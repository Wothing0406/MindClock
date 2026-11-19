import '../../domain/game/pvp_models.dart';
import '../../domain/services/pvp_gateway.dart';
import '../services/local_id_generator.dart';
import '../services/personal_api_client.dart';

/// Gateway PvP 1v1 thật gọi backend `/v1/pvp/*` (`T061 AC-03`).
class RemotePvpGateway implements PvpGateway {
  const RemotePvpGateway({required PersonalApiClient apiClient})
      : _apiClient = apiClient;

  final PersonalApiClient _apiClient;

  @override
  bool get isDebugFixture => false;

  @override
  Future<PvpMatchmakeResponse> matchmake({
    required String championId,
    required String subjectCode,
    required String gradeBand,
    String curriculum = 'gdpt_2018',
  }) async {
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/pvp/matchmake',
      idempotencyKey: LocalIdGenerator.nextUuidV4(),
      body: <String, dynamic>{
        'championId': championId,
        'subjectCode': subjectCode,
        'gradeBand': gradeBand,
        'curriculum': curriculum,
      },
    );
    return PvpMatchmakeResponse.fromJson(json);
  }

  @override
  Future<void> cancelMatchmake() async {
    await _apiClient.postJson(
      '/pvp/matchmake/cancel',
      idempotencyKey: LocalIdGenerator.nextUuidV4(),
      body: const <String, dynamic>{},
    );
  }

  @override
  Future<PvpMatchSnapshot> getMatch(String matchId) async {
    final Map<String, dynamic> json =
        await _apiClient.getJson('/pvp/matches/$matchId');
    return PvpMatchSnapshot.fromJson(json);
  }

  @override
  Future<List<PvpMatchEvent>> getMatchEvents(
    String matchId, {
    int afterSequence = 0,
  }) async {
    final Map<String, dynamic> json = await _apiClient.getJson(
      '/pvp/matches/$matchId/events',
      queryParameters: <String, String>{
        'after_sequence': afterSequence.toString(),
      },
    );
    final List<dynamic> items = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PvpMatchEvent.fromJson)
        .toList(growable: false);
  }

  @override
  Future<PvpRoundSubmitResponse> submitRound({
    required String matchId,
    required int roundNo,
    required String answerText,
    required String reasoningText,
  }) async {
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/pvp/matches/$matchId/rounds/$roundNo/submit',
      idempotencyKey: LocalIdGenerator.nextUuidV4(),
      body: <String, dynamic>{
        'answerText': answerText,
        'reasoningText': reasoningText,
      },
    );
    return PvpRoundSubmitResponse.fromJson(json);
  }

  @override
  Future<PvpRoundActionResponse> chooseAction({
    required String matchId,
    required int roundNo,
    required String actionType,
  }) async {
    final Map<String, dynamic> json = await _apiClient.postJson(
      '/pvp/matches/$matchId/rounds/$roundNo/action',
      idempotencyKey: LocalIdGenerator.nextUuidV4(),
      body: <String, dynamic>{
        'actionType': actionType,
      },
    );
    return PvpRoundActionResponse.fromJson(json);
  }
}
