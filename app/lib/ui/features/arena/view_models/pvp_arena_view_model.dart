import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/game/pvp_models.dart';
import '../../../../domain/models/personal_flow_models.dart';
import '../../../../domain/services/pvp_gateway.dart';

enum PvpUiStage {
  idle,
  queuing,
  inMatch,
  completed,
}

/// ViewModel điều phối Đấu trường giao hữu PvP 1v1 (`/v1/pvp/*`, T061 AC-03).
class PvpArenaViewModel extends ChangeNotifier {
  PvpArenaViewModel({
    required PvpGateway gateway,
    this.enableAutoPolling = true,
  }) : _gateway = gateway;

  final PvpGateway _gateway;
  final bool enableAutoPolling;

  PvpUiStage _stage = PvpUiStage.idle;
  bool _busy = false;
  ChampionId _champion = ChampionId.haNhan;
  String _subjectCode = 'math';
  String _gradeBand = 'Lớp 11';
  String? _statusMessageVi;
  String? _errorVi;
  PvpMatchSnapshot? _snapshot;
  PvpRoundSubmitResponse? _lastSubmit;
  PvpRoundActionResponse? _lastAction;
  String? _lastMatchId;
  Timer? _pollTimer;

  PvpUiStage get stage => _stage;
  bool get isBusy => _busy;
  bool get isDebugFixture => _gateway.isDebugFixture;
  ChampionId get champion => _champion;
  String get subjectCode => _subjectCode;
  String get gradeBand => _gradeBand;
  String? get statusMessageVi => _statusMessageVi;
  String? get errorVi => _errorVi;
  PvpMatchSnapshot? get snapshot => _snapshot;
  PvpRoundSubmitResponse? get lastSubmit => _lastSubmit;
  PvpRoundActionResponse? get lastAction => _lastAction;

  void selectChampion(ChampionId id) {
    _champion = id;
    notifyListeners();
  }

  void configureSubjectAndGrade({
    required String subjectCode,
    required String gradeBand,
  }) {
    _subjectCode = subjectCode;
    _gradeBand = gradeBand;
    notifyListeners();
  }

  Future<void> startMatchmake() async {
    _busy = true;
    _errorVi = null;
    _statusMessageVi = 'Đang kết nối hàng đợi giao hữu...';
    notifyListeners();
    try {
      final PvpMatchmakeResponse res = await _gateway.matchmake(
        championId: _champion.code,
        subjectCode: _subjectCode,
        gradeBand: _gradeBand,
      );
      if (res.isWaiting || res.matchSnapshot == null) {
        _stage = PvpUiStage.queuing;
        _statusMessageVi =
            res.messageVi ?? 'Đang tìm đối thủ cùng môn & khối lớp...';
        _startPollingQueue();
      } else {
        _applyMatchSnapshot(res.matchSnapshot!);
      }
    } on PersonalApiException catch (e) {
      _errorVi = e.messageVi;
      _statusMessageVi = null;
    } catch (_) {
      _errorVi = 'Không kết nối được hàng đợi PvP lúc này.';
      _statusMessageVi = null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> pollOnce() async {
    if (_busy) return;
    _busy = true;
    try {
      if (_stage == PvpUiStage.queuing) {
        final PvpMatchmakeResponse res = await _gateway.matchmake(
          championId: _champion.code,
          subjectCode: _subjectCode,
          gradeBand: _gradeBand,
        );
        if (!res.isWaiting && res.matchSnapshot != null) {
          _applyMatchSnapshot(res.matchSnapshot!);
        }
      } else if (_stage == PvpUiStage.inMatch && _lastMatchId != null) {
        final PvpMatchSnapshot latest = await _gateway.getMatch(_lastMatchId!);
        _applyMatchSnapshot(latest);
      }
    } on PersonalApiException catch (e) {
      _errorVi = e.messageVi;
    } catch (_) {
      // Giữ trạng thái hiện tại khi poll rớt mạng tạm thời.
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> cancelQueue() async {
    _stopPolling();
    _busy = true;
    notifyListeners();
    try {
      await _gateway.cancelMatchmake();
    } catch (_) {
      // Hủy queue best-effort
    } finally {
      _stage = PvpUiStage.idle;
      _statusMessageVi = 'Đã rời hàng đợi ghép trận.';
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> submitAnswer({
    required String answerText,
    required String reasoningText,
  }) async {
    final PvpMatchSnapshot? snap = _snapshot;
    final PvpRoundInfo? round = snap?.currentRoundInfo;
    if (snap == null || round == null) return;
    _busy = true;
    _errorVi = null;
    notifyListeners();
    try {
      final PvpRoundSubmitResponse sub = await _gateway.submitRound(
        matchId: snap.matchId,
        roundNo: round.roundNo,
        answerText: answerText,
        reasoningText: reasoningText,
      );
      _lastSubmit = sub;
      _statusMessageVi = sub.feedbackVi.isNotEmpty
          ? sub.feedbackVi
          : 'Đã nộp bài làm round ${round.roundNo}.';
      final PvpMatchSnapshot latest = await _gateway.getMatch(snap.matchId);
      _applyMatchSnapshot(latest);
    } on PersonalApiException catch (e) {
      _errorVi = e.messageVi;
    } catch (_) {
      _errorVi = 'Không nộp được bài làm lên máy chủ PvP.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> chooseAction(CombatActionType action) async {
    final PvpMatchSnapshot? snap = _snapshot;
    final PvpRoundInfo? round = snap?.currentRoundInfo;
    if (snap == null || round == null) return;
    _busy = true;
    _errorVi = null;
    notifyListeners();
    try {
      final PvpRoundActionResponse act = await _gateway.chooseAction(
        matchId: snap.matchId,
        roundNo: round.roundNo,
        actionType: action.code,
      );
      _lastAction = act;
      _statusMessageVi = 'Đã gửi chiêu (${act.actionType}) — đang đồng bộ kết quả round.';
      final PvpMatchSnapshot latest = await _gateway.getMatch(snap.matchId);
      _applyMatchSnapshot(latest);
    } on PersonalApiException catch (e) {
      _errorVi = e.messageVi;
    } catch (_) {
      _errorVi = 'Không gửi được hành động chiêu lên máy chủ.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void leaveFinishedMatch() {
    _stopPolling();
    _snapshot = null;
    _lastMatchId = null;
    _lastSubmit = null;
    _lastAction = null;
    _errorVi = null;
    _statusMessageVi = null;
    _stage = PvpUiStage.idle;
    notifyListeners();
  }

  void _applyMatchSnapshot(PvpMatchSnapshot snap) {
    _snapshot = snap;
    _lastMatchId = snap.matchId;
    if (snap.isCompleted) {
      _stage = PvpUiStage.completed;
      _stopPolling();
    } else {
      _stage = PvpUiStage.inMatch;
      _startPollingMatch();
    }
  }

  void _startPollingQueue() {
    _stopPolling();
    if (!enableAutoPolling) return;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => pollOnce(),
    );
  }

  void _startPollingMatch() {
    _stopPolling();
    if (!enableAutoPolling) return;
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => pollOnce(),
    );
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
