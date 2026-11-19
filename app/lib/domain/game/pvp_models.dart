import 'combat_catalog.dart';

/// Thông tin một đấu thủ trong trận PvP 1v1 từ server `/v1/pvp/*`.
class PvpPlayerSnapshot {
  const PvpPlayerSnapshot({
    required this.userId,
    required this.alias,
    required this.championId,
    required this.hp,
    required this.armor,
    required this.ward,
    required this.qi,
    required this.skill1Used,
    required this.skill2Used,
    required this.isAlive,
  });

  final String userId;
  final String alias;
  final ChampionId championId;
  final int hp;
  final int armor;
  final int ward;
  final int qi;
  final bool skill1Used;
  final bool skill2Used;
  final bool isAlive;

  factory PvpPlayerSnapshot.fromJson(Map<String, dynamic> json) {
    final String rawChamp = json['champion_id'] as String? ??
        json['championId'] as String? ??
        'ha_nhan';
    return PvpPlayerSnapshot(
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      alias: json['alias'] as String? ?? 'Học sinh MindClock',
      championId: ChampionId.fromCode(rawChamp),
      hp: (json['hp'] as num?)?.toInt() ?? 100,
      armor: (json['armor'] as num?)?.toInt() ?? 50,
      ward: (json['ward'] as num?)?.toInt() ?? 0,
      qi: (json['qi'] as num?)?.toInt() ?? 0,
      skill1Used: json['skill_1_used'] as bool? ?? json['skill1Used'] as bool? ?? false,
      skill2Used: json['skill_2_used'] as bool? ?? json['skill2Used'] as bool? ?? false,
      isAlive: json['is_alive'] as bool? ?? json['isAlive'] as bool? ?? true,
    );
  }
}

class PvpMySubmissionSnapshot {
  const PvpMySubmissionSnapshot({
    required this.submitted,
    this.gradeStatus,
    this.feedbackVi = '',
  });

  final bool submitted;
  final String? gradeStatus;
  final String feedbackVi;

  factory PvpMySubmissionSnapshot.fromJson(Map<String, dynamic> json) {
    return PvpMySubmissionSnapshot(
      submitted: json['submitted'] as bool? ?? false,
      gradeStatus: json['grade_status'] as String? ?? json['gradeStatus'] as String?,
      feedbackVi: json['feedback_vi'] as String? ?? json['feedbackVi'] as String? ?? '',
    );
  }
}

class PvpRoundInfo {
  const PvpRoundInfo({
    required this.roundNo,
    required this.questionId,
    required this.prompt,
    required this.reasoningPromptVi,
    required this.deadlineAtIso,
    required this.state,
    required this.isSecretRound,
    required this.mySubmission,
    required this.opponentSubmitted,
  });

  final int roundNo;
  final String questionId;
  final String prompt;
  final String reasoningPromptVi;
  final String deadlineAtIso;
  final String state; // 'answering' | 'action_window' | 'settled' | 'void'
  final bool isSecretRound;
  final PvpMySubmissionSnapshot mySubmission;
  final bool opponentSubmitted;

  factory PvpRoundInfo.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawSub =
        (json['my_submission'] as Map<String, dynamic>?) ??
            (json['mySubmission'] as Map<String, dynamic>?) ??
            const <String, dynamic>{};
    return PvpRoundInfo(
      roundNo: (json['round_no'] as num?)?.toInt() ??
          (json['roundNo'] as num?)?.toInt() ??
          1,
      questionId: json['question_id'] as String? ??
          json['questionId'] as String? ??
          '',
      prompt: json['prompt'] as String? ?? '',
      reasoningPromptVi: json['reasoning_prompt_vi'] as String? ??
          json['reasoningPromptVi'] as String? ??
          'Viết ngắn gọn bước giải.',
      deadlineAtIso:
          json['deadline_at'] as String? ?? json['deadlineAt'] as String? ?? '',
      state: json['state'] as String? ?? 'answering',
      isSecretRound:
          json['is_secret_round'] as bool? ?? json['isSecretRound'] as bool? ?? false,
      mySubmission: PvpMySubmissionSnapshot.fromJson(rawSub),
      opponentSubmitted: json['opponent_submitted'] as bool? ??
          json['opponentSubmitted'] as bool? ??
          false,
    );
  }
}

class PvpMatchSnapshot {
  const PvpMatchSnapshot({
    required this.matchId,
    required this.mode,
    required this.status,
    required this.ruleVersion,
    required this.subjectCode,
    required this.gradeBand,
    required this.currentRound,
    required this.secretRoundNo,
    this.winnerUserId,
    this.finishReason,
    this.players = const <PvpPlayerSnapshot>[],
    this.currentRoundInfo,
  });

  final String matchId;
  final String mode;
  final String status; // 'waiting' | 'in_progress' | 'completed' | 'void'
  final String ruleVersion;
  final String subjectCode;
  final String gradeBand;
  final int currentRound;
  final int secretRoundNo;
  final String? winnerUserId;
  final String? finishReason;
  final List<PvpPlayerSnapshot> players;
  final PvpRoundInfo? currentRoundInfo;

  bool get isWaiting => status == 'waiting';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed' || status == 'void';

  factory PvpMatchSnapshot.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawPlayers =
        json['players'] as List<dynamic>? ?? const <dynamic>[];
    final Map<String, dynamic>? rawRound =
        (json['current_round_info'] as Map<String, dynamic>?) ??
            (json['currentRoundInfo'] as Map<String, dynamic>?);
    return PvpMatchSnapshot(
      matchId: json['match_id'] as String? ?? json['matchId'] as String? ?? '',
      mode: json['mode'] as String? ?? 'duel_1v1',
      status: json['status'] as String? ?? 'in_progress',
      ruleVersion:
          json['rule_version'] as String? ?? json['ruleVersion'] as String? ?? 'solo-three-v0.1',
      subjectCode:
          json['subject_code'] as String? ?? json['subjectCode'] as String? ?? 'TOAN',
      gradeBand:
          json['grade_band'] as String? ?? json['gradeBand'] as String? ?? 'Lớp 11',
      currentRound: (json['current_round'] as num?)?.toInt() ??
          (json['currentRound'] as num?)?.toInt() ??
          1,
      secretRoundNo: (json['secret_round_no'] as num?)?.toInt() ??
          (json['secretRoundNo'] as num?)?.toInt() ??
          3,
      winnerUserId:
          json['winner_user_id'] as String? ?? json['winnerUserId'] as String?,
      finishReason:
          json['finish_reason'] as String? ?? json['finishReason'] as String?,
      players: rawPlayers
          .whereType<Map<String, dynamic>>()
          .map(PvpPlayerSnapshot.fromJson)
          .toList(growable: false),
      currentRoundInfo:
          rawRound != null ? PvpRoundInfo.fromJson(rawRound) : null,
    );
  }
}

class PvpMatchmakeResponse {
  const PvpMatchmakeResponse({
    required this.isWaiting,
    this.messageVi,
    this.matchSnapshot,
  });

  final bool isWaiting;
  final String? messageVi;
  final PvpMatchSnapshot? matchSnapshot;

  factory PvpMatchmakeResponse.fromJson(Map<String, dynamic> json) {
    final String status = json['status'] as String? ?? '';
    if (status == 'waiting' && (json['match_id'] == null && json['matchId'] == null)) {
      return PvpMatchmakeResponse(
        isWaiting: true,
        messageVi: json['message_vi'] as String? ??
            json['messageVi'] as String? ??
            'Đang tìm đối thủ cùng môn và khối lớp...',
      );
    }
    return PvpMatchmakeResponse(
      isWaiting: false,
      matchSnapshot: PvpMatchSnapshot.fromJson(json),
    );
  }
}

class PvpMatchEvent {
  const PvpMatchEvent({
    required this.sequence,
    required this.eventType,
    this.payload = const <String, dynamic>{},
  });

  final int sequence;
  final String eventType;
  final Map<String, dynamic> payload;

  factory PvpMatchEvent.fromJson(Map<String, dynamic> json) {
    return PvpMatchEvent(
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      eventType: json['event_type'] as String? ?? json['eventType'] as String? ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ??
          (json['payload_json'] as Map<String, dynamic>?) ??
          const <String, dynamic>{},
    );
  }
}

class PvpRoundSubmitResponse {
  const PvpRoundSubmitResponse({
    required this.submitted,
    required this.gradeStatus,
    required this.roundState,
    required this.feedbackVi,
  });

  final bool submitted;
  final String gradeStatus;
  final String roundState;
  final String feedbackVi;

  factory PvpRoundSubmitResponse.fromJson(Map<String, dynamic> json) {
    return PvpRoundSubmitResponse(
      submitted: json['submitted'] as bool? ?? true,
      gradeStatus:
          json['grade_status'] as String? ?? json['gradeStatus'] as String? ?? 'grading_pending',
      roundState:
          json['round_state'] as String? ?? json['roundState'] as String? ?? 'answering',
      feedbackVi:
          json['feedback_vi'] as String? ?? json['feedbackVi'] as String? ?? '',
    );
  }
}

class PvpRoundActionResponse {
  const PvpRoundActionResponse({
    required this.actionType,
    required this.roundState,
    this.settleResult,
  });

  final String actionType;
  final String roundState;
  final Map<String, dynamic>? settleResult;

  factory PvpRoundActionResponse.fromJson(Map<String, dynamic> json) {
    return PvpRoundActionResponse(
      actionType: json['action_type'] as String? ?? json['actionType'] as String? ?? 'basic',
      roundState: json['round_state'] as String? ?? json['roundState'] as String? ?? 'settled',
      settleResult: (json['settle_result'] as Map<String, dynamic>?) ??
          (json['settleResult'] as Map<String, dynamic>?),
    );
  }
}
