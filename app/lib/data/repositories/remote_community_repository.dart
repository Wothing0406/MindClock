import '../../domain/models/community_models.dart';
import '../../domain/models/commitment_group_models.dart';
import '../../domain/services/community_repository.dart';
import '../services/local_id_generator.dart';
import '../services/personal_api_client.dart';

class RemoteCommunityRepository implements CommunityRepository {
  const RemoteCommunityRepository({required PersonalApiClient apiClient})
      : _apiClient = apiClient;

  final PersonalApiClient _apiClient;

  @override
  bool get isDebugFixture => false;

  @override
  Future<PublicStudentProfile> fetchPublicProfile(String userId) async {
    final Map<String, dynamic> data =
        await _apiClient.getJson('/profiles/$userId');
    return PublicStudentProfile.fromJson(data);
  }

  @override
  Future<List<PublicStudentProfile>> searchUsers({
    String query = '',
    String? gradeLevel,
    String? subjectCode,
  }) async {
    final Map<String, String> params = <String, String>{};
    if (query.trim().isNotEmpty) params['q'] = query.trim();
    if (gradeLevel != null && gradeLevel.trim().isNotEmpty) {
      params['gradeLevel'] = gradeLevel.trim();
    }
    if (subjectCode != null && subjectCode.trim().isNotEmpty) {
      params['subjectCode'] = subjectCode.trim();
    }
    final Map<String, dynamic> data = await _apiClient.getJson(
      '/users/search',
      queryParameters: params.isEmpty ? null : params,
    );
    final List<dynamic> raw = data['users'] as List<dynamic>? ?? <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PublicStudentProfile.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> sendFriendRequest(
    String receiverUserId, {
    String messageVi = '',
  }) async {
    await _apiClient.postJson(
      '/friends/request',
      body: <String, dynamic>{
        'receiverUserId': receiverUserId,
        'messageVi': messageVi,
      },
      idempotencyKey: 'fr_req_${LocalIdGenerator.nextUuidV4()}',
    );
  }

  @override
  Future<({List<FriendRequestItem> incoming, List<FriendRequestItem> outgoing})>
      fetchFriendRequests() async {
    final Map<String, dynamic> data =
        await _apiClient.getJson('/friends/requests');
    final List<FriendRequestItem> incoming =
        (data['incoming'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(FriendRequestItem.fromJson)
            .toList(growable: false);
    final List<FriendRequestItem> outgoing =
        (data['outgoing'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(FriendRequestItem.fromJson)
            .toList(growable: false);
    return (incoming: incoming, outgoing: outgoing);
  }

  @override
  Future<void> respondFriendRequest(String requestId, String decision) async {
    await _apiClient.postJson(
      '/friends/requests/$requestId/respond',
      body: <String, dynamic>{'decision': decision},
      idempotencyKey: 'fr_resp_${LocalIdGenerator.nextUuidV4()}',
    );
  }

  @override
  Future<List<PublicStudentProfile>> fetchFriends() async {
    final Map<String, dynamic> data = await _apiClient.getJson('/friends');
    final List<dynamic> raw = data['friends'] as List<dynamic>? ?? <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PublicStudentProfile.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> blockUser(String blockedUserId, {String reason = ''}) async {
    await _apiClient.postJson(
      '/users/block',
      body: <String, dynamic>{
        'blockedUserId': blockedUserId,
        'reason': reason,
      },
      idempotencyKey: 'blk_${LocalIdGenerator.nextUuidV4()}',
    );
  }

  @override
  Future<List<PublicStudyRoomSummary>> listPublicRooms({
    String? gradeLevel,
    String? subjectCode,
  }) async {
    final Map<String, String> params = <String, String>{};
    if (gradeLevel != null && gradeLevel.trim().isNotEmpty) {
      params['gradeLevel'] = gradeLevel.trim();
    }
    if (subjectCode != null && subjectCode.trim().isNotEmpty) {
      params['subjectCode'] = subjectCode.trim();
    }
    final Map<String, dynamic> data = await _apiClient.getJson(
      '/study-rooms/public',
      queryParameters: params.isEmpty ? null : params,
    );
    final List<dynamic> raw = data['rooms'] as List<dynamic>? ?? <dynamic>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PublicStudyRoomSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<StudyRoomDetail> createRoom({
    required String title,
    required String subjectCode,
    required String gradeLevel,
    String targetLevel = 'basic',
    String visibility = 'public',
    int maxMembers = 4,
    bool aiCompanionEnabled = true,
  }) async {
    final Map<String, dynamic> data = await _apiClient.postJson(
      '/study-rooms',
      body: <String, dynamic>{
        'title': title,
        'subjectCode': subjectCode,
        'gradeLevel': gradeLevel,
        'targetLevel': targetLevel,
        'visibility': visibility,
        'maxMembers': maxMembers,
        'aiCompanionEnabled': aiCompanionEnabled,
      },
      idempotencyKey: 'room_new_${LocalIdGenerator.nextUuidV4()}',
    );
    return StudyRoomDetail.fromJson(data);
  }

  @override
  Future<StudyRoomDetail> joinRoom(
    String roomId, {
    String? roomCode,
    bool micEnabled = false,
    bool camEnabled = false,
    String statusNote = 'Đang tập trung',
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'micEnabled': micEnabled,
      'camEnabled': camEnabled,
      'statusNote': statusNote,
    };
    if (roomCode != null && roomCode.trim().isNotEmpty) {
      body['roomCode'] = roomCode.trim();
    }
    final Map<String, dynamic> data = await _apiClient.postJson(
      '/study-rooms/$roomId/join',
      body: body,
      idempotencyKey: 'room_join_${LocalIdGenerator.nextUuidV4()}',
    );
    return StudyRoomDetail.fromJson(data);
  }

  @override
  Future<StudyRoomDetail> updateRoomMedia(
    String roomId, {
    bool? micEnabled,
    bool? camEnabled,
    bool? aiCompanionEnabled,
    String? statusNote,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (micEnabled != null) body['micEnabled'] = micEnabled;
    if (camEnabled != null) body['camEnabled'] = camEnabled;
    if (aiCompanionEnabled != null) {
      body['aiCompanionEnabled'] = aiCompanionEnabled;
    }
    if (statusNote != null) body['statusNote'] = statusNote;
    final Map<String, dynamic> data = await _apiClient.patchJson(
      '/study-rooms/$roomId/media',
      body: body,
      idempotencyKey: 'room_media_${LocalIdGenerator.nextUuidV4()}',
    );
    return StudyRoomDetail.fromJson(data);
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    await _apiClient.postJson(
      '/study-rooms/$roomId/leave',
      body: const <String, dynamic>{},
      idempotencyKey: 'room_leave_${LocalIdGenerator.nextUuidV4()}',
    );
  }

  @override
  Future<StudyRoomDetail> removeRoomMember(
    String roomId,
    String memberUserId,
  ) async {
    final Map<String, dynamic> data = await _apiClient.deleteJson(
      '/study-rooms/$roomId/members/$memberUserId',
      idempotencyKey: 'room_remove_${LocalIdGenerator.nextUuidV4()}',
    );
    return StudyRoomDetail.fromJson(data);
  }

  @override
  Future<void> deleteRoom(String roomId) =>
      _apiClient.deleteNoContent('/study-rooms/$roomId');

  @override
  Future<StudyRoomDetail> fetchRoom(String roomId) async =>
      StudyRoomDetail.fromJson(
          await _apiClient.getJson('/study-rooms/$roomId'));

  @override
  Future<StudyRoomDetail> updateRoomSettings(
    String roomId, {
    String? title,
    int? maxMembers,
    String? visibility,
    bool? aiCompanionEnabled,
  }) async =>
      StudyRoomDetail.fromJson(await _apiClient.patchJson(
        '/study-rooms/$roomId/settings',
        body: {
          if (title != null) 'title': title.trim(),
          if (maxMembers != null) 'maxMembers': maxMembers,
          if (visibility != null) 'visibility': visibility,
          if (aiCompanionEnabled != null)
            'aiCompanionEnabled': aiCompanionEnabled,
        },
      ));

  @override
  Future<StudyAiMatchResult> aiMatchGroups({
    String? subjectCode,
    String? gradeLevel,
    String? targetLevel,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (subjectCode != null && subjectCode.trim().isNotEmpty) {
      body['subjectCode'] = subjectCode.trim();
    }
    if (gradeLevel != null && gradeLevel.trim().isNotEmpty) {
      body['gradeLevel'] = gradeLevel.trim();
    }
    if (targetLevel != null && targetLevel.trim().isNotEmpty) {
      body['targetLevel'] = targetLevel.trim();
    }
    final Map<String, dynamic> data = await _apiClient.postJson(
      '/study-rooms/ai-match',
      body: body,
      idempotencyKey: 'ai_match_${LocalIdGenerator.nextUuidV4()}',
    );
    return StudyAiMatchResult.fromJson(data);
  }

  @override
  Future<CommitmentGroupHub> fetchCommitmentGroupHub() async =>
      CommitmentGroupHub.fromJson(
          await _apiClient.getJson('/commitment-groups/me'));

  @override
  Future<CommitmentGroupDetail> createCommitmentGroup({
    required String name,
    String petName = 'Mầm',
  }) async =>
      CommitmentGroupDetail.fromJson(await _apiClient.postJson(
        '/commitment-groups',
        body: <String, dynamic>{'name': name, 'petName': petName},
        idempotencyKey: 'commitment_new_${LocalIdGenerator.nextUuidV4()}',
      ));

  @override
  Future<void> inviteCommitmentFriend(
      String groupId, String recipientUserId) async {
    await _apiClient.postJson('/commitment-groups/$groupId/invites',
        body: <String, dynamic>{'recipientUserId': recipientUserId},
        idempotencyKey: 'commitment_invite_${LocalIdGenerator.nextUuidV4()}');
  }

  @override
  Future<void> respondCommitmentInvite(String inviteId, String decision) async {
    await _apiClient.postJson('/commitment-group-invites/$inviteId/respond',
        body: <String, dynamic>{'decision': decision},
        idempotencyKey:
            'commitment_invite_reply_${LocalIdGenerator.nextUuidV4()}');
  }

  @override
  Future<void> requestCommitmentJoin(String groupCode) async {
    await _apiClient.postJson('/commitment-group-join-requests',
        body: <String, dynamic>{'groupCode': groupCode.trim().toUpperCase()},
        idempotencyKey: 'commitment_request_${LocalIdGenerator.nextUuidV4()}');
  }

  @override
  Future<CommitmentGroupDetail> respondCommitmentJoinRequest(
          String groupId, String requestId, String decision) async =>
      CommitmentGroupDetail.fromJson(await _apiClient.postJson(
        '/commitment-groups/$groupId/join-requests/$requestId/respond',
        body: <String, dynamic>{'decision': decision},
        idempotencyKey: 'commitment_approve_${LocalIdGenerator.nextUuidV4()}',
      ));

  @override
  Future<CommitmentGroupDetail> removeCommitmentMember(
          String groupId, String memberUserId) async =>
      CommitmentGroupDetail.fromJson(await _apiClient.deleteJson(
        '/commitment-groups/$groupId/members/$memberUserId',
        idempotencyKey: 'commitment_remove_${LocalIdGenerator.nextUuidV4()}',
      ));

  @override
  Future<void> leaveCommitmentGroup(String groupId) async {
    await _apiClient.postJson('/commitment-groups/$groupId/leave',
        body: const <String, dynamic>{},
        idempotencyKey: 'commitment_leave_${LocalIdGenerator.nextUuidV4()}');
  }

  @override
  Future<void> deleteCommitmentGroup(String groupId) =>
      _apiClient.deleteNoContent('/commitment-groups/$groupId');

  @override
  Future<CommitmentGroupHub> setPrimaryCommitmentGroup(String groupId) async =>
      CommitmentGroupHub.fromJson(await _apiClient.postJson(
        '/commitment-groups/$groupId/primary',
        body: const <String, dynamic>{},
        idempotencyKey: 'commitment_primary_${LocalIdGenerator.nextUuidV4()}',
      ));

  @override
  Future<CommitmentGroupDetail> reportCommitmentBusyToday(
    String groupId, {
    String reason = 'exam',
  }) async =>
      CommitmentGroupDetail.fromJson(await _apiClient.postJson(
        '/commitment-groups/$groupId/busy-today',
        body: <String, dynamic>{'reason': reason},
        idempotencyKey: 'commitment_busy_${LocalIdGenerator.nextUuidV4()}',
      ));
}
