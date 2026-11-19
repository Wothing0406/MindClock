import '../game/pvp_models.dart';

/// Gateway giao tiếp đấu trường PvP 1v1 giao hữu (`/v1/pvp/*`, T061 AC-03).
abstract interface class PvpGateway {
  bool get isDebugFixture;

  Future<PvpMatchmakeResponse> matchmake({
    required String championId,
    required String subjectCode,
    required String gradeBand,
    String curriculum = 'gdpt_2018',
  });

  Future<void> cancelMatchmake();

  Future<PvpMatchSnapshot> getMatch(String matchId);

  Future<List<PvpMatchEvent>> getMatchEvents(
    String matchId, {
    int afterSequence = 0,
  });

  Future<PvpRoundSubmitResponse> submitRound({
    required String matchId,
    required int roundNo,
    required String answerText,
    required String reasoningText,
  });

  Future<PvpRoundActionResponse> chooseAction({
    required String matchId,
    required int roundNo,
    required String actionType,
  });
}
