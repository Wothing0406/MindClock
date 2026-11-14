/// Trạng thái UI khi gửi câu hỏi tới trợ lý học tập `/v1/study/help` (`docs/45 §§3,5`).
enum StudyAiRequestStatus {
  idle,
  loading,
  ready,
  timeout,
  rateLimited,
  offline,
  authExpired,
  error,
}

/// Một lượt trao đổi ngắn trong phiên học (`tối đa 3 lượt gần nhất` gửi lên backend).
class StudyHelpTurn {
  const StudyHelpTurn({
    required this.role,
    required this.contentVi,
    this.nextQuestionVi,
    this.helpLevel,
    this.safetyStatus,
    this.isOfflineFallback = false,
  });

  final String role; // 'user' hoặc 'assistant'
  final String contentVi;
  final String? nextQuestionVi;
  final String? helpLevel;
  final String? safetyStatus;
  final bool isOfflineFallback;

  Map<String, dynamic> toApiJson() => <String, dynamic>{
        'role': role,
        'contentVi': contentVi,
        if (nextQuestionVi != null && nextQuestionVi!.isNotEmpty)
          'nextQuestionVi': nextQuestionVi,
      };
}

class StudyHelpResponse {
  const StudyHelpResponse({
    required this.messageVi,
    this.nextQuestionVi,
    this.helpLevel = 'socratic',
    this.safetyStatus = 'safe',
    this.isDebugFixture = false,
  });

  static const String offlineFallbackMessageVi =
      'Ghi lại bước bạn đang vướng, rồi thử một cách khác.';

  final String messageVi;
  final String? nextQuestionVi;
  final String helpLevel;
  final String safetyStatus;
  final bool isDebugFixture;

  factory StudyHelpResponse.fromJson(
    Map<String, dynamic> json, {
    required bool isDebugFixture,
  }) {
    final String rawMessage =
        (json['message_vi'] ?? json['messageVi'] ?? '').toString().trim();
    final String rawNext =
        (json['next_question_vi'] ?? json['nextQuestionVi'] ?? '')
            .toString()
            .trim();
    return StudyHelpResponse(
      messageVi:
          rawMessage.isEmpty ? offlineFallbackMessageVi : rawMessage,
      nextQuestionVi: rawNext.isEmpty ? null : rawNext,
      helpLevel:
          (json['help_level'] ?? json['helpLevel'] ?? 'socratic').toString(),
      safetyStatus:
          (json['safety_status'] ?? json['safetyStatus'] ?? 'safe').toString(),
      isDebugFixture: isDebugFixture,
    );
  }
}

class RemoteStudySessionResult {
  const RemoteStudySessionResult({
    required this.remoteSessionId,
    required this.clientSessionId,
    required this.state,
    this.isDebugFixture = false,
  });

  final String remoteSessionId;
  final String clientSessionId;
  final String state;
  final bool isDebugFixture;

  factory RemoteStudySessionResult.fromJson(
    Map<String, dynamic> json, {
    required String fallbackClientSessionId,
    required bool isDebugFixture,
  }) {
    final String clientId =
        (json['clientSessionId'] ?? fallbackClientSessionId).toString();
    final String remoteId =
        (json['sessionId'] ?? json['id'] ?? clientId).toString();
    return RemoteStudySessionResult(
      remoteSessionId: remoteId.isEmpty ? clientId : remoteId,
      clientSessionId: clientId,
      state: (json['state'] ?? 'synced').toString(),
      isDebugFixture: isDebugFixture,
    );
  }
}
