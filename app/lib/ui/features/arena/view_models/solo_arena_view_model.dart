import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/game/solo_combat_engine.dart';
import '../../../../domain/game/solo_training_question_bank.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';

enum ArenaSection {
  hub,
  setup,
  loading,
  battle,
  summary,
}

enum SoloBattlePhase {
  answering,
  gradedUncertain,
  gradedIncorrect,
  choosingAction,
  roundFeedback,
}

class SoloRoundHistoryItem {
  const SoloRoundHistoryItem({
    required this.roundNo,
    required this.question,
    required this.submittedAnswer,
    required this.submittedReasoning,
    required this.playerGrade,
    required this.resolution,
  });

  final int roundNo;
  final SoloApprovedQuestion question;
  final String submittedAnswer;
  final String submittedReasoning;
  final SoloGradeStatus playerGrade;
  final SoloRoundResolution resolution;
}

/// ViewModel điều phối luồng G1 Đấu trường → Luyện đơn cục bộ (offline-safe, 0 RP).
class SoloArenaViewModel extends ChangeNotifier {
  SoloArenaViewModel({
    int initialSeed = 20261118,
    this.enableRoundTimer = true,
  }) : _seed = initialSeed;

  static const int defaultSecretRoundNo = 3;
  static const List<int> timePresetSeconds = <int>[30, 45, 60, 90];
  static const List<String> concreteMapIds = <String>[
    'courtyard',
    'dawn_peak',
    'night_library',
  ];

  final bool enableRoundTimer;

  ArenaSection _section = ArenaSection.hub;
  SoloBattlePhase _phase = SoloBattlePhase.answering;

  String _selectedSubjectCode = 'math';
  String? _gradeLevel;
  String _selectedMapId = 'courtyard';
  String _resolvedMapId = 'courtyard';
  int _playerLane = 1;
  int _botAttackLane = 1;
  bool _dodgeActiveThisTurn = false;
  int _dodgeCountThisMatch = 0;
  String? _dodgeNoticeVi;
  bool _autoCastSpecial = false;
  bool _isFetchingAiQuestion = false;
  ChampionId _playerChampion = ChampionId.haNhan;
  ChampionId _botChampion = ChampionId.hanBoiPhap;
  BotDifficulty _botDifficulty = BotDifficulty.tieuChuan;
  bool _noTimeLimit = true;
  int _roundTimeLimitSeconds = 60;
  int? _remainingRoundSeconds;
  bool _roundTimedOut = false;
  Timer? _roundTimer;
  int _seed;
  Future<SoloApprovedQuestion?> Function({
    required String subjectCode,
    required String seedQuestionId,
    required int roundNo,
  })? _continuousQuestionProvider;

  bool _reduceMotionOverride = false;
  bool _skipEffects = false;
  bool _soundEnabled = false; // Tắt mặc định theo docs/04-game/02 §2
  bool _simulateAssetFallback = false;

  String? _setupErrorVi;
  int _currentRound = 1;
  List<SoloApprovedQuestion> _deck = <SoloApprovedQuestion>[];
  int _deckCursor = 0;
  SoloApprovedQuestion? _currentQuestion;

  SoloCombatantState _playerState = const SoloCombatantState(
    actorId: 'local_student',
    displayName: 'Bạn',
    championId: ChampionId.haNhan,
    isBot: false,
  );
  SoloCombatantState _botState = const SoloCombatantState(
    actorId: 'training_bot',
    displayName: 'Máy tập',
    championId: ChampionId.hanBoiPhap,
    isBot: true,
  );

  String _lastSubmittedAnswer = '';
  String _lastSubmittedReasoning = '';
  SoloGradingFeedback? _lastGrading;
  bool _showRubricReveal = false;
  SoloRoundResolution? _lastResolution;
  final List<SoloRoundHistoryItem> _history = <SoloRoundHistoryItem>[];
  bool _matchFinished = false;
  String? _winnerActorId;
  String? _finishReason;

  // --- Getters ---
  ArenaSection get section => _section;
  SoloBattlePhase get phase => _phase;
  String get selectedSubjectCode => _selectedSubjectCode;
  ChampionId get playerChampion => _playerChampion;
  ChampionId get botChampion => _botChampion;
  BotDifficulty get botDifficulty => _botDifficulty;
  bool get noTimeLimit => _noTimeLimit;
  int get roundTimeLimitSeconds => _roundTimeLimitSeconds;
  int? get remainingRoundSeconds => _remainingRoundSeconds;
  bool get roundTimedOut => _roundTimedOut;
  int get seed => _seed;

  bool get reduceMotionOverride => _reduceMotionOverride;
  bool get skipEffects => _skipEffects;
  bool get soundEnabled => _soundEnabled;
  bool get simulateAssetFallback => _simulateAssetFallback;

  String? get setupErrorVi => _setupErrorVi;
  int get currentRound => _currentRound;
  bool get isCurrentRoundSecret => _currentRound == defaultSecretRoundNo;
  SoloApprovedQuestion? get currentQuestion => _currentQuestion;
  SoloCombatantState get playerState => _playerState;
  SoloCombatantState get botState => _botState;

  String get lastSubmittedAnswer => _lastSubmittedAnswer;
  String get lastSubmittedReasoning => _lastSubmittedReasoning;
  SoloGradingFeedback? get lastGrading => _lastGrading;
  bool get showRubricReveal => _showRubricReveal;
  SoloRoundResolution? get lastResolution => _lastResolution;
  List<SoloRoundHistoryItem> get history =>
      List<SoloRoundHistoryItem>.unmodifiable(_history);
  bool get matchFinished => _matchFinished;
  String? get winnerActorId => _winnerActorId;
  String? get finishReason => _finishReason;

  bool get hasSelectedSubjectApprovedPool =>
      SoloTrainingQuestionBank.hasApprovedCacheFor(_selectedSubjectCode);

  List<SoloActionAvailability> get actionOptions => evaluateActionAvailability(
        state: _playerState,
        roundNo: _currentRound,
        playerGrade: _lastGrading?.status,
        actionWindowOpen: _phase == SoloBattlePhase.choosingAction,
      );

  // --- Navigation & Setup ---
  String? get gradeLevel => _gradeLevel;
  String get selectedMapId => _selectedMapId;
  String get resolvedMapId => _resolvedMapId;
  int get playerLane => _playerLane;
  int get botAttackLane => _botAttackLane;
  bool get dodgeActiveThisTurn => _dodgeActiveThisTurn;
  int get dodgeCountThisMatch => _dodgeCountThisMatch;
  String? get dodgeNoticeVi => _dodgeNoticeVi;
  bool get autoCastSpecial => _autoCastSpecial;
  bool get isFetchingAiQuestion => _isFetchingAiQuestion;
  bool get hasContinuousQuestionProvider => _continuousQuestionProvider != null;

  void selectMap(String mapId) {
    _selectedMapId = mapId;
    if (concreteMapIds.contains(mapId)) {
      _resolvedMapId = mapId;
    }
    notifyListeners();
  }

  void setGradeLevel(String? gradeLevel) {
    _gradeLevel = gradeLevel;
  }

  void toggleAutoCastSpecial() {
    _autoCastSpecial = !_autoCastSpecial;
    if (_autoCastSpecial && _phase == SoloBattlePhase.choosingAction) {
      final CombatActionType autoPick = _bestAvailableAction();
      chooseAction(autoPick);
      return;
    }
    notifyListeners();
  }

  /// Bên người chơi chủ động lách làn trên sân để né đòn báo trước từ đối thủ.
  void triggerPlayerDodge() {
    if (_section != ArenaSection.battle) return;
    if (_phase == SoloBattlePhase.roundFeedback) return;
    int nextLane = (_playerLane + 1) % 3;
    if (nextLane == _botAttackLane) {
      nextLane = (nextLane + 1) % 3;
    }
    _playerLane = nextLane;
    if (!_dodgeActiveThisTurn) {
      _dodgeActiveThisTurn = true;
      _dodgeCountThisMatch++;
    }
    _dodgeNoticeVi =
        'Lách sang làn ${_playerLane + 1} · Sẵn sàng né đòn đối thủ!';
    notifyListeners();
  }

  void openSoloSetup({StudyProfile? profile}) {
    _setupErrorVi = null;
    if (profile != null) {
      _gradeLevel = profile.gradeLevel;
    }
    if (profile != null && profile.selectedSubjectCodes.isNotEmpty) {
      final String? preferred =
          profile.selectedSubjectCodes.cast<String?>().firstWhere(
                (String? code) =>
                    code != null &&
                    SoloTrainingQuestionBank.hasApprovedCacheFor(code),
                orElse: () => null,
              );
      if (preferred != null) {
        _selectedSubjectCode = preferred;
      }
    }
    _section = ArenaSection.setup;
    notifyListeners();
  }

  void backToHub() {
    _stopRoundTimer();
    _setupErrorVi = null;
    _section = ArenaSection.hub;
    notifyListeners();
  }

  void selectSubject(String code) {
    _selectedSubjectCode = code;
    _setupErrorVi = null;
    notifyListeners();
  }

  void selectPlayerChampion(ChampionId id) {
    _playerChampion = id;
    if (_botChampion == id) {
      _botChampion = switch (id) {
        ChampionId.haNhan => ChampionId.hanBoiPhap,
        ChampionId.tuyetDinh => ChampionId.haNhan,
        ChampionId.hanBoiPhap => ChampionId.tuyetDinh,
      };
    }
    notifyListeners();
  }

  void selectBotChampion(ChampionId id) {
    _botChampion = id;
    notifyListeners();
  }

  void selectDifficulty(BotDifficulty difficulty) {
    _botDifficulty = difficulty;
    notifyListeners();
  }

  void toggleNoTimeLimit() {
    _noTimeLimit = !_noTimeLimit;
    if (_noTimeLimit) {
      _stopRoundTimer();
      _remainingRoundSeconds = null;
    }
    notifyListeners();
  }

  /// Đặt thời gian đếm ngược mỗi lượt (30/45/60/90s hoặc null = Không giới hạn).
  void selectRoundTimeLimit(int? seconds) {
    if (seconds == null || seconds <= 0) {
      _noTimeLimit = true;
      _stopRoundTimer();
      _remainingRoundSeconds = null;
    } else {
      _noTimeLimit = false;
      _roundTimeLimitSeconds = seconds;
    }
    notifyListeners();
  }

  /// Gắn nguồn nạp câu hỏi liên tục (ví dụ gọi AI tạo biến thể từ đề gốc khi có mạng).
  void setContinuousQuestionProvider(
    Future<SoloApprovedQuestion?> Function({
      required String subjectCode,
      required String seedQuestionId,
      required int roundNo,
    })? provider,
  ) {
    _continuousQuestionProvider = provider;
  }

  void setSeed(int nextSeed) {
    _seed = nextSeed <= 0 ? 1 : nextSeed;
    notifyListeners();
  }

  void nextPresetSeed() {
    _seed = ((_seed * 1664525) + 1013904223) & 0x0FFFFFFF;
    if (_seed == 0) _seed = 20261118;
    notifyListeners();
  }

  void toggleReduceMotion() {
    _reduceMotionOverride = !_reduceMotionOverride;
    notifyListeners();
  }

  void toggleSkipEffects() {
    _skipEffects = !_skipEffects;
    notifyListeners();
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
  }

  void toggleSimulateAssetFallback() {
    _simulateAssetFallback = !_simulateAssetFallback;
    notifyListeners();
  }

  // --- Match lifecycle ---
  bool startSoloMatch({
    String? playerName,
    bool showLoadingScreen = false,
  }) {
    if (!SoloTrainingQuestionBank.hasApprovedCacheFor(_selectedSubjectCode)) {
      _setupErrorVi =
          'Môn ${SubjectCatalog.nameFor(_selectedSubjectCode)} chưa có đủ bộ câu hỏi đã duyệt lưu trên máy. '
          'Hãy chọn môn có nhãn Đã sẵn sàng (Toán, Vật lí, Tiếng Anh, Sinh học) để luyện.';
      notifyListeners();
      return false;
    }

    _setupErrorVi = null;
    if (_selectedMapId == 'random') {
      _resolvedMapId = concreteMapIds[_seed.abs() % concreteMapIds.length];
    } else if (concreteMapIds.contains(_selectedMapId)) {
      _resolvedMapId = _selectedMapId;
    } else {
      _resolvedMapId = 'courtyard';
    }
    _deck = SoloTrainingQuestionBank.selectDeterministicDeck(
      subjectCode: _selectedSubjectCode,
      seed: _seed,
      gradeLevel: _gradeLevel,
    );
    _deckCursor = 0;
    _currentRound = 1;
    _currentQuestion = _drawNextQuestion();
    _playerLane = 1;
    _botAttackLane = (_seed + 1) % 3;
    _dodgeActiveThisTurn = false;
    _dodgeCountThisMatch = 0;
    _dodgeNoticeVi = null;

    final String cleanName =
        (playerName != null && playerName.trim().isNotEmpty)
            ? playerName.trim()
            : 'Bạn';
    _playerState = SoloCombatantState(
      actorId: 'local_student',
      displayName: cleanName,
      championId: _playerChampion,
      isBot: false,
    );
    _botState = SoloCombatantState(
      actorId: 'training_bot',
      displayName: 'Máy tập (${_botDifficulty.labelVi})',
      championId: _botChampion,
      isBot: true,
    );

    _lastSubmittedAnswer = '';
    _lastSubmittedReasoning = '';
    _lastGrading = null;
    _showRubricReveal = false;
    _lastResolution = null;
    _history.clear();
    _matchFinished = false;
    _winnerActorId = null;
    _finishReason = null;

    _phase = SoloBattlePhase.answering;
    _section = showLoadingScreen ? ArenaSection.loading : ArenaSection.battle;
    if (!showLoadingScreen) {
      _startRoundTimer();
      _prefetchNextContinuousQuestion();
    } else {
      _stopRoundTimer();
    }
    notifyListeners();
    return true;
  }

  void completeArenaLoading() {
    if (_section != ArenaSection.loading) return;
    _section = ArenaSection.battle;
    _startRoundTimer();
    _prefetchNextContinuousQuestion();
    notifyListeners();
  }

  void cancelArenaLoading() {
    if (_section != ArenaSection.loading) return;
    _stopRoundTimer();
    _section = ArenaSection.setup;
    notifyListeners();
  }

  bool replayWithSameSeed({
    String? playerName,
    bool showLoadingScreen = false,
  }) {
    return startSoloMatch(
      playerName: playerName,
      showLoadingScreen: showLoadingScreen,
    );
  }

  SoloApprovedQuestion _drawNextQuestion() {
    if (_deck.isEmpty) {
      _deck = SoloTrainingQuestionBank.selectDeterministicDeck(
        subjectCode: _selectedSubjectCode,
        seed: _seed,
        gradeLevel: _gradeLevel,
      );
      if (_deck.isEmpty) {
        _deck = SoloTrainingQuestionBank.selectDeterministicDeck(
          subjectCode: 'math',
          seed: _seed,
          gradeLevel: _gradeLevel,
        );
      }
    }
    if (_deckCursor >= _deck.length) {
      final List<SoloApprovedQuestion> fresh =
          SoloTrainingQuestionBank.selectDeterministicDeck(
        subjectCode: _selectedSubjectCode,
        seed: _seed + _deckCursor + 17,
        gradeLevel: _gradeLevel,
      );
      _deck.addAll(fresh.isNotEmpty
          ? fresh
          : SoloTrainingQuestionBank.selectDeterministicDeck(
              subjectCode: 'math',
              seed: _seed + _deckCursor + 17,
              gradeLevel: _gradeLevel,
            ));
    }
    SoloApprovedQuestion q = _deck[_deckCursor];
    if (_deck.length > 1 &&
        _currentQuestion?.id == q.id &&
        _deckCursor + 1 < _deck.length) {
      _deckCursor++;
      q = _deck[_deckCursor];
    }
    _deckCursor++;
    return q;
  }

  void _prefetchNextContinuousQuestion() {
    final provider = _continuousQuestionProvider;
    final SoloApprovedQuestion? current = _currentQuestion;
    if (provider == null || current == null) return;
    provider(
      subjectCode: _selectedSubjectCode,
      seedQuestionId: current.id,
      roundNo: _currentRound + 1,
    ).then((SoloApprovedQuestion? generated) {
      if (generated == null) return;
      final bool duplicate =
          _deck.any((SoloApprovedQuestion e) => e.id == generated.id);
      if (!duplicate) {
        _deck.insert(_deckCursor.clamp(0, _deck.length), generated);
        notifyListeners();
      }
    }).catchError((Object _) {});
  }

  void _startRoundTimer() {
    _stopRoundTimer();
    _roundTimedOut = false;
    if (_noTimeLimit) {
      _remainingRoundSeconds = null;
      return;
    }
    _remainingRoundSeconds = _roundTimeLimitSeconds;
    if (!enableRoundTimer) return;
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_section != ArenaSection.battle ||
          _phase != SoloBattlePhase.answering) {
        _stopRoundTimer();
        return;
      }
      final int next = (_remainingRoundSeconds ?? 0) - 1;
      if (next <= 0) {
        triggerRoundTimeout();
      } else {
        _remainingRoundSeconds = next;
        notifyListeners();
      }
    });
  }

  void _stopRoundTimer() {
    _roundTimer?.cancel();
    _roundTimer = null;
  }

  /// Khi hết giờ của round: chốt trạng thái uncertain (không trừ HP/uy tín oan) để trận đấu đi tiếp liên tục.
  void triggerRoundTimeout() {
    if (_phase != SoloBattlePhase.answering) return;
    _stopRoundTimer();
    _remainingRoundSeconds = 0;
    _roundTimedOut = true;
    _lastSubmittedAnswer = '';
    _lastSubmittedReasoning = '';
    _lastGrading = const SoloGradingFeedback(
      status: SoloGradeStatus.uncertain,
      feedbackVi:
          'Hết thời gian lượt này! Bạn không bị phạt HP và có thể chuyển ngay sang câu tiếp theo.',
      canRetry: false,
      canSwapQuestion: true,
      canRevealRubric: false,
    );
    _phase = SoloBattlePhase.gradedUncertain;
    notifyListeners();
  }

  /// Chủ động kéo 1 câu hỏi AI mới theo hồ sơ/môn hiện tại để chơi ngay.
  Future<bool> fetchAiQuestionNow() async {
    final provider = _continuousQuestionProvider;
    final SoloApprovedQuestion? current = _currentQuestion;
    if (provider == null || current == null || _isFetchingAiQuestion) {
      return false;
    }
    _isFetchingAiQuestion = true;
    notifyListeners();
    try {
      final SoloApprovedQuestion? generated = await provider(
        subjectCode: _selectedSubjectCode,
        seedQuestionId: current.id,
        roundNo: _currentRound,
      );
      if (generated == null) return false;
      final bool duplicate =
          _deck.any((SoloApprovedQuestion e) => e.id == generated.id);
      if (!duplicate) {
        _deck.insert(_deckCursor.clamp(0, _deck.length), generated);
      }
      if (_phase == SoloBattlePhase.answering) {
        _currentQuestion = generated;
        _lastSubmittedAnswer = '';
        _lastSubmittedReasoning = '';
        _lastGrading = null;
        _showRubricReveal = false;
        _startRoundTimer();
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isFetchingAiQuestion = false;
      notifyListeners();
    }
  }

  CombatActionType _bestAvailableAction() {
    final List<SoloActionAvailability> opts = evaluateActionAvailability(
      state: _playerState,
      roundNo: _currentRound,
      playerGrade: SoloGradeStatus.correct,
      actionWindowOpen: true,
    );
    for (final CombatActionType preferred in const <CombatActionType>[
      CombatActionType.skill2,
      CombatActionType.skill1,
      CombatActionType.basic,
    ]) {
      final bool ok = opts.any(
        (SoloActionAvailability a) => a.actionType == preferred && a.enabled,
      );
      if (ok) return preferred;
    }
    return CombatActionType.basic;
  }

  /// Chấm bài làm 3 trạng thái (`correct | incorrect | uncertain`).
  SoloGradingFeedback submitAnswer({
    required String answerText,
    required String reasoningText,
  }) {
    final SoloApprovedQuestion q = _currentQuestion!;
    _lastSubmittedAnswer = answerText.trim();
    _lastSubmittedReasoning = reasoningText.trim();

    final SoloGradingFeedback grading = gradeSoloTrainingSubmission(
      question: q,
      answerText: answerText,
      reasoningText: reasoningText,
    );
    _lastGrading = grading;
    _showRubricReveal = false;

    switch (grading.status) {
      case SoloGradeStatus.correct:
        _stopRoundTimer();
        if (_autoCastSpecial) {
          _phase = SoloBattlePhase.choosingAction;
          _settleCurrentRound(
            playerGrade: SoloGradeStatus.correct,
            playerAction: _bestAvailableAction(),
          );
          return grading;
        }
        _phase = SoloBattlePhase.choosingAction;
      case SoloGradeStatus.uncertain:
        _stopRoundTimer();
        _phase = SoloBattlePhase.gradedUncertain;
      case SoloGradeStatus.incorrect:
        _phase = SoloBattlePhase.gradedIncorrect;
    }
    notifyListeners();
    return grading;
  }

  /// Cho phép sửa chữ trình bày khi kết quả là `uncertain` hoặc `incorrect`.
  void editSubmissionAgain() {
    if (_phase != SoloBattlePhase.gradedUncertain &&
        _phase != SoloBattlePhase.gradedIncorrect) {
      return;
    }
    if (_roundTimedOut) {
      swapQuestionOnUncertain();
      return;
    }
    _phase = SoloBattlePhase.answering;
    _showRubricReveal = false;
    _startRoundTimer();
    notifyListeners();
  }

  /// Khi `uncertain` hoặc hết giờ, chuyển sang câu mới liên tục mà không bị phạt HP/lượt.
  void swapQuestionOnUncertain() {
    if (_phase != SoloBattlePhase.gradedUncertain) return;
    _currentQuestion = _drawNextQuestion();
    _lastSubmittedAnswer = '';
    _lastSubmittedReasoning = '';
    _lastGrading = null;
    _showRubricReveal = false;
    _phase = SoloBattlePhase.answering;
    _startRoundTimer();
    _prefetchNextContinuousQuestion();
    notifyListeners();
  }

  /// Chỉ cho xem cách chấm SAU KHI đã nộp bài (không lộ đáp án trước nộp).
  void toggleRubricReveal() {
    if (_phase == SoloBattlePhase.answering) return;
    if (_lastGrading == null || !_lastGrading!.canRevealRubric) return;
    _showRubricReveal = !_showRubricReveal;
    notifyListeners();
  }

  /// Chọn Đánh thường / Chiêu 1 / Chiêu 2 sau khi trả lời `correct`.
  SoloRoundResolution? chooseAction(CombatActionType action) {
    if (_phase != SoloBattlePhase.choosingAction) return null;
    final SoloActionAvailability picked = actionOptions.firstWhere(
      (SoloActionAvailability a) => a.actionType == action,
    );
    if (!picked.enabled) return null;
    return _settleCurrentRound(
      playerGrade: SoloGradeStatus.correct,
      playerAction: action,
    );
  }

  /// Tiếp tục lượt sau khi trả lời `incorrect` (không kích hoạt chiêu, không phạt uy tín/RP).
  SoloRoundResolution? continueTurnAfterIncorrect() {
    if (_phase != SoloBattlePhase.gradedIncorrect) return null;
    return _settleCurrentRound(
      playerGrade: SoloGradeStatus.incorrect,
      playerAction: CombatActionType.basic,
    );
  }

  SoloRoundResolution _settleCurrentRound({
    required SoloGradeStatus playerGrade,
    required CombatActionType playerAction,
  }) {
    final DeterministicTrainingBot bot = DeterministicTrainingBot(
      seed: _seed,
      difficulty: _botDifficulty,
    );
    final BotRoundDecision botDecision = bot.decideRound(
      roundNo: _currentRound,
      botState: _botState,
    );

    final SoloRoundResolution res = settleSoloRound(
      roundNo: _currentRound,
      playerState: _playerState,
      botState: _botState,
      playerGrade: playerGrade,
      playerActionRequested: playerAction,
      botDecision: botDecision,
      isSecretRound: isCurrentRoundSecret,
    );

    _playerState = res.nextPlayerState;
    _botState = res.nextBotState;
    _matchFinished = res.settle.matchFinished;
    _winnerActorId = res.settle.winnerUserId;
    _finishReason = res.settle.finishReason;
    final int rawDamageToPlayer = res.settle.playerADelta.damageTaken;
    if (_dodgeActiveThisTurn &&
        _playerLane != _botAttackLane &&
        rawDamageToPlayer > 0) {
      final int mitigated =
          (rawDamageToPlayer * 0.65).round().clamp(1, rawDamageToPlayer);
      final int restoredHp = (_playerState.hp + mitigated).clamp(0, maxHp);
      _playerState = _playerState.copyWith(hp: restoredHp);
      _dodgeNoticeVi =
          'Né thành công ở làn ${_playerLane + 1}! Giảm $mitigated sát thương đòn đối thủ.';
      if (_matchFinished && _playerState.isAlive && _botState.isAlive) {
        _matchFinished = false;
        _winnerActorId = null;
        _finishReason = null;
      }
    } else if (_dodgeActiveThisTurn) {
      _dodgeNoticeVi = 'Đã giữ thế né ở làn ${_playerLane + 1}.';
    } else {
      _dodgeNoticeVi = null;
    }
    _dodgeActiveThisTurn = false;
    _lastResolution = res;

    if (_currentQuestion != null) {
      _history.add(
        SoloRoundHistoryItem(
          roundNo: _currentRound,
          question: _currentQuestion!,
          submittedAnswer: _lastSubmittedAnswer,
          submittedReasoning: _lastSubmittedReasoning,
          playerGrade: playerGrade,
          resolution: res,
        ),
      );
    }

    _phase = SoloBattlePhase.roundFeedback;
    notifyListeners();
    return res;
  }

  void advanceAfterFeedback() {
    if (_phase != SoloBattlePhase.roundFeedback) return;
    if (_matchFinished || _currentRound >= maxCombatRounds) {
      _section = ArenaSection.summary;
      notifyListeners();
      return;
    }
    _currentRound++;
    _botAttackLane = (_seed + _currentRound) % 3;
    _dodgeActiveThisTurn = false;
    _dodgeNoticeVi = null;
    _currentQuestion = _drawNextQuestion();
    _lastSubmittedAnswer = '';
    _lastSubmittedReasoning = '';
    _lastGrading = null;
    _showRubricReveal = false;
    _lastResolution = null;
    _phase = SoloBattlePhase.answering;
    _startRoundTimer();
    _prefetchNextContinuousQuestion();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopRoundTimer();
    super.dispose();
  }

  String summaryOutcomeTitleVi() {
    if (_winnerActorId == _playerState.actorId) {
      return 'Bạn thắng lượt luyện';
    }
    if (_winnerActorId == _botState.actorId) {
      return 'Máy tập thắng lượt luyện';
    }
    return 'Hòa lượt luyện';
  }

  String summaryFinishReasonVi() {
    return switch (_finishReason) {
      'ko' => 'Hạ gục (HP đối thủ về 0)',
      'double_ko' => 'Đồng thời hạ gục (Cả hai về 0 HP → Hòa)',
      'hp_tiebreak' => 'Hết 6 round · Phân định theo HP còn lại',
      'armor_tiebreak' =>
        'Hết 6 round · HP bằng nhau, phân định theo Giáp còn lại',
      'draw_tiebreak' => 'Hết 6 round · HP và Giáp bằng nhau → Hòa',
      _ => 'Kết thúc lượt luyện cục bộ',
    };
  }
}
