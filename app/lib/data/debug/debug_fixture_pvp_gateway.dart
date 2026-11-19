import '../../domain/game/combat_catalog.dart';
import '../../domain/game/pvp_models.dart';
import '../../domain/game/solo_combat_engine.dart';
import '../../domain/game/solo_training_question_bank.dart';
import '../../domain/services/pvp_gateway.dart';

/// Gateway mẫu offline phục vụ kiểm thử & debug PvP (`isDebugFixture = true`).
class DebugFixturePvpGateway implements PvpGateway {
  DebugFixturePvpGateway({
    this.selfUserId = 'debug_user_a',
    this.opponentUserId = 'debug_user_b',
    this.opponentAlias = 'Gia Bảo (Demo)',
  });

  final String selfUserId;
  final String opponentUserId;
  final String opponentAlias;

  @override
  bool get isDebugFixture => true;

  bool _queuedOnce = false;
  int _roundNo = 1;
  bool _submitted = false;
  String _gradeStatus = 'correct';
  String _roundState = 'answering';
  String _status = 'in_progress';
  int _myHp = 100;
  int _myArmor = 50;
  int _myQi = 0;
  int _oppHp = 100;
  int _oppArmor = 50;
  int _oppQi = 1;
  bool _skill1Used = false;
  bool _skill2Used = false;
  ChampionId _myChamp = ChampionId.haNhan;
  String _subjectCode = 'TOAN';
  String _gradeBand = 'Lớp 11';

  @override
  Future<PvpMatchmakeResponse> matchmake({
    required String championId,
    required String subjectCode,
    required String gradeBand,
    String curriculum = 'gdpt_2018',
  }) async {
    _myChamp = ChampionId.fromCode(championId);
    _subjectCode = subjectCode;
    _gradeBand = gradeBand;
    if (!_queuedOnce) {
      _queuedOnce = true;
      _roundNo = 1;
      _myHp = 100;
      _myArmor = 50;
      _myQi = 0;
      _oppHp = 100;
      _oppArmor = 50;
      _oppQi = 0;
      _skill1Used = false;
      _skill2Used = false;
      _submitted = false;
      _roundState = 'answering';
      _status = 'in_progress';
      return const PvpMatchmakeResponse(
        isWaiting: true,
        messageVi: 'Mẫu debug: Đang tìm đối thủ cùng môn (bấm Kiểm tra lại để ghép)...',
      );
    }
    _queuedOnce = false;
    return PvpMatchmakeResponse(
      isWaiting: false,
      matchSnapshot: _buildSnapshot(),
    );
  }

  @override
  Future<void> cancelMatchmake() async {
    _queuedOnce = false;
  }

  @override
  Future<PvpMatchSnapshot> getMatch(String matchId) async {
    return _buildSnapshot();
  }

  @override
  Future<List<PvpMatchEvent>> getMatchEvents(
    String matchId, {
    int afterSequence = 0,
  }) async {
    if (afterSequence >= 1) return const <PvpMatchEvent>[];
    return const <PvpMatchEvent>[
      PvpMatchEvent(sequence: 1, eventType: 'matched'),
    ];
  }

  @override
  Future<PvpRoundSubmitResponse> submitRound({
    required String matchId,
    required int roundNo,
    required String answerText,
    required String reasoningText,
  }) async {
    _submitted = true;
    final String lowerReason = reasoningText.trim().toLowerCase();
    if (lowerReason.contains('uncertain') || answerText.trim().isEmpty) {
      _gradeStatus = 'uncertain';
      _roundState = 'void';
      return const PvpRoundSubmitResponse(
        submitted: true,
        gradeStatus: 'uncertain',
        roundState: 'void',
        feedbackVi: 'Chưa đủ rõ bước lập luận để chốt (round chuyển void, không phạt).',
      );
    }
    final SoloApprovedQuestion q = _currentQuestion();
    final SoloGradingFeedback grade = gradeSoloTrainingSubmission(
      question: q,
      answerText: answerText,
      reasoningText: reasoningText,
    );
    _gradeStatus = switch (grade.status) {
      SoloGradeStatus.correct => 'correct',
      SoloGradeStatus.incorrect => 'incorrect',
      SoloGradeStatus.uncertain => 'uncertain',
    };
    _roundState = _gradeStatus == 'uncertain' ? 'void' : 'action_window';
    return PvpRoundSubmitResponse(
      submitted: true,
      gradeStatus: _gradeStatus,
      roundState: _roundState,
      feedbackVi: grade.feedbackVi,
    );
  }

  @override
  Future<PvpRoundActionResponse> chooseAction({
    required String matchId,
    required int roundNo,
    required String actionType,
  }) async {
    int dmg = 0;
    if (_gradeStatus == 'correct') {
      if (actionType == 'skill_2' && _myQi >= 2 && !_skill2Used) {
        _skill2Used = true;
        _myQi -= 2;
        dmg = CombatCatalog.getSpec(_myChamp).skill2.damage;
      } else if (actionType == 'skill_1' && _myQi >= 1 && !_skill1Used) {
        _skill1Used = true;
        _myQi -= 1;
        dmg = CombatCatalog.getSpec(_myChamp).skill1.damage;
      } else {
        dmg = basicAttackDamage;
      }
      if (_myQi < maxQi) {
        _myQi += 1;
      }
      final int armorBreak = dmg.clamp(0, _oppArmor);
      _oppArmor -= armorBreak;
      _oppHp = (_oppHp - (dmg - armorBreak)).clamp(0, maxHp);
    }

    if (_oppHp > 0 && _oppArmor > 0) {
      const int oppDmg = 18;
      final int armorHit = oppDmg.clamp(0, _myArmor);
      _myArmor -= armorHit;
      _myHp = (_myHp - (oppDmg - armorHit)).clamp(0, maxHp);
      if (_oppQi < maxQi) _oppQi += 1;
    }

    if (_oppHp == 0 || _myHp == 0 || _roundNo >= maxCombatRounds) {
      _status = 'completed';
    } else {
      _roundNo += 1;
      _submitted = false;
      _roundState = 'answering';
    }
    return PvpRoundActionResponse(
      actionType: actionType,
      roundState: 'settled',
      settleResult: <String, dynamic>{
        'damageDealt': dmg,
        'nextRound': _roundNo,
      },
    );
  }

  SoloApprovedQuestion _currentQuestion() {
    final List<SoloApprovedQuestion> deck =
        SoloTrainingQuestionBank.selectDeterministicDeck(
      subjectCode: _subjectCode == 'TOAN' ? 'math' : 'math',
      seed: 20261119,
    );
    return deck[(_roundNo - 1) % deck.length];
  }

  PvpMatchSnapshot _buildSnapshot() {
    final SoloApprovedQuestion q = _currentQuestion();
    return PvpMatchSnapshot(
      matchId: 'pvp_debug_01',
      mode: 'duel_1v1',
      status: _status,
      ruleVersion: combatRuleVersion,
      subjectCode: _subjectCode,
      gradeBand: _gradeBand,
      currentRound: _roundNo,
      secretRoundNo: 3,
      winnerUserId: _status == 'completed' ? selfUserId : null,
      finishReason: _status == 'completed' ? 'ko_or_round_limit' : null,
      players: <PvpPlayerSnapshot>[
        PvpPlayerSnapshot(
          userId: selfUserId,
          alias: 'Bạn',
          championId: _myChamp,
          hp: _myHp,
          armor: _myArmor,
          ward: 0,
          qi: _myQi,
          skill1Used: _skill1Used,
          skill2Used: _skill2Used,
          isAlive: _myHp > 0,
        ),
        PvpPlayerSnapshot(
          userId: opponentUserId,
          alias: opponentAlias,
          championId: ChampionId.tuyetDinh,
          hp: _oppHp,
          armor: _oppArmor,
          ward: 0,
          qi: _oppQi,
          skill1Used: false,
          skill2Used: false,
          isAlive: _oppHp > 0,
        ),
      ],
      currentRoundInfo: PvpRoundInfo(
        roundNo: _roundNo,
        questionId: q.id,
        prompt: q.prompt,
        reasoningPromptVi: q.reasoningPromptVi,
        deadlineAtIso: DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 75))
            .toIso8601String(),
        state: _roundState,
        isSecretRound: _roundNo == 3,
        mySubmission: PvpMySubmissionSnapshot(
          submitted: _submitted,
          gradeStatus: _submitted ? _gradeStatus : null,
          feedbackVi: _submitted ? 'Đã ghi nhận bài làm.' : '',
        ),
        opponentSubmitted: _submitted,
      ),
    );
  }
}
