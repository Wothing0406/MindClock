import 'package:flutter/foundation.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/game/solo_combat_engine.dart';
import '../../../../domain/game/solo_training_question_bank.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';

enum ArenaSection {
  hub,
  setup,
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
  }) : _seed = initialSeed;

  static const int defaultSecretRoundNo = 3;

  ArenaSection _section = ArenaSection.hub;
  SoloBattlePhase _phase = SoloBattlePhase.answering;

  String _selectedSubjectCode = 'math';
  ChampionId _playerChampion = ChampionId.haNhan;
  ChampionId _botChampion = ChampionId.hanBoiPhap;
  BotDifficulty _botDifficulty = BotDifficulty.tieuChuan;
  bool _noTimeLimit = true;
  int _seed;

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
  void openSoloSetup({StudyProfile? profile}) {
    _setupErrorVi = null;
    if (profile != null && profile.selectedSubjectCodes.isNotEmpty) {
      final String? preferred = profile.selectedSubjectCodes.cast<String?>().firstWhere(
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
    notifyListeners();
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
  bool startSoloMatch({String? playerName}) {
    if (!SoloTrainingQuestionBank.hasApprovedCacheFor(_selectedSubjectCode)) {
      _setupErrorVi =
          'Môn ${SubjectCatalog.nameFor(_selectedSubjectCode)} chưa có đủ bộ câu hỏi đã duyệt lưu trên máy. '
          'Hãy chọn môn có nhãn Đã sẵn sàng (Toán, Vật lí, Tiếng Anh, Sinh học) để luyện.';
      notifyListeners();
      return false;
    }

    _setupErrorVi = null;
    _deck = SoloTrainingQuestionBank.selectDeterministicDeck(
      subjectCode: _selectedSubjectCode,
      seed: _seed,
    );
    _deckCursor = 0;
    _currentRound = 1;
    _currentQuestion = _drawNextQuestion();

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
    _section = ArenaSection.battle;
    notifyListeners();
    return true;
  }

  bool replayWithSameSeed({String? playerName}) {
    return startSoloMatch(playerName: playerName);
  }

  SoloApprovedQuestion _drawNextQuestion() {
    if (_deck.isEmpty) {
      _deck = SoloTrainingQuestionBank.selectDeterministicDeck(
        subjectCode: 'math',
        seed: _seed,
      );
    }
    final SoloApprovedQuestion q = _deck[_deckCursor % _deck.length];
    _deckCursor++;
    return q;
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
        _phase = SoloBattlePhase.choosingAction;
      case SoloGradeStatus.uncertain:
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
    _phase = SoloBattlePhase.answering;
    _showRubricReveal = false;
    notifyListeners();
  }

  /// Khi `uncertain`, người học có thể đổi sang câu approved khác mà không bị phạt HP/lượt.
  void swapQuestionOnUncertain() {
    if (_phase != SoloBattlePhase.gradedUncertain) return;
    _currentQuestion = _drawNextQuestion();
    _lastSubmittedAnswer = '';
    _lastSubmittedReasoning = '';
    _lastGrading = null;
    _showRubricReveal = false;
    _phase = SoloBattlePhase.answering;
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
    _lastResolution = res;
    _matchFinished = res.settle.matchFinished;
    _winnerActorId = res.settle.winnerUserId;
    _finishReason = res.settle.finishReason;

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
    _currentQuestion = _drawNextQuestion();
    _lastSubmittedAnswer = '';
    _lastSubmittedReasoning = '';
    _lastGrading = null;
    _showRubricReveal = false;
    _lastResolution = null;
    _phase = SoloBattlePhase.answering;
    notifyListeners();
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
      'armor_tiebreak' => 'Hết 6 round · HP bằng nhau, phân định theo Giáp còn lại',
      'draw_tiebreak' => 'Hết 6 round · HP và Giáp bằng nhau → Hòa',
      _ => 'Kết thúc lượt luyện cục bộ',
    };
  }
}
