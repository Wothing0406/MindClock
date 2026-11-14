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

/// Câu hỏi luyện tập cá nhân hóa sinh ở backend (`POST /v1/questions/personalized`).
///
/// Bản nháp AI cá nhân hóa (`status: draft`, `xpAwarded: 0`) không thay thế ngân hàng
/// báo thức đã duyệt (`GET /v1/challenges/next`).
class PersonalizedPracticeQuestion {
  const PersonalizedPracticeQuestion({
    required this.questionId,
    required this.subjectCode,
    required this.gradeBand,
    required this.topicId,
    required this.difficulty,
    required this.prompt,
    required this.reasoningPromptVi,
    required this.steps,
    this.hintVi,
    required this.status,
    required this.sourceType,
    required this.modelVersion,
    this.xpAwarded = 0,
    this.fallbackUsed = false,
    this.isDebugFixture = false,
  });

  final String questionId;
  final String subjectCode;
  final String gradeBand;
  final String topicId;
  final int difficulty;
  final String prompt;
  final String reasoningPromptVi;
  final List<String> steps;
  final String? hintVi;
  final String status;
  final String sourceType;
  final String modelVersion;
  final int xpAwarded;
  final bool fallbackUsed;
  final bool isDebugFixture;

  factory PersonalizedPracticeQuestion.fromJson(
    Map<String, dynamic> json, {
    required bool isDebugFixture,
  }) {
    final List<dynamic> rawSteps =
        (json['steps'] as List<dynamic>?) ?? const <dynamic>[];
    final String rawHint = (json['hintVi'] ?? '').toString().trim();
    return PersonalizedPracticeQuestion(
      questionId: (json['questionId'] ?? '').toString(),
      subjectCode: (json['subjectCode'] ?? 'TOAN').toString(),
      gradeBand: (json['gradeBand'] ?? 'Lớp 9').toString(),
      topicId: (json['topicId'] ?? '').toString(),
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      prompt: (json['prompt'] ?? '').toString(),
      reasoningPromptVi: (json['reasoningPromptVi'] ?? '').toString(),
      steps: rawSteps
          .map((dynamic e) => e.toString().trim())
          .where((String s) => s.isNotEmpty)
          .toList(growable: false),
      hintVi: rawHint.isEmpty ? null : rawHint,
      status: (json['status'] ?? 'draft').toString(),
      sourceType: (json['sourceType'] ?? 'ai_personalized_draft').toString(),
      modelVersion: (json['modelVersion'] ?? 'gemini-3.8-flash').toString(),
      xpAwarded: (json['xpAwarded'] as num?)?.toInt() ?? 0,
      fallbackUsed: json['fallbackUsed'] == true,
      isDebugFixture: isDebugFixture,
    );
  }
}

/// Ephemeral token dùng 1 lần cho phiên Gemini Live opt-in (`POST /v1/study/live-token`).
class GeminiLiveSessionToken {
  const GeminiLiveSessionToken({
    required this.tokenName,
    required this.wsUrl,
    required this.model,
    required this.expiresAt,
    required this.expiresInSeconds,
    required this.responseModalities,
    required this.contextSummary,
    this.isMock = false,
    this.isDebugFixture = false,
  });

  final String tokenName;
  final String wsUrl;
  final String model;
  final String expiresAt;
  final int expiresInSeconds;
  final List<String> responseModalities;
  final String contextSummary;
  final bool isMock;
  final bool isDebugFixture;

  factory GeminiLiveSessionToken.fromJson(
    Map<String, dynamic> json, {
    required bool isDebugFixture,
  }) {
    final List<dynamic> rawModalities =
        (json['responseModalities'] as List<dynamic>?) ?? const <dynamic>['AUDIO'];
    return GeminiLiveSessionToken(
      tokenName: (json['tokenName'] ?? '').toString(),
      wsUrl: (json['wsUrl'] ?? '').toString(),
      model: (json['model'] ?? 'gemini-3.8-live').toString(),
      expiresAt: (json['expiresAt'] ?? '').toString(),
      expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 600,
      responseModalities: rawModalities
          .map((dynamic e) => e.toString().trim())
          .where((String s) => s.isNotEmpty)
          .toList(growable: false),
      contextSummary: (json['contextSummary'] ?? '').toString(),
      isMock: json['isMock'] == true,
      isDebugFixture: isDebugFixture,
    );
  }
}
