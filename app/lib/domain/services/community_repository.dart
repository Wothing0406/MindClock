import '../models/community_models.dart';

/// Hợp đồng tầng Repository cho Hồ sơ công khai, Kết bạn, Phòng học công khai & AI ghép nhóm (T058).
abstract interface class CommunityRepository {
  bool get isDebugFixture;

  Future<PublicStudentProfile> fetchPublicProfile(String userId);

  Future<List<PublicStudentProfile>> searchUsers({
    String query = '',
    String? gradeLevel,
    String? subjectCode,
  });

  Future<void> sendFriendRequest(
    String receiverUserId, {
    String messageVi = '',
  });

  Future<({List<FriendRequestItem> incoming, List<FriendRequestItem> outgoing})>
      fetchFriendRequests();

  Future<void> respondFriendRequest(String requestId, String decision);

  Future<List<PublicStudentProfile>> fetchFriends();

  Future<void> blockUser(String blockedUserId, {String reason = ''});

  Future<List<PublicStudyRoomSummary>> listPublicRooms({
    String? gradeLevel,
    String? subjectCode,
  });

  Future<StudyRoomDetail> createRoom({
    required String title,
    required String subjectCode,
    required String gradeLevel,
    String targetLevel = 'basic',
    String visibility = 'public',
    int maxMembers = 4,
    bool aiCompanionEnabled = true,
  });

  Future<StudyRoomDetail> joinRoom(
    String roomId, {
    String? roomCode,
    bool micEnabled = false,
    bool camEnabled = false,
    String statusNote = 'Đang tập trung',
  });

  Future<StudyRoomDetail> updateRoomMedia(
    String roomId, {
    bool? micEnabled,
    bool? camEnabled,
    bool? aiCompanionEnabled,
    String? statusNote,
  });

  Future<void> leaveRoom(String roomId);

  Future<StudyRoomDetail> fetchRoom(String roomId);

  Future<StudyRoomDetail> updateRoomSettings(
    String roomId, {
    String? title,
    int? maxMembers,
    String? visibility,
    bool? aiCompanionEnabled,
  });

  Future<StudyAiMatchResult> aiMatchGroups({
    String? subjectCode,
    String? gradeLevel,
    String? targetLevel,
  });
}
