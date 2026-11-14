from datetime import datetime, timezone
import hashlib
from typing import Any, Callable
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Response, UploadFile, File, Form, status
from sqlalchemy import delete, desc, func, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.auth.verify_token import AuthenticatedPrincipal
from app.config import Settings, get_settings
from app.db.models import (
    Alarm,
    AlarmSession,
    Attempt,
    ConsentEvent,
    IdempotencyRecord,
    Question,
    StudySession,
    TimetableSlot,
    TopicProgress,
    User,
    XpLedger,
)
from app.repositories.idempotency import lookup_idempotency, save_idempotency
from app.schemas import (
    AlarmUpsertRequest,
    ConsentUpdateRequest,
    LiveTokenRequest,
    PersonalizedQuestionRequest,
    ProfilePatchRequest,
    SessionAnswerRequest,
    SessionCreateRequest,
    SessionEventRequest,
    SessionFeedbackRequest,
    StudyHelpRequest,
    StudySessionCreateRequest,
    StudySessionFinishRequest,
    TimetablePutRequest,
)
from app.services.gemini_service import (
    OFFLINE_HELP_FALLBACK_VI,
    GeminiService,
    GeminiServiceError,
    normalize_subject_code,
)


def _api_error(status_code: int, code: str, message: str, retryable: bool = False) -> HTTPException:
    return HTTPException(
        status_code=status_code,
        detail={
            'error': {
                'code': code,
                'message': message,
                'requestId': f'req_{uuid.uuid4().hex[:12]}',
                'retryable': retryable,
            }
        },
    )


def _alarm_to_wire(alarm: Alarm) -> dict[str, Any]:
    return {
        'id': alarm.id,
        'localTime': alarm.local_time,
        'timeZone': alarm.time_zone,
        'weekdays': alarm.weekdays_json or [],
        'enabled': alarm.enabled,
        'challengeMode': alarm.challenge_mode,
        'snoozeMinutes': alarm.snooze_minutes,
        'revision': alarm.revision,
    }


def _question_to_personalized_wire(q: Question, *, fallback_used: bool = False) -> dict[str, Any]:
    return {
        'questionId': q.id,
        'subjectCode': q.subject_code,
        'gradeBand': q.grade_band,
        'topicId': q.topic_id,
        'difficulty': q.difficulty,
        'prompt': q.prompt,
        'reasoningPromptVi': q.reasoning_prompt_vi,
        'steps': (q.rubric_json or {}).get('steps', []),
        'hintVi': (q.rubric_json or {}).get('hint_vi'),
        'status': q.status,
        'sourceType': q.source_type,
        'modelVersion': q.model_version or 'approved-bank',
        'xpAwarded': 0,
        'fallbackUsed': fallback_used,
    }


def _select_published_question(
    db: Session,
    *,
    user_id: str,
    subject_code: str,
    grade_band: str,
) -> Question | None:
    clean_subject = normalize_subject_code(subject_code)
    weak_topic_ids = list(
        db.scalars(
            select(TopicProgress.topic_id)
            .where(
                TopicProgress.user_id == user_id,
                TopicProgress.subject_code == clean_subject,
                TopicProgress.attempts > TopicProgress.correct,
            )
            .order_by(TopicProgress.updated_at.asc())
        )
    )
    candidates = list(
        db.scalars(
            select(Question).where(
                Question.status == 'published',
                Question.source_type == 'approved_bank',
                Question.subject_code == clean_subject,
            )
        )
    )
    if not candidates:
        candidates = list(
            db.scalars(
                select(Question).where(
                    Question.status == 'published',
                    Question.source_type == 'approved_bank',
                )
            )
        )
    if not candidates:
        return None
    for q in candidates:
        if q.grade_band == grade_band and q.topic_id in weak_topic_ids:
            return q
    for q in candidates:
        if q.grade_band == grade_band:
            return q
    return candidates[0]


def _has_granted_consent(db: Session, user_id: str, scope: str) -> bool:
    latest = db.scalar(
        select(ConsentEvent)
        .where(ConsentEvent.user_id == user_id, ConsentEvent.scope == scope)
        .order_by(desc(ConsentEvent.occurred_at))
        .limit(1)
    )
    return bool(latest and latest.granted)


def create_v1_router(
    *,
    get_db: Callable[..., Any],
    get_current_user: Callable[..., Any],
    gemini_factory: Callable[[Settings], GeminiService] | None = None,
) -> APIRouter:
    router = APIRouter(prefix='/v1')

    def _get_gemini(settings: Settings) -> GeminiService:
        if gemini_factory is not None:
            return gemini_factory(settings)
        return GeminiService(settings)

    @router.get('/health')
    def health(
        db: Session = Depends(get_db),
        settings: Settings = Depends(get_settings),
    ) -> dict[str, Any]:
        db_ok = True
        try:
            db.execute(text('SELECT 1'))
        except Exception:
            db_ok = False
        return {
            'status': 'ok' if db_ok else 'degraded',
            'version': 'v1',
            'dbReady': db_ok,
            'dbDialect': 'sqlite' if settings.is_sqlite else 'postgresql',
            'geminiConfigured': settings.has_gemini_key,
            'geminiPrimaryModel': settings.gemini_primary_model,
            'geminiFastModel': settings.gemini_fast_model,
            'geminiLiveModel': settings.gemini_live_model,
        }

    @router.get('/me')
    def get_me(
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        u = principal.user
        return {
            'id': u.id,
            'authSubject': u.auth_subject,
            'alias': u.alias,
            'gradeLevel': u.grade_band,
            'selectedSubjects': u.selected_subjects_json or [],
            'goalLabel': u.goal_label,
            'timeZone': u.time_zone,
            'liveConsentGranted': _has_granted_consent(db, u.id, 'gemini_live_opt_in'),
        }

    @router.patch('/me')
    def patch_me(
        payload: ProfilePatchRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        u = db.get(type(principal.user), principal.user.id)
        if u is None:
            raise _api_error(404, 'USER_NOT_FOUND', 'Không tìm thấy hồ sơ người dùng.')
        if payload.alias is not None:
            u.alias = payload.alias.strip()[:80] or u.alias
        if payload.grade_band is not None:
            u.grade_band = payload.grade_band.strip()[:40] or u.grade_band
        if payload.selected_subjects is not None:
            u.selected_subjects_json = [
                normalize_subject_code(s) for s in payload.selected_subjects if s.strip()
            ]
        if payload.goal_label is not None:
            u.goal_label = payload.goal_label.strip()[:120]
        if payload.time_zone is not None:
            u.time_zone = payload.time_zone.strip()[:64] or u.time_zone
        if payload.live_consent_granted is not None:
            db.add(
                ConsentEvent(
                    user_id=u.id,
                    scope='gemini_live_opt_in',
                    version=u.consent_version,
                    granted=payload.live_consent_granted,
                )
            )
        db.commit()
        db.refresh(u)
        return {
            'id': u.id,
            'authSubject': u.auth_subject,
            'alias': u.alias,
            'gradeLevel': u.grade_band,
            'selectedSubjects': u.selected_subjects_json or [],
            'goalLabel': u.goal_label,
            'timeZone': u.time_zone,
            'liveConsentGranted': _has_granted_consent(db, u.id, 'gemini_live_opt_in'),
        }

    @router.post('/me/consent')
    def update_consent(
        payload: ConsentUpdateRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        event = ConsentEvent(
            user_id=principal.user.id,
            scope=payload.scope.strip(),
            version=payload.version.strip(),
            granted=payload.granted,
        )
        db.add(event)
        db.commit()
        return {
            'scope': event.scope,
            'granted': event.granted,
            'version': event.version,
        }

    @router.delete('/me', status_code=status.HTTP_202_ACCEPTED)
    def delete_me(
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        uid = principal.user.id
        db.execute(delete(Question).where(Question.target_user_id == uid))
        db.execute(delete(IdempotencyRecord).where(IdempotencyRecord.user_id == uid))
        db.execute(delete(XpLedger).where(XpLedger.user_id == uid))
        db.execute(delete(TopicProgress).where(TopicProgress.user_id == uid))
        db.execute(delete(ConsentEvent).where(ConsentEvent.user_id == uid))
        db.execute(delete(TimetableSlot).where(TimetableSlot.user_id == uid))
        db.execute(delete(Alarm).where(Alarm.user_id == uid))
        db.execute(delete(StudySession).where(StudySession.user_id == uid))
        db.execute(delete(AlarmSession).where(AlarmSession.user_id == uid))
        db.execute(delete(User).where(User.id == uid))
        db.commit()
        return {
            'status': 'deleted',
            'deletedAt': datetime.now(timezone.utc).isoformat().replace('+00:00', 'Z'),
        }

    @router.get('/timetable')
    def get_timetable(
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        slots = list(
            db.scalars(
                select(TimetableSlot)
                .where(TimetableSlot.user_id == principal.user.id)
                .order_by(TimetableSlot.weekday.asc(), TimetableSlot.position.asc())
            )
        )
        return {
            'slots': [
                {
                    'weekday': s.weekday,
                    'subjectCode': s.subject_code,
                    'topicId': s.topic_id,
                    'position': s.position,
                }
                for s in slots
            ]
        }

    @router.put('/timetable')
    def put_timetable(
        payload: TimetablePutRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        db.execute(delete(TimetableSlot).where(TimetableSlot.user_id == principal.user.id))
        per_day_pos: dict[int, int] = {}
        saved: list[TimetableSlot] = []
        for item in payload.slots:
            pos = per_day_pos.get(item.weekday, 0)
            per_day_pos[item.weekday] = pos + 1
            slot = TimetableSlot(
                user_id=principal.user.id,
                weekday=item.weekday,
                subject_code=normalize_subject_code(item.subject_code),
                topic_id=item.topic_id.strip()[:64],
                position=pos,
            )
            db.add(slot)
            saved.append(slot)
        db.commit()
        return {
            'slots': [
                {
                    'weekday': s.weekday,
                    'subjectCode': s.subject_code,
                    'topicId': s.topic_id,
                    'position': s.position,
                }
                for s in saved
            ]
        }

    @router.get('/alarms')
    def list_alarms(
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        items = list(
            db.scalars(
                select(Alarm)
                .where(Alarm.user_id == principal.user.id)
                .order_by(Alarm.created_at.asc())
            )
        )
        return {'items': [_alarm_to_wire(a) for a in items]}

    @router.post('/alarms')
    def create_alarm(
        payload: AlarmUpsertRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
        idempotency_key: str | None = Header(default=None, alias='Idempotency-Key'),
    ) -> dict[str, Any]:
        raw_body = payload.model_dump(by_alias=True)
        cached = lookup_idempotency(
            db,
            user_id=principal.user.id,
            route='POST:/v1/alarms',
            key=idempotency_key,
            payload=raw_body,
        )
        if cached is not None:
            return cached

        alarm = Alarm(
            user_id=principal.user.id,
            local_time=payload.local_time,
            time_zone=payload.time_zone,
            weekdays_json=payload.weekdays,
            enabled=payload.enabled,
            challenge_mode=payload.challenge_mode,
            snooze_minutes=payload.snooze_minutes,
            revision=1,
        )
        db.add(alarm)
        db.flush()
        resp = _alarm_to_wire(alarm)
        save_idempotency(
            db,
            user_id=principal.user.id,
            route='POST:/v1/alarms',
            key=idempotency_key,
            payload=raw_body,
            response_json=resp,
        )
        db.commit()
        return resp

    @router.patch('/alarms/{alarm_id}')
    def update_alarm(
        alarm_id: str,
        payload: AlarmUpsertRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        alarm = db.get(Alarm, alarm_id)
        if alarm is None:
            raise _api_error(404, 'ALARM_NOT_FOUND', 'Không tìm thấy báo thức.')
        if alarm.user_id != principal.user.id:
            raise _api_error(
                403,
                'FORBIDDEN_OWNER',
                'Không có quyền sửa báo thức của tài khoản khác.',
            )
        alarm.local_time = payload.local_time
        alarm.time_zone = payload.time_zone
        alarm.weekdays_json = payload.weekdays
        alarm.enabled = payload.enabled
        alarm.challenge_mode = payload.challenge_mode
        alarm.snooze_minutes = payload.snooze_minutes
        alarm.revision = alarm.revision + 1
        db.commit()
        db.refresh(alarm)
        return _alarm_to_wire(alarm)

    @router.delete('/alarms/{alarm_id}', status_code=status.HTTP_204_NO_CONTENT)
    def delete_alarm(
        alarm_id: str,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> Response:
        alarm = db.get(Alarm, alarm_id)
        if alarm is None:
            raise _api_error(404, 'ALARM_NOT_FOUND', 'Không tìm thấy báo thức.')
        if alarm.user_id != principal.user.id:
            raise _api_error(
                403,
                'FORBIDDEN_OWNER',
                'Không có quyền xóa báo thức của tài khoản khác.',
            )
        db.delete(alarm)
        db.commit()
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    @router.get('/challenges/next')
    def get_next_challenge(
        subject: str = Query(default='TOAN'),
        date: str = Query(default='2026-11-14'),
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        selected = _select_published_question(
            db,
            user_id=principal.user.id,
            subject_code=subject,
            grade_band=principal.user.grade_band,
        )
        if selected is None:
            raise _api_error(404, 'QUESTION_NOT_FOUND', 'Chưa có câu hỏi đã duyệt.')
        return {
            'questionId': selected.id,
            'questionRevision': selected.revision,
            'validForDate': date,
            'subject': selected.subject_code,
            'gradeBand': selected.grade_band,
            'topicId': selected.topic_id,
            'difficulty': selected.difficulty,
            'prompt': selected.prompt,
            'reasoningPromptVi': selected.reasoning_prompt_vi,
            'offlinePolicy': 'ungraded_only',
            'estimatedSeconds': 75,
            'fallback': False,
        }

    @router.post('/questions/personalized')
    async def create_personalized_question(
        payload: PersonalizedQuestionRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
        settings: Settings = Depends(get_settings),
    ) -> dict[str, Any]:
        u = principal.user
        effective_grade = (payload.grade_level or u.grade_band or 'Lớp 9').strip()
        clean_subject = normalize_subject_code(payload.subject_code)

        weak_topics = list(
            db.scalars(
                select(TopicProgress.topic_id).where(
                    TopicProgress.user_id == u.id,
                    TopicProgress.subject_code == clean_subject,
                    TopicProgress.attempts > TopicProgress.correct,
                )
            )
        )

        gemini = _get_gemini(settings)
        # Gọi Gemini ngoài DB transaction theo docs/28 §3.
        try:
            draft = await gemini.generate_personalized_question(
                alias=u.alias,
                grade_level=effective_grade,
                subject_code=clean_subject,
                weak_topics=weak_topics,
                topic_hint=payload.topic_hint,
                difficulty=payload.difficulty,
            )
        except GeminiServiceError:
            fallback_q = _select_published_question(
                db,
                user_id=u.id,
                subject_code=clean_subject,
                grade_band=effective_grade,
            )
            if fallback_q is None:
                raise _api_error(
                    503,
                    'AI_UPSTREAM_UNAVAILABLE',
                    'Không tạo được câu hỏi cá nhân hóa lúc này.',
                    retryable=True,
                )
            return _question_to_personalized_wire(fallback_q, fallback_used=True)

        question = Question(
            id=f'ai_q_{uuid.uuid4().hex[:12]}',
            subject_code=clean_subject,
            grade_band=effective_grade,
            topic_id=draft.topic_id,
            difficulty=draft.difficulty,
            prompt=draft.prompt,
            answer_spec_json={'accepted': draft.accepted_answers},
            reasoning_prompt_vi=draft.reasoning_prompt_vi,
            rubric_json={'steps': draft.steps, 'hint_vi': draft.hint_vi},
            rubric_revision=1,
            status='draft',
            source_type='ai_personalized_draft',
            target_user_id=u.id,
            model_version=draft.model_version,
            revision=1,
        )
        if payload.save_to_bank:
            db.add(question)
            db.commit()
            db.refresh(question)
        return _question_to_personalized_wire(question, fallback_used=False)

    @router.get('/questions/personalized')
    def list_personalized_questions(
        subject: str | None = Query(default=None),
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        stmt = select(Question).where(
            Question.source_type == 'ai_personalized_draft',
            Question.target_user_id == principal.user.id,
        )
        if subject and subject.strip():
            stmt = stmt.where(Question.subject_code == normalize_subject_code(subject))
        rows = list(db.scalars(stmt.order_by(desc(Question.created_at)).limit(20)))
        return {
            'items': [_question_to_personalized_wire(q) for q in rows],
        }

    @router.get('/sessions')
    def list_alarm_sessions(
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        rows = list(
            db.scalars(
                select(AlarmSession)
                .where(AlarmSession.user_id == principal.user.id)
                .order_by(desc(AlarmSession.created_at))
                .limit(30)
            )
        )
        return {
            'items': [
                {
                    'sessionId': s.id,
                    'localDate': s.local_date,
                    'subject': 'TOAN',
                    'state': s.state,
                }
                for s in rows
            ]
        }

    @router.post('/sessions')
    def create_alarm_session(
        payload: SessionCreateRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        existing = db.scalar(
            select(AlarmSession).where(
                AlarmSession.user_id == principal.user.id,
                AlarmSession.local_session_id == payload.local_session_id,
            )
        )
        if existing is not None:
            return {
                'sessionId': existing.id,
                'state': existing.state,
                'version': existing.version,
            }

        q_id = payload.question_id or 'math9-linear-001'
        q_obj = db.get(Question, q_id)
        if q_obj is None:
            q_obj = _select_published_question(
                db,
                user_id=principal.user.id,
                subject_code='TOAN',
                grade_band=principal.user.grade_band,
            )
        session = AlarmSession(
            id=f'srv_{payload.local_session_id}',
            user_id=principal.user.id,
            alarm_id=payload.alarm_id,
            local_session_id=payload.local_session_id,
            question_id=q_obj.id if q_obj else q_id,
            question_revision=q_obj.revision if q_obj else 1,
            local_date=payload.local_date,
            time_zone=payload.time_zone,
            state='active',
            version=1,
        )
        db.add(session)
        db.commit()
        return {
            'sessionId': session.id,
            'state': session.state,
            'version': session.version,
        }

    @router.post('/sessions/{session_id}/events')
    def post_alarm_session_event(
        session_id: str,
        payload: SessionEventRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
        idempotency_key: str | None = Header(default=None, alias='Idempotency-Key'),
    ) -> dict[str, Any]:
        session = db.get(AlarmSession, session_id)
        if session is None:
            raise _api_error(404, 'SESSION_NOT_FOUND', 'Không tìm thấy phiên học.')
        if session.user_id != principal.user.id:
            raise _api_error(
                403,
                'FORBIDDEN_OWNER',
                'Không có quyền truy cập phiên của tài khoản khác.',
            )
        raw_body = payload.model_dump(by_alias=True)
        cached = lookup_idempotency(
            db,
            user_id=principal.user.id,
            route=f'POST:/v1/sessions/{session_id}/events',
            key=idempotency_key,
            payload=raw_body,
        )
        if cached is not None:
            return cached

        if payload.event_type == 'complete_ungraded':
            session.state = 'completed_ungraded'
        elif payload.event_type == 'dismiss':
            session.state = 'dismissed'
        session.version += 1
        resp = {
            'sessionId': session.id,
            'state': session.state,
            'version': session.version,
        }
        save_idempotency(
            db,
            user_id=principal.user.id,
            route=f'POST:/v1/sessions/{session_id}/events',
            key=idempotency_key,
            payload=raw_body,
            response_json=resp,
        )
        db.commit()
        return resp

    @router.post('/sessions/{session_id}/answers')
    def submit_alarm_answer(
        session_id: str,
        payload: SessionAnswerRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
        idempotency_key: str | None = Header(default=None, alias='Idempotency-Key'),
    ) -> dict[str, Any]:
        session = db.get(AlarmSession, session_id)
        if session is None:
            raise _api_error(404, 'SESSION_NOT_FOUND', 'Không tìm thấy phiên học.')
        if session.user_id != principal.user.id:
            raise _api_error(
                403,
                'FORBIDDEN_OWNER',
                'Không có quyền nộp bài cho phiên của người khác.',
            )

        raw_body = payload.model_dump(by_alias=True)
        cached = lookup_idempotency(
            db,
            user_id=principal.user.id,
            route=f'POST:/v1/sessions/{session_id}/answers',
            key=idempotency_key,
            payload=raw_body,
        )
        if cached is not None:
            return cached

        question = db.get(Question, session.question_id)
        accepted = [
            str(x).strip().lower()
            for x in ((question.answer_spec_json or {}).get('accepted', ['8']) if question else ['8'])
        ]
        answer_norm = payload.answer_value.strip().lower()
        reasoning_norm = payload.reasoning_text.strip().lower()

        if 'uncertain' in reasoning_norm or not answer_norm:
            result = 'uncertain'
            xp_delta = 0
            observed_steps: list[str] = []
            first_issue = None
            hint = None
            feedback = 'Chưa đủ rõ bước lập luận để chấm dứt khoát.'
            next_actions = ['retry', 'finish_ungraded', 'emergency_stop']
        elif answer_norm in accepted:
            already_rewarded = (
                session.state == 'completed'
                or db.scalar(
                    select(XpLedger.id).where(
                        XpLedger.user_id == principal.user.id,
                        XpLedger.source_type == 'alarm_session',
                        XpLedger.source_id == session.id,
                    )
                )
                is not None
            )
            result = 'correct'
            xp_delta = 0 if already_rewarded else 10
            observed_steps = [payload.reasoning_text.strip()] if payload.reasoning_text.strip() else []
            first_issue = None
            hint = None
            feedback = (
                'Chính xác! Server ghi nhận +10 XP.'
                if xp_delta > 0
                else 'Chính xác! Phiên này đã được ghi nhận XP trước đó.'
            )
            next_actions = ['finish']
            session.state = 'completed'
        else:
            result = 'incorrect'
            xp_delta = 0
            session.wrong_attempts += 1
            show_hint = session.wrong_attempts >= 3
            observed_steps = [payload.reasoning_text.strip()] if (show_hint and payload.reasoning_text.strip()) else []
            first_issue = 'Kiểm tra lại bước biến đổi chính.' if show_hint else None
            hint = (
                (question.rubric_json or {}).get('hint_vi')
                if (show_hint and question)
                else None
            )
            feedback = 'Bài này chưa đúng. Bạn có thể thử lại.'
            next_actions = ['retry', 'finish_ungraded', 'emergency_stop']

        attempt_id = f'att_{uuid.uuid4().hex[:10]}'
        client_attempt_id = idempotency_key or attempt_id
        db.add(
            Attempt(
                id=attempt_id,
                session_id=session.id,
                client_attempt_id=client_attempt_id,
                kind='text',
                grade_status=result,
                feedback_json={'feedback': feedback},
                rubric_revision=question.rubric_revision if question else 1,
                model_version='deterministic-validator',
            )
        )
        if xp_delta > 0:
            db.add(
                XpLedger(
                    user_id=principal.user.id,
                    source_type='alarm_session',
                    source_id=session.id,
                    reason='challenge_correct',
                    delta=xp_delta,
                )
            )
        if question and result in {'correct', 'incorrect'}:
            tp = db.get(TopicProgress, (principal.user.id, question.topic_id))
            if tp is None:
                tp = TopicProgress(
                    user_id=principal.user.id,
                    topic_id=question.topic_id,
                    subject_code=question.subject_code,
                    attempts=0,
                    correct=0,
                )
                db.add(tp)
            tp.attempts += 1
            if result == 'correct':
                tp.correct += 1

        resp = {
            'attemptId': attempt_id,
            'result': result,
            'observedSteps': observed_steps,
            'firstIssue': first_issue,
            'feedback': feedback,
            'hint': hint,
            'nextActions': next_actions,
            'xpAwarded': xp_delta,
            'modelVersion': 'deterministic-validator',
            'rubricRevision': question.rubric_revision if question else 1,
        }
        save_idempotency(
            db,
            user_id=principal.user.id,
            route=f'POST:/v1/sessions/{session_id}/answers',
            key=idempotency_key,
            payload=raw_body,
            response_json=resp,
        )
        try:
            db.commit()
        except IntegrityError:
            db.rollback()
        return resp

    @router.post('/sessions/{session_id}/attempts')
    async def submit_alarm_photo_attempt(
        session_id: str,
        image: UploadFile | None = File(default=None),
        file: UploadFile | None = File(default=None),
        reasoning_text: str = Form(default=''),
        answer_value: str = Form(default='', alias='answerValue'),
        client_attempt_id_form: str = Form(default='', alias='clientAttemptId'),
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
        settings: Settings = Depends(get_settings),
        idempotency_key: str | None = Header(default=None, alias='Idempotency-Key'),
    ) -> dict[str, Any]:
        session = db.get(AlarmSession, session_id)
        if session is None:
            raise _api_error(404, 'SESSION_NOT_FOUND', 'Không tìm thấy phiên học.')
        if session.user_id != principal.user.id:
            raise _api_error(403, 'FORBIDDEN_OWNER', 'Không có quyền truy cập phiên của người khác.')

        upload = image or file
        if upload is None:
            raise _api_error(400, 'IMAGE_REQUIRED', 'Thiếu ảnh bài làm tải lên (image).')
        raw_bytes = await upload.read()
        if not raw_bytes:
            raise _api_error(400, 'EMPTY_IMAGE', 'Tệp ảnh rỗng.')
        if len(raw_bytes) > 5 * 1024 * 1024:
            raise _api_error(413, 'IMAGE_TOO_LARGE', 'Ảnh vượt quá giới hạn 5 MB.')

        mime = (upload.content_type or 'image/jpeg').split(';', 1)[0].strip().lower()
        if mime == 'image/jpg':
            mime = 'image/jpeg'
        if mime not in {'image/jpeg', 'image/png', 'image/webp'}:
            raise _api_error(
                415,
                'UNSUPPORTED_MEDIA_TYPE',
                'Định dạng ảnh chưa hỗ trợ. Vui lòng chọn JPEG, PNG hoặc WebP.',
            )

        digest = hashlib.sha256(raw_bytes).hexdigest()
        idem_payload = {
            'sha256': digest,
            'len': len(raw_bytes),
            'answerValue': answer_value.strip(),
            'reasoning': reasoning_text.strip(),
        }
        cached = lookup_idempotency(
            db,
            user_id=principal.user.id,
            route=f'POST:/v1/sessions/{session_id}/attempts',
            key=idempotency_key,
            payload=idem_payload,
        )
        if cached is not None:
            return cached

        question = db.get(Question, session.question_id)
        accepted = [
            str(x)
            for x in ((question.answer_spec_json or {}).get('accepted', ['8']) if question else ['8'])
        ]
        rubric_steps = [
            str(s)
            for s in ((question.rubric_json or {}).get('steps', []) if question else [])
        ]
        hint_vi = (question.rubric_json or {}).get('hint_vi') if question else None
        q_prompt = question.prompt if question else 'Giải bài tập theo đúng yêu cầu đề.'

        gemini = _get_gemini(settings)
        # Gọi Gemini Vision trong bộ nhớ ngoài DB transaction (không lưu ảnh ra đĩa/log).
        grade = await gemini.grade_photo_attempt(
            image_bytes=raw_bytes,
            mime_type=mime,
            question_prompt=q_prompt,
            accepted_answers=accepted,
            rubric_steps=rubric_steps,
            hint_vi=hint_vi,
            answer_value=answer_value,
            reasoning_text=reasoning_text,
            wrong_attempts_so_far=session.wrong_attempts,
        )

        xp_delta = 0
        if grade.result == 'correct':
            already_rewarded = (
                session.state == 'completed'
                or db.scalar(
                    select(XpLedger.id).where(
                        XpLedger.user_id == principal.user.id,
                        XpLedger.source_type == 'alarm_session',
                        XpLedger.source_id == session.id,
                    )
                )
                is not None
            )
            xp_delta = 0 if already_rewarded else 10
            session.state = 'completed'
            next_actions = ['finish']
        elif grade.result == 'incorrect':
            session.wrong_attempts += 1
            next_actions = ['retry', 'finish_ungraded', 'emergency_stop']
        else:
            next_actions = ['retry', 'finish_ungraded', 'emergency_stop']

        attempt_id = f'att_photo_{uuid.uuid4().hex[:8]}'
        db.add(
            Attempt(
                id=attempt_id,
                session_id=session.id,
                client_attempt_id=idempotency_key or client_attempt_id_form or attempt_id,
                kind='photo',
                grade_status=grade.result,
                feedback_json={'feedback': grade.feedback},
                rubric_revision=question.rubric_revision if question else 1,
                model_version=grade.model_version,
            )
        )
        if xp_delta > 0:
            db.add(
                XpLedger(
                    user_id=principal.user.id,
                    source_type='alarm_session',
                    source_id=session.id,
                    reason='photo_challenge_correct',
                    delta=xp_delta,
                )
            )
        if question and grade.result in {'correct', 'incorrect'}:
            tp = db.get(TopicProgress, (principal.user.id, question.topic_id))
            if tp is None:
                tp = TopicProgress(
                    user_id=principal.user.id,
                    topic_id=question.topic_id,
                    subject_code=question.subject_code,
                    attempts=0,
                    correct=0,
                )
                db.add(tp)
            tp.attempts += 1
            if grade.result == 'correct':
                tp.correct += 1

        resp = {
            'attemptId': attempt_id,
            'result': grade.result,
            'observedSteps': grade.observed_steps,
            'firstIssue': grade.first_issue,
            'feedback': grade.feedback,
            'hint': grade.hint_vi,
            'nextActions': next_actions,
            'xpAwarded': xp_delta,
            'modelVersion': grade.model_version,
            'rubricRevision': question.rubric_revision if question else 1,
        }
        save_idempotency(
            db,
            user_id=principal.user.id,
            route=f'POST:/v1/sessions/{session_id}/attempts',
            key=idempotency_key,
            payload=idem_payload,
            response_json=resp,
        )
        db.commit()
        return resp

    @router.post('/sessions/{session_id}/feedback')
    def post_feedback(
        session_id: str,
        payload: SessionFeedbackRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        session = db.get(AlarmSession, session_id)
        if session is None:
            raise _api_error(404, 'SESSION_NOT_FOUND', 'Không tìm thấy phiên học.')
        if session.user_id != principal.user.id:
            raise _api_error(403, 'FORBIDDEN_OWNER', 'Không có quyền gửi phản hồi phiên người khác.')
        msg = (payload.comment or payload.reason or payload.category or '').strip()
        if not msg:
            raise _api_error(400, 'FEEDBACK_EMPTY', 'Cần chọn lý do hoặc nhập phản hồi.')
        return {
            'feedbackId': f'fb_{uuid.uuid4().hex[:10]}',
            'status': 'queued_for_review',
            'recorded': True,
        }

    @router.get('/progress/summary')
    def progress_summary(
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
    ) -> dict[str, Any]:
        total_xp = db.scalar(
            select(func.coalesce(func.sum(XpLedger.delta), 0)).where(
                XpLedger.user_id == principal.user.id
            )
        )
        completed_count = db.scalar(
            select(func.count(AlarmSession.id)).where(
                AlarmSession.user_id == principal.user.id,
                AlarmSession.state == 'completed',
            )
        )
        weak_topics = list(
            db.scalars(
                select(TopicProgress.topic_id).where(
                    TopicProgress.user_id == principal.user.id,
                    TopicProgress.attempts > TopicProgress.correct,
                )
            )
        )
        return {
            'xp': int(total_xp or 0),
            'streak': 1 if (completed_count or 0) > 0 else 0,
            'completedSessions': int(completed_count or 0),
            'topicsToReview': weak_topics,
        }

    @router.post('/study/sessions')
    def create_study_session(
        payload: StudySessionCreateRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
        idempotency_key: str | None = Header(default=None, alias='Idempotency-Key'),
    ) -> dict[str, Any]:
        raw_body = payload.model_dump(by_alias=True)
        cached = lookup_idempotency(
            db,
            user_id=principal.user.id,
            route='POST:/v1/study/sessions',
            key=idempotency_key,
            payload=raw_body,
        )
        if cached is not None:
            return cached

        existing = db.scalar(
            select(StudySession).where(
                StudySession.user_id == principal.user.id,
                StudySession.client_session_id == payload.client_session_id,
            )
        )
        if existing is None:
            existing = StudySession(
                id=f'srv_study_{payload.client_session_id}',
                user_id=principal.user.id,
                client_session_id=payload.client_session_id,
                task_title=payload.task_title,
                subject_code=payload.subject_code,
                grade_band=principal.user.grade_band,
                target_minutes=payload.target_minutes,
                focus_level=payload.focus_level,
                state='active',
            )
            db.add(existing)
            db.flush()

        resp = {
            'sessionId': existing.id,
            'clientSessionId': existing.client_session_id,
            'state': existing.state,
        }
        save_idempotency(
            db,
            user_id=principal.user.id,
            route='POST:/v1/study/sessions',
            key=idempotency_key,
            payload=raw_body,
            response_json=resp,
        )
        db.commit()
        return resp

    @router.post('/study/sessions/{session_id}/finish')
    def finish_study_session(
        session_id: str,
        payload: StudySessionFinishRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
        idempotency_key: str | None = Header(default=None, alias='Idempotency-Key'),
    ) -> dict[str, Any]:
        raw_body = payload.model_dump(by_alias=True)
        cached = lookup_idempotency(
            db,
            user_id=principal.user.id,
            route=f'POST:/v1/study/sessions/{session_id}/finish',
            key=idempotency_key,
            payload=raw_body,
        )
        if cached is not None:
            return cached

        study_session = db.get(StudySession, session_id)
        if study_session is None and payload.client_session_id:
            study_session = db.scalar(
                select(StudySession).where(
                    StudySession.user_id == principal.user.id,
                    StudySession.client_session_id == payload.client_session_id,
                )
            )
        if study_session is not None and study_session.user_id != principal.user.id:
            raise _api_error(
                403,
                'FORBIDDEN_OWNER',
                'Không có quyền kết thúc phiên học của tài khoản khác.',
            )

        if study_session is None:
            study_session = StudySession(
                id=session_id,
                user_id=principal.user.id,
                client_session_id=payload.client_session_id or session_id,
                task_title='Phiên tự học',
                grade_band=principal.user.grade_band,
            )
            db.add(study_session)

        study_session.state = payload.final_status or 'finished'
        study_session.elapsed_wall_seconds = payload.elapsed_wall_seconds
        study_session.in_app_focus_seconds = payload.in_app_focus_seconds
        study_session.notes_done = payload.notes_done
        study_session.notes_stuck = payload.notes_stuck
        study_session.ended_at = datetime.now(timezone.utc)

        resp = {
            'sessionId': study_session.id,
            'clientSessionId': study_session.client_session_id,
            'state': study_session.state,
            'xpAwarded': 0,
        }
        save_idempotency(
            db,
            user_id=principal.user.id,
            route=f'POST:/v1/study/sessions/{session_id}/finish',
            key=idempotency_key,
            payload=raw_body,
            response_json=resp,
        )
        db.commit()
        return resp

    @router.post('/study/help')
    async def study_help(
        payload: StudyHelpRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
        settings: Settings = Depends(get_settings),
    ) -> dict[str, Any]:
        # Kiểm tra owner nếu session đã tồn tại trên DB
        study_session = db.scalar(
            select(StudySession).where(
                (StudySession.id == payload.client_session_id)
                | (StudySession.client_session_id == payload.client_session_id)
            )
        )
        if study_session is not None and study_session.user_id != principal.user.id:
            raise _api_error(
                403,
                'FORBIDDEN_OWNER',
                'Không có quyền hỏi trong phiên của người khác.',
            )

        gemini = _get_gemini(settings)
        grade_level = (payload.grade or principal.user.grade_band or 'Lớp 9').strip()
        clipped_turns = [t.model_dump(by_alias=True) for t in payload.recent_turns[-3:]]

        try:
            res = await gemini.generate_socratic_help(
                subject_code=payload.subject,
                grade_level=grade_level,
                task_title=payload.task,
                question_text=payload.question_text,
                recent_turns=clipped_turns,
            )
        except GeminiServiceError as exc:
            raise _api_error(exc.status_code, exc.code, exc.message_vi, retryable=exc.retryable)

        return {
            'message_vi': res.message_vi or OFFLINE_HELP_FALLBACK_VI,
            'next_question_vi': res.next_question_vi,
            'help_level': res.help_level,
            'safety_status': res.safety_status,
            'model_version': res.model_version,
        }

    @router.post('/study/live-token')
    async def create_live_token(
        payload: LiveTokenRequest,
        principal: AuthenticatedPrincipal = Depends(get_current_user),
        db: Session = Depends(get_db),
        settings: Settings = Depends(get_settings),
    ) -> dict[str, Any]:
        u = principal.user
        has_consent = payload.consent_granted or _has_granted_consent(
            db, u.id, 'gemini_live_opt_in'
        )
        if not has_consent:
            raise _api_error(
                403,
                'CONSENT_REQUIRED',
                'Cần người dùng bật đồng ý rõ ràng trước khi mở Gemini Live.',
            )
        if payload.consent_granted and not _has_granted_consent(
            db, u.id, 'gemini_live_opt_in'
        ):
            db.add(
                ConsentEvent(
                    user_id=u.id,
                    scope='gemini_live_opt_in',
                    version=u.consent_version,
                    granted=True,
                )
            )
            db.commit()

        gemini = _get_gemini(settings)
        grade_level = (payload.grade_level or u.grade_band or 'Lớp 9').strip()
        try:
            token_res = await gemini.create_live_ephemeral_token(
                alias=u.alias,
                grade_level=grade_level,
                subject_code=payload.subject_code,
                task_title=payload.task_title,
                response_modality=payload.response_modality,
            )
        except GeminiServiceError as exc:
            raise _api_error(exc.status_code, exc.code, exc.message_vi, retryable=exc.retryable)

        return {
            'tokenName': token_res.token_name,
            'wsUrl': token_res.ws_url,
            'model': token_res.model,
            'expiresAt': token_res.expires_at,
            'expiresInSeconds': token_res.expires_in_seconds,
            'responseModalities': token_res.response_modalities,
            'contextSummary': token_res.system_instruction_summary,
            'isMock': token_res.is_mock,
        }

    return router
