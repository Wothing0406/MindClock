from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ApiModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)


class ProfilePatchRequest(ApiModel):
    alias: str | None = None
    grade_band: str | None = Field(default=None, alias='gradeLevel')
    selected_subjects: list[str] | None = Field(default=None, alias='selectedSubjects')
    goal_label: str | None = Field(default=None, alias='goalLabel')
    time_zone: str | None = Field(default=None, alias='timeZone')
    live_consent_granted: bool | None = Field(default=None, alias='liveConsentGranted')


class AlarmUpsertRequest(ApiModel):
    local_time: str = Field(alias='localTime', min_length=4, max_length=8)
    time_zone: str = Field(default='Asia/Ho_Chi_Minh', alias='timeZone')
    weekdays: list[int] = Field(default_factory=list)
    enabled: bool = True
    challenge_mode: str = Field(default='short_review', alias='challengeMode')
    snooze_minutes: int | None = Field(default=None, alias='snoozeMinutes')
    revision: int | None = None


class SessionCreateRequest(ApiModel):
    local_session_id: str = Field(alias='localSessionId', min_length=1, max_length=64)
    alarm_id: str = Field(default='primary_morning', alias='alarmId')
    question_id: str | None = Field(default=None, alias='questionId')
    local_date: str = Field(default='2026-11-14', alias='localDate')
    time_zone: str = Field(default='Asia/Ho_Chi_Minh', alias='timeZone')


class SessionEventRequest(ApiModel):
    event_type: str = Field(alias='eventType')
    occurred_at: str | None = Field(default=None, alias='occurredAt')
    version: int = 1


class SessionAnswerRequest(ApiModel):
    answer_value: str = Field(default='', alias='answerValue')
    reasoning_text: str = Field(default='', alias='reasoningText')


class SessionFeedbackRequest(ApiModel):
    attempt_id: str | None = Field(default=None, alias='attemptId')
    category: str | None = Field(default=None, max_length=64)
    comment: str | None = Field(default=None, max_length=400)
    reason: str | None = Field(default=None, max_length=400)


class TimetableSlotIn(ApiModel):
    weekday: int = Field(ge=1, le=7)
    subject_code: str = Field(alias='subjectCode', min_length=1, max_length=32)
    topic_id: str = Field(default='', alias='topicId', max_length=64)


class TimetablePutRequest(ApiModel):
    slots: list[TimetableSlotIn] = Field(default_factory=list, max_length=56)


class StudySessionCreateRequest(ApiModel):
    client_session_id: str = Field(alias='clientSessionId', min_length=1, max_length=64)
    task_title: str = Field(alias='taskTitle', min_length=1, max_length=160)
    subject_code: str | None = Field(default=None, alias='subjectCode')
    target_minutes: int = Field(default=25, alias='targetMinutes', ge=1, le=180)
    focus_level: str = Field(default='standard', alias='focusLevel')
    started_at: str | None = Field(default=None, alias='startedAt')


class StudySessionFinishRequest(ApiModel):
    client_session_id: str | None = Field(default=None, alias='clientSessionId')
    final_status: str = Field(default='completed', alias='finalStatus')
    elapsed_wall_seconds: int = Field(default=0, alias='elapsedWallSeconds', ge=0)
    in_app_focus_seconds: int = Field(default=0, alias='inAppFocusSeconds', ge=0)
    ended_at: str | None = Field(default=None, alias='endedAt')
    notes_done: str = Field(default='', alias='notesDone', max_length=500)
    notes_stuck: str = Field(default='', alias='notesStuck', max_length=500)


class StudyHelpTurnIn(ApiModel):
    role: str
    content_vi: str = Field(alias='contentVi')
    next_question_vi: str | None = Field(default=None, alias='nextQuestionVi')


class StudyHelpRequest(ApiModel):
    client_session_id: str = Field(alias='clientSessionId', min_length=1, max_length=64)
    subject: str = 'general'
    grade: str | None = None
    task: str = Field(min_length=1, max_length=160)
    question_text: str = Field(alias='questionText', min_length=1, max_length=600)
    recent_turns: list[StudyHelpTurnIn] = Field(default_factory=list, alias='recentTurns')


class PersonalizedQuestionRequest(ApiModel):
    subject_code: str = Field(alias='subjectCode', min_length=1, max_length=32)
    grade_level: str | None = Field(default=None, alias='gradeLevel')
    topic_hint: str | None = Field(default=None, alias='topicHint', max_length=120)
    difficulty: int = Field(default=1, ge=1, le=3)
    save_to_bank: bool = Field(default=True, alias='saveToBank')


class LiveTokenRequest(ApiModel):
    session_id: str | None = Field(default=None, alias='sessionId')
    subject_code: str = Field(default='TOAN', alias='subjectCode')
    grade_level: str | None = Field(default=None, alias='gradeLevel')
    task_title: str = Field(default='Ôn tập cá nhân', alias='taskTitle', max_length=160)
    response_modality: str = Field(default='AUDIO', alias='responseModality')
    consent_granted: bool = Field(default=False, alias='consentGranted')


class ConsentUpdateRequest(ApiModel):
    scope: str = Field(min_length=1, max_length=48)
    granted: bool
    version: str = '2026-11'
    extra: dict[str, Any] | None = None
