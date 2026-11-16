from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
import random
from typing import Any

from sqlalchemy import and_, func, or_
from sqlalchemy.orm import Session

from app.db.models import (
    Match,
    MatchEvent,
    MatchPlayer,
    MatchQueue,
    MatchRound,
    Question,
    RoundAction,
    RoundSubmission,
    User,
)
from app.game.combat_catalog import (
    ActionType,
    ChampionId,
    COMBAT_RULE_VERSION,
    normalize_champion_id,
)
from app.game.combat_engine import (
    PlayerCombatState,
    RoundActionInput,
    settle_combat_round,
)
from app.services.gemini_service import normalize_subject_code
from app.services.answer_normalizer import is_answer_accepted


class PvpServiceError(Exception):
    def __init__(
        self,
        *,
        code: str,
        message_vi: str,
        status_code: int = 400,
    ) -> None:
        super().__init__(message_vi)
        self.code = code
        self.message_vi = message_vi
        self.status_code = status_code


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def _iso_utc(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.isoformat()


class PvpMatchService:
    def __init__(self, db: Session) -> None:
        self._db = db

    def queue_player(
        self,
        *,
        user_id: str,
        raw_champion_id: str,
        raw_subject_code: str,
        grade_band: str,
        curriculum: str = 'gdpt_2018',
    ) -> dict[str, Any]:
        """Đưa người chơi vào hàng đợi giao hữu hoặc ghép cặp ngay nếu tìm thấy đối thủ hợp lệ."""
        norm_champ = normalize_champion_id(raw_champion_id)
        norm_subject = normalize_subject_code(raw_subject_code)

        # 1. Kiểm tra ngân hàng câu hỏi: bắt buộc có ít nhất 6 câu đã duyệt
        approved_questions = (
            self._db.query(Question)
            .filter(
                Question.status == 'published',
                Question.subject_code == norm_subject,
                Question.grade_band == grade_band,
            )
            .all()
        )
        if len(approved_questions) < 6:
            raise PvpServiceError(
                code='INSUFFICIENT_APPROVED_QUESTIONS',
                message_vi=(
                    f'Chưa đủ tối thiểu 6 câu hỏi đã duyệt Bộ GD&ĐT cho môn {norm_subject} - '
                    f'{grade_band} để mở đấu trường giao hữu.'
                ),
                status_code=400,
            )

        # 2. Kiểm tra nếu user đang có trận đấu dở dang (in_progress)
        existing_player = (
            self._db.query(MatchPlayer)
            .join(Match, Match.id == MatchPlayer.match_id)
            .filter(
                MatchPlayer.user_id == user_id,
                Match.status == 'in_progress',
            )
            .first()
        )
        if existing_player:
            return self.get_match_snapshot(
                match_id=existing_player.match_id, user_id=user_id
            )

        # 3. Tìm đối thủ phù hợp trong hàng đợi
        opponent_entry = (
            self._db.query(MatchQueue)
            .filter(
                MatchQueue.user_id != user_id,
                MatchQueue.subject_code == norm_subject,
                MatchQueue.grade_band == grade_band,
                MatchQueue.curriculum == curriculum,
            )
            .first()
        )

        if not opponent_entry:
            # Chưa có đối thủ -> ghi nhận vào hàng đợi
            existing_queue = (
                self._db.query(MatchQueue).filter(MatchQueue.user_id == user_id).first()
            )
            if existing_queue:
                existing_queue.champion_id = norm_champ.value
                existing_queue.subject_code = norm_subject
                existing_queue.grade_band = grade_band
                existing_queue.curriculum = curriculum
                existing_queue.queued_at = utc_now()
            else:
                new_queue = MatchQueue(
                    user_id=user_id,
                    champion_id=norm_champ.value,
                    subject_code=norm_subject,
                    grade_band=grade_band,
                    curriculum=curriculum,
                    queued_at=utc_now(),
                )
                self._db.add(new_queue)
            self._db.commit()

            return {
                'status': 'waiting',
                'subject_code': norm_subject,
                'grade_band': grade_band,
                'curriculum': curriculum,
                'message_vi': 'Đang tìm kiếm đối thủ cùng môn và khối lớp...',
            }

        # 4. Tìm thấy đối thủ -> Khởi tạo trận đấu thật trong transaction
        opponent_user_id = opponent_entry.user_id
        opponent_champion_id = opponent_entry.champion_id

        # Xóa cả hai khỏi hàng đợi
        self._db.delete(opponent_entry)
        my_queue = (
            self._db.query(MatchQueue).filter(MatchQueue.user_id == user_id).first()
        )
        if my_queue:
            self._db.delete(my_queue)

        # Chọn 6 câu hỏi độc lập (xáo trộn)
        selected_questions = list(approved_questions)
        random.shuffle(selected_questions)
        q_pool = selected_questions[:6]

        # Khởi tạo Match
        secret_round_no = 3  # Chọn round 3 làm secret round
        new_match = Match(
            subject_code=norm_subject,
            grade_band=grade_band,
            curriculum=curriculum,
            status='in_progress',
            rule_version=COMBAT_RULE_VERSION,
            current_round=1,
            secret_round_no=secret_round_no,
        )
        self._db.add(new_match)
        self._db.flush()

        # Tạo MatchPlayer cho 2 đấu thủ
        player_a = MatchPlayer(
            match_id=new_match.id,
            user_id=user_id,
            champion_id=norm_champ.value,
        )
        player_b = MatchPlayer(
            match_id=new_match.id,
            user_id=opponent_user_id,
            champion_id=opponent_champion_id,
        )
        self._db.add_all([player_a, player_b])

        # Tạo MatchRound 1
        q1 = q_pool[0]
        round_1_deadline = utc_now() + timedelta(seconds=75)
        round_1 = MatchRound(
            match_id=new_match.id,
            round_no=1,
            question_id=q1.id,
            question_revision=q1.revision,
            prompt=q1.prompt,
            reasoning_prompt_vi=q1.reasoning_prompt_vi,
            rubric_json=q1.rubric_json or {},
            deadline_at=round_1_deadline,
            state='answering',
        )
        self._db.add(round_1)

        # Ghi các sự kiện đồng bộ tuần tự (monotonic sequence)
        ev_matched = MatchEvent(
            match_id=new_match.id,
            sequence=1,
            event_type='matched',
            payload_json={
                'match_id': new_match.id,
                'subject_code': norm_subject,
                'grade_band': grade_band,
                'player_a': {'user_id': user_id, 'champion_id': norm_champ.value},
                'player_b': {
                    'user_id': opponent_user_id,
                    'champion_id': opponent_champion_id,
                },
                'secret_round_no': secret_round_no,
            },
        )
        ev_round_1 = MatchEvent(
            match_id=new_match.id,
            sequence=2,
            event_type='round_started',
            payload_json={
                'round_no': 1,
                'question_id': q1.id,
                'question_revision': q1.revision,
                'prompt': q1.prompt,
                'reasoning_prompt_vi': q1.reasoning_prompt_vi,
                'deadline_at': _iso_utc(round_1_deadline),
                'is_secret_round': (secret_round_no == 1),
            },
        )
        self._db.add_all([ev_matched, ev_round_1])
        self._db.commit()

        return self.get_match_snapshot(match_id=new_match.id, user_id=user_id)

    def cancel_queue(self, *, user_id: str) -> dict[str, Any]:
        """Rút khỏi hàng đợi tìm trận."""
        entry = self._db.query(MatchQueue).filter(MatchQueue.user_id == user_id).first()
        if entry:
            self._db.delete(entry)
            self._db.commit()
            return {'cancelled': True, 'message_vi': 'Đã hủy tìm kiếm trận đấu.'}
        return {'cancelled': False, 'message_vi': 'Bạn không ở trong hàng đợi.'}

    def get_match_snapshot(self, *, match_id: str, user_id: str) -> dict[str, Any]:
        """Lấy snapshot trận đấu với kiểm tra quyền người tham gia (Authorization Isolation)."""
        match = self._db.query(Match).filter(Match.id == match_id).first()
        if not match:
            raise PvpServiceError(
                code='MATCH_NOT_FOUND',
                message_vi='Không tìm thấy trận đấu.',
                status_code=404,
            )

        players = self._db.query(MatchPlayer).filter(MatchPlayer.match_id == match_id).all()
        participant_ids = {p.user_id for p in players}
        if user_id not in participant_ids:
            raise PvpServiceError(
                code='FORBIDDEN',
                message_vi='Bạn không phải người tham gia trận đấu này.',
                status_code=403,
            )

        # Thông tin round hiện tại
        current_round = (
            self._db.query(MatchRound)
            .filter(
                MatchRound.match_id == match_id,
                MatchRound.round_no == match.current_round,
            )
            .first()
        )

        # Bài nộp của round hiện tại
        submissions = (
            self._db.query(RoundSubmission)
            .filter(
                RoundSubmission.match_id == match_id,
                RoundSubmission.round_no == match.current_round,
            )
            .all()
        )
        sub_by_user = {s.user_id: s for s in submissions}
        my_sub = sub_by_user.get(user_id)
        opponent_id = (participant_ids - {user_id}).pop() if len(participant_ids) > 1 else None
        opp_sub = sub_by_user.get(opponent_id) if opponent_id else None

        # Alias từ bảng User
        users = self._db.query(User).filter(User.id.in_(list(participant_ids))).all()
        alias_map = {u.id: u.alias for u in users}

        players_data = []
        for p in players:
            players_data.append({
                'user_id': p.user_id,
                'alias': alias_map.get(p.user_id, 'Học sinh MindClock'),
                'champion_id': p.champion_id,
                'hp': p.hp,
                'armor': p.armor,
                'ward': p.ward,
                'qi': p.qi,
                'skill_1_used': p.skill_1_used,
                'skill_2_used': p.skill_2_used,
                'is_alive': p.hp > 0,
            })

        round_info: dict[str, Any] | None = None
        if current_round:
            round_info = {
                'round_no': current_round.round_no,
                'prompt': current_round.prompt,
                'reasoning_prompt_vi': current_round.reasoning_prompt_vi,
                'deadline_at': _iso_utc(current_round.deadline_at),
                'state': current_round.state,
                'is_secret_round': (match.secret_round_no == current_round.round_no),
                'my_submission': (
                    {
                        'submitted': True,
                        'grade_status': (
                            my_sub.grade_status
                            if current_round.state in {'action_window', 'settled'}
                            else 'grading_pending'
                        ),
                        'feedback_vi': (
                            my_sub.feedback_vi
                            if current_round.state in {'action_window', 'settled'}
                            else ''
                        ),
                    }
                    if my_sub
                    else {'submitted': False}
                ),
                'opponent_submitted': bool(opp_sub),
            }

        return {
            'match_id': match.id,
            'status': match.status,
            'rule_version': match.rule_version,
            'subject_code': match.subject_code,
            'grade_band': match.grade_band,
            'current_round': match.current_round,
            'secret_round_no': match.secret_round_no,
            'winner_user_id': match.winner_user_id,
            'finish_reason': match.finish_reason,
            'players': players_data,
            'current_round_info': round_info,
        }

    def get_match_events(
        self,
        *,
        match_id: str,
        user_id: str,
        after_sequence: int = 0,
    ) -> list[dict[str, Any]]:
        """Lấy dòng sự kiện tăng dần để đồng bộ hoặc khôi phục kết nối (Reconnect)."""
        players = self._db.query(MatchPlayer).filter(MatchPlayer.match_id == match_id).all()
        participant_ids = {p.user_id for p in players}
        if user_id not in participant_ids:
            raise PvpServiceError(
                code='FORBIDDEN',
                message_vi='Bạn không có quyền truy cập sự kiện của trận đấu này.',
                status_code=403,
            )

        events = (
            self._db.query(MatchEvent)
            .filter(
                MatchEvent.match_id == match_id,
                MatchEvent.sequence > after_sequence,
            )
            .order_by(MatchEvent.sequence.asc())
            .all()
        )

        return [
            {
                'sequence': ev.sequence,
                'event_type': ev.event_type,
                'payload': ev.payload_json,
                'created_at': _iso_utc(ev.created_at),
            }
            for ev in events
        ]

    def _next_event_sequence(self, match_id: str) -> int:
        last_seq = (
            self._db.query(func.max(MatchEvent.sequence))
            .filter(MatchEvent.match_id == match_id)
            .scalar()
        )
        return (last_seq or 0) + 1

    def submit_round_answer(
        self,
        *,
        match_id: str,
        round_no: int,
        user_id: str,
        answer_text: str,
        reasoning_text: str,
    ) -> dict[str, Any]:
        """Nộp bài làm (đáp án + 1 bước lý giải bắt buộc) với tính lũy đẳng (Idempotency)."""
        match = self._db.query(Match).filter(Match.id == match_id).first()
        if not match or match.status != 'in_progress':
            raise PvpServiceError(
                code='MATCH_NOT_ACTIVE',
                message_vi='Trận đấu không ở trạng thái hoạt động.',
            )
        if match.current_round != round_no:
            raise PvpServiceError(
                code='INVALID_ROUND',
                message_vi='Round nộp bài không hợp lệ.',
            )

        players = self._db.query(MatchPlayer).filter(MatchPlayer.match_id == match_id).all()
        participant_ids = {p.user_id for p in players}
        if user_id not in participant_ids:
            raise PvpServiceError(
                code='FORBIDDEN',
                message_vi='Bạn không có quyền nộp bài cho trận này.',
                status_code=403,
            )

        current_round = (
            self._db.query(MatchRound)
            .filter(MatchRound.match_id == match_id, MatchRound.round_no == round_no)
            .first()
        )
        if not current_round or current_round.state != 'answering':
            raise PvpServiceError(
                code='ROUND_NOT_ANSWERING',
                message_vi='Round hiện tại không trong thời gian nộp bài.',
            )

        # Idempotency: nếu đã nộp rồi thì trả lại kết quả cũ
        existing_sub = (
            self._db.query(RoundSubmission)
            .filter(
                RoundSubmission.match_id == match_id,
                RoundSubmission.round_no == round_no,
                RoundSubmission.user_id == user_id,
            )
            .first()
        )
        if existing_sub:
            return {
                'submitted': True,
                'grade_status': existing_sub.grade_status,
                'round_state': current_round.state,
                'feedback_vi': existing_sub.feedback_vi,
                'is_duplicate': True,
            }

        clean_reasoning = reasoning_text.strip()
        clean_answer = answer_text.strip().lower()

        # Kiểm tra deadline
        deadline_tz = current_round.deadline_at
        if deadline_tz.tzinfo is None:
            deadline_tz = deadline_tz.replace(tzinfo=timezone.utc)

        is_timeout = utc_now() > deadline_tz
        if is_timeout:
            grade_status = 'timeout'
            feedback_vi = 'Hết thời gian làm bài của round.'
        elif len(clean_reasoning) < 3:
            # Bắt buộc kèm một bước trình bày; chỉ khoanh đáp án không kích hoạt chiêu
            grade_status = 'incorrect'
            feedback_vi = 'Cần nộp kèm ít nhất một bước trình bày lời giải để kích hoạt chiêu thức.'
        else:
            # Chấm bài theo rubric chuẩn của question
            q = self._db.query(Question).filter(Question.id == current_round.question_id).first()
            accepted_answers: list[str] = []
            if q and q.answer_spec_json:
                spec = q.answer_spec_json
                if isinstance(spec, str):
                    try:
                        spec = json.loads(spec)
                    except Exception:
                        spec = {}
                if isinstance(spec, dict):
                    accepted_answers = [
                        str(a).strip().lower()
                        for a in spec.get('accepted', [])
                    ]
            if not accepted_answers:
                accepted_answers = [clean_answer]

            # Kiểm tra đáp án chính xác (chuẩn hóa số thập phân, phân số, biến, đơn vị)
            if is_answer_accepted(clean_answer, accepted_answers):
                grade_status = 'correct'
                feedback_vi = 'Đáp án và bước trình bày chính xác.'
            else:
                grade_status = 'incorrect'
                feedback_vi = 'Đáp án hoặc bước biến đổi chưa chính xác.'

        submission = RoundSubmission(
            match_id=match_id,
            round_no=round_no,
            user_id=user_id,
            answer_text=answer_text,
            reasoning_text=reasoning_text,
            grade_status=grade_status,
            feedback_vi=feedback_vi,
            submitted_at=utc_now(),
        )
        self._db.add(submission)
        self._db.flush()

        all_subs = (
            self._db.query(RoundSubmission)
            .filter(RoundSubmission.match_id == match_id, RoundSubmission.round_no == round_no)
            .all()
        )

        if len(all_subs) >= 2:
            # Cả hai bên đã nộp xong -> kiểm tra nếu có uncertain
            has_uncertain = any(s.grade_status == 'uncertain' for s in all_subs)
            if has_uncertain:
                current_round.state = 'void'
                seq = self._next_event_sequence(match_id)
                self._db.add(
                    MatchEvent(
                        match_id=match_id,
                        sequence=seq,
                        event_type='round_voided',
                        payload_json={'round_no': round_no, 'reason': 'uncertain_submission_review'},
                    )
                )
            else:
                current_round.state = 'action_window'
                seq = self._next_event_sequence(match_id)
                grades_map = {s.user_id: s.grade_status for s in all_subs}
                self._db.add(
                    MatchEvent(
                        match_id=match_id,
                        sequence=seq,
                        event_type='action_window_opened',
                        payload_json={
                            'round_no': round_no,
                            'action_window_seconds': 6,
                            'grades': grades_map,
                        },
                    )
                )
        else:
            # Một bên nộp -> ghi nhận sự kiện nộp bài an toàn
            seq = self._next_event_sequence(match_id)
            self._db.add(
                MatchEvent(
                    match_id=match_id,
                    sequence=seq,
                    event_type='submission_accepted',
                    payload_json={'round_no': round_no, 'user_id': user_id},
                )
            )

        self._db.commit()
        return {
            'submitted': True,
            'grade_status': grade_status,
            'round_state': current_round.state,
            'feedback_vi': feedback_vi,
        }

    def choose_round_action(
        self,
        *,
        match_id: str,
        round_no: int,
        user_id: str,
        raw_action_type: str,
    ) -> dict[str, Any]:
        """Chọn chiêu thức trong cửa sổ hành động và giải quyết round khi cả hai đã chọn."""
        match = self._db.query(Match).filter(Match.id == match_id).first()
        if not match or match.status != 'in_progress':
            raise PvpServiceError(
                code='MATCH_NOT_ACTIVE',
                message_vi='Trận đấu không ở trạng thái hoạt động.',
            )
        if match.current_round != round_no:
            raise PvpServiceError(
                code='INVALID_ROUND',
                message_vi='Round chọn chiêu không hợp lệ.',
            )

        players = self._db.query(MatchPlayer).filter(MatchPlayer.match_id == match_id).all()
        participant_ids = {p.user_id for p in players}
        if user_id not in participant_ids:
            raise PvpServiceError(
                code='FORBIDDEN',
                message_vi='Bạn không có quyền chọn chiêu.',
                status_code=403,
            )

        current_round = (
            self._db.query(MatchRound)
            .filter(MatchRound.match_id == match_id, MatchRound.round_no == round_no)
            .first()
        )
        if not current_round or current_round.state != 'action_window':
            raise PvpServiceError(
                code='ACTION_WINDOW_CLOSED',
                message_vi='Cửa sổ chọn chiêu chưa mở hoặc đã kết thúc.',
            )

        # Idempotency
        existing_act = (
            self._db.query(RoundAction)
            .filter(
                RoundAction.match_id == match_id,
                RoundAction.round_no == round_no,
                RoundAction.user_id == user_id,
            )
            .first()
        )
        if existing_act:
            return {
                'action_type': existing_act.action_type,
                'round_state': current_round.state,
                'is_duplicate': True,
            }

        norm_action = raw_action_type.strip().lower()
        if norm_action not in {'basic', 'skill_1', 'skill_2'}:
            norm_action = 'basic'

        action_rec = RoundAction(
            match_id=match_id,
            round_no=round_no,
            user_id=user_id,
            action_type=norm_action,
        )
        self._db.add(action_rec)
        self._db.flush()

        all_actions = (
            self._db.query(RoundAction)
            .filter(RoundAction.match_id == match_id, RoundAction.round_no == round_no)
            .all()
        )

        settle_result_data: dict[str, Any] | None = None
        if len(all_actions) >= 2:
            # Settle round bằng pure combat engine Server-Authoritative!
            p_map = {p.user_id: p for p in players}
            act_map = {a.user_id: a.action_type for a in all_actions}
            subs = (
                self._db.query(RoundSubmission)
                .filter(RoundSubmission.match_id == match_id, RoundSubmission.round_no == round_no)
                .all()
            )
            sub_map = {s.user_id: s.grade_status for s in subs}

            u_list = list(p_map.keys())
            u_a, u_b = u_list[0], u_list[1]
            mp_a, mp_b = p_map[u_a], p_map[u_b]

            state_a = PlayerCombatState(
                user_id=u_a,
                champion_id=normalize_champion_id(mp_a.champion_id),
                hp=mp_a.hp,
                armor=mp_a.armor,
                ward=mp_a.ward,
                qi=mp_a.qi,
                consecutive_correct=mp_a.consecutive_correct,
                skill_1_used=mp_a.skill_1_used,
                skill_2_used=mp_a.skill_2_used,
                passive_trigger_count=mp_a.passive_triggers,
                passive_pending_ward=mp_a.passive_pending_ward,
                buff_next_basic_bonus=mp_a.buff_next_basic,
                penalty_next_basic=mp_a.penalty_next_basic,
            )
            state_b = PlayerCombatState(
                user_id=u_b,
                champion_id=normalize_champion_id(mp_b.champion_id),
                hp=mp_b.hp,
                armor=mp_b.armor,
                ward=mp_b.ward,
                qi=mp_b.qi,
                consecutive_correct=mp_b.consecutive_correct,
                skill_1_used=mp_b.skill_1_used,
                skill_2_used=mp_b.skill_2_used,
                passive_trigger_count=mp_b.passive_triggers,
                passive_pending_ward=mp_b.passive_pending_ward,
                buff_next_basic_bonus=mp_b.buff_next_basic,
                penalty_next_basic=mp_b.penalty_next_basic,
            )

            settle_res = settle_combat_round(
                round_no=round_no,
                player_a=state_a,
                player_b=state_b,
                input_a=RoundActionInput(
                    user_id=u_a,
                    grade=sub_map.get(u_a, 'incorrect'),
                    action=ActionType(act_map.get(u_a, 'basic')),
                ),
                input_b=RoundActionInput(
                    user_id=u_b,
                    grade=sub_map.get(u_b, 'incorrect'),
                    action=ActionType(act_map.get(u_b, 'basic')),
                ),
                is_secret_round=(match.secret_round_no == round_no),
            )

            # Cập nhật DB cho player A & B
            mp_a.hp = state_a.hp
            mp_a.armor = state_a.armor
            mp_a.ward = state_a.ward
            mp_a.qi = state_a.qi
            mp_a.skill_1_used = state_a.skill_1_used
            mp_a.skill_2_used = state_a.skill_2_used
            mp_a.consecutive_correct = state_a.consecutive_correct
            mp_a.passive_triggers = state_a.passive_trigger_count
            mp_a.passive_pending_ward = state_a.passive_pending_ward
            mp_a.buff_next_basic = state_a.buff_next_basic_bonus
            mp_a.penalty_next_basic = state_a.penalty_next_basic

            mp_b.hp = state_b.hp
            mp_b.armor = state_b.armor
            mp_b.ward = state_b.ward
            mp_b.qi = state_b.qi
            mp_b.skill_1_used = state_b.skill_1_used
            mp_b.skill_2_used = state_b.skill_2_used
            mp_b.consecutive_correct = state_b.consecutive_correct
            mp_b.passive_triggers = state_b.passive_trigger_count
            mp_b.passive_pending_ward = state_b.passive_pending_ward
            mp_b.buff_next_basic = state_b.buff_next_basic_bonus
            mp_b.penalty_next_basic = state_b.penalty_next_basic

            current_round.state = 'settled'

            # Phát event round_settled
            seq = self._next_event_sequence(match_id)
            delta_a_dict = {
                'user_id': settle_res.player_a_delta.user_id,
                'action_used': (
                    settle_res.player_a_delta.action_used.value
                    if settle_res.player_a_delta.action_used
                    else None
                ),
                'raw_damage_dealt': settle_res.player_a_delta.raw_damage_dealt,
                'damage_taken': settle_res.player_a_delta.damage_taken,
                'ward_absorbed': settle_res.player_a_delta.ward_absorbed,
                'armor_damage_taken': settle_res.player_a_delta.armor_damage_taken,
                'hp_damage_taken': settle_res.player_a_delta.hp_damage_taken,
                'hp_healed': settle_res.player_a_delta.hp_healed,
                'armor_healed': settle_res.player_a_delta.armor_healed,
                'ward_added_in_round': settle_res.player_a_delta.ward_added_in_round,
                'qi_spent': settle_res.player_a_delta.qi_spent,
                'qi_gained': settle_res.player_a_delta.qi_gained,
                'passive_triggered': settle_res.player_a_delta.passive_triggered,
                'passive_effect_vi': settle_res.player_a_delta.passive_effect_vi,
                'new_hp': state_a.hp,
                'new_armor': state_a.armor,
                'new_ward': state_a.ward,
                'new_qi': state_a.qi,
                'is_alive': state_a.is_alive,
            }
            delta_b_dict = {
                'user_id': settle_res.player_b_delta.user_id,
                'action_used': (
                    settle_res.player_b_delta.action_used.value
                    if settle_res.player_b_delta.action_used
                    else None
                ),
                'raw_damage_dealt': settle_res.player_b_delta.raw_damage_dealt,
                'damage_taken': settle_res.player_b_delta.damage_taken,
                'ward_absorbed': settle_res.player_b_delta.ward_absorbed,
                'armor_damage_taken': settle_res.player_b_delta.armor_damage_taken,
                'hp_damage_taken': settle_res.player_b_delta.hp_damage_taken,
                'hp_healed': settle_res.player_b_delta.hp_healed,
                'armor_healed': settle_res.player_b_delta.armor_healed,
                'ward_added_in_round': settle_res.player_b_delta.ward_added_in_round,
                'qi_spent': settle_res.player_b_delta.qi_spent,
                'qi_gained': settle_res.player_b_delta.qi_gained,
                'passive_triggered': settle_res.player_b_delta.passive_triggered,
                'passive_effect_vi': settle_res.player_b_delta.passive_effect_vi,
                'new_hp': state_b.hp,
                'new_armor': state_b.armor,
                'new_ward': state_b.ward,
                'new_qi': state_b.qi,
                'is_alive': state_b.is_alive,
            }
            self._db.add(
                MatchEvent(
                    match_id=match_id,
                    sequence=seq,
                    event_type='round_settled',
                    payload_json={
                        'round_no': round_no,
                        'delta_a': delta_a_dict,
                        'delta_b': delta_b_dict,
                        'match_finished': settle_res.match_finished,
                        'winner_user_id': settle_res.winner_user_id,
                        'finish_reason': settle_res.finish_reason,
                    },
                )
            )
            self._db.flush()

            if settle_res.match_finished:
                match.status = 'completed'
                match.winner_user_id = settle_res.winner_user_id
                match.finish_reason = settle_res.finish_reason
                seq_fin = self._next_event_sequence(match_id)
                self._db.add(
                    MatchEvent(
                        match_id=match_id,
                        sequence=seq_fin,
                        event_type='match_finished',
                        payload_json={
                            'match_id': match_id,
                            'winner_user_id': settle_res.winner_user_id,
                            'finish_reason': settle_res.finish_reason,
                        },
                    )
                )
            else:
                next_round_no = round_no + 1
                match.current_round = next_round_no
                approved_questions = (
                    self._db.query(Question)
                    .filter(
                        Question.status == 'published',
                        Question.subject_code == match.subject_code,
                        Question.grade_band == match.grade_band,
                    )
                    .all()
                )
                used_q_ids = {
                    r.question_id
                    for r in self._db.query(MatchRound).filter(MatchRound.match_id == match_id).all()
                }
                avail_questions = [q for q in approved_questions if q.id not in used_q_ids]
                next_q = avail_questions[0] if avail_questions else approved_questions[0]

                next_deadline = utc_now() + timedelta(seconds=75)
                next_round = MatchRound(
                    match_id=match_id,
                    round_no=next_round_no,
                    question_id=next_q.id,
                    question_revision=next_q.revision,
                    prompt=next_q.prompt,
                    reasoning_prompt_vi=next_q.reasoning_prompt_vi,
                    rubric_json=next_q.rubric_json or {},
                    deadline_at=next_deadline,
                    state='answering',
                )
                self._db.add(next_round)

                seq_next = self._next_event_sequence(match_id)
                self._db.add(
                    MatchEvent(
                        match_id=match_id,
                        sequence=seq_next,
                        event_type='round_started',
                        payload_json={
                            'round_no': next_round_no,
                            'question_id': next_q.id,
                            'question_revision': next_q.revision,
                            'prompt': next_q.prompt,
                            'reasoning_prompt_vi': next_q.reasoning_prompt_vi,
                            'deadline_at': _iso_utc(next_deadline),
                            'is_secret_round': (match.secret_round_no == next_round_no),
                        },
                    )
                )

            settle_result_data = {
                'round_settled': True,
                'match_finished': settle_res.match_finished,
                'winner_user_id': settle_res.winner_user_id,
            }

        self._db.commit()
        return {
            'action_type': norm_action,
            'round_state': current_round.state,
            'settle_result': settle_result_data,
        }
