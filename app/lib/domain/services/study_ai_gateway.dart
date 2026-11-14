import '../models/study_ai_models.dart';
import '../models/study_focus_models.dart';

/// Gateway cho Không gian học AI (`docs/45 §5`):
/// - `POST /v1/study/sessions` (tạo/đồng bộ metadata idempotent)
/// - `POST /v1/study/sessions/{id}/finish` (kết thúc idempotent)
/// - `POST /v1/study/help` (trợ lý Socratic server-side, client KHÔNG giữ Gemini key)
abstract interface class StudyAiGateway {
  bool get isDebugFixture;

  Future<RemoteStudySessionResult> createStudySession({
    required StudyFocusSessionSnapshot snapshot,
    required String idempotencyKey,
  });

  Future<RemoteStudySessionResult> finishStudySession({
    required StudyFocusRecord record,
    required String idempotencyKey,
  });

  Future<StudyHelpResponse> requestHelp({
    required String sessionId,
    required String taskTitle,
    String? subjectCode,
    String? gradeLevel,
    required String questionText,
    required List<StudyHelpTurn> recentTurns,
    required String idempotencyKey,
  });
}
