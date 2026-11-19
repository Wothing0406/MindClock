import '../../domain/models/community_models.dart';
import '../../domain/services/community_repository.dart';

/// Fixture cục bộ dùng cho chế độ test/offline demo của Gói B (có nhãn rõ ràng).
class DebugFixtureCommunityRepository implements CommunityRepository {
  DebugFixtureCommunityRepository() {
    _peers = <PublicStudentProfile>[
      const PublicStudentProfile(
        userId: 'peer_minh_anh',
        alias: 'Minh Anh 11A1',
        avatarId: 'avatar_book',
        gradeLevel: 'Lớp 11',
        selectedSubjects: <String>['math', 'physics', 'english'],
        goalLabel: 'Ôn thi THPT khối A1',
        studyLevel: 'exam_prep',
        studyLevelLabelVi: 'Đang ôn thi',
        friendStatus: 'friends',
        matchScore: 95,
        matchReasonVi: 'Cùng Lớp 11 · Chung môn Toán, Vật lí',
      ),
      const PublicStudentProfile(
        userId: 'peer_quang_huy',
        alias: 'Quang Huy 11B',
        avatarId: 'avatar_clock',
        gradeLevel: 'Lớp 11',
        selectedSubjects: <String>['math', 'chemistry'],
        goalLabel: 'Chinh phục 9+ Toán',
        studyLevel: 'challenge',
        studyLevelLabelVi: 'Thử thách cao',
        friendStatus: 'none',
        matchScore: 80,
        matchReasonVi: 'Cùng Lớp 11 · Chung môn Toán',
      ),
      const PublicStudentProfile(
        userId: 'peer_gia_bao',
        alias: 'Gia Bảo 12C',
        avatarId: 'avatar_scholar',
        gradeLevel: 'Lớp 12',
        selectedSubjects: <String>['literature', 'english'],
        goalLabel: 'Luyện đề khối D',
        studyLevel: 'basic',
        studyLevelLabelVi: 'Cơ bản',
        friendStatus: 'incoming_pending',
        pendingRequestId: 'req_bao_1',
        matchScore: 60,
        matchReasonVi: 'Chung môn Tiếng Anh',
      ),
    ];

    _rooms = <StudyRoomDetail>[
      const StudyRoomDetail(
        summary: PublicStudyRoomSummary(
          roomId: 'room_toan_11',
          roomCode: 'MIND11',
          title: 'Cày đề Đạo hàm & Hàm số 11',
          subjectCode: 'math',
          gradeLevel: 'Lớp 11',
          targetLevel: 'exam_prep',
          targetLevelLabelVi: 'Đang ôn thi',
          visibility: 'public',
          maxMembers: 6,
          memberCount: 2,
          aiCompanionEnabled: true,
          ownerAlias: 'Minh Anh 11A1',
          ownerAvatarId: 'avatar_book',
          matchScore: 95,
          matchReasonVi: 'Cùng Lớp 11 · Đúng môn Toán · Nhịp Đang ôn thi',
        ),
        members: <StudyRoomMemberTile>[
          StudyRoomMemberTile(
            userId: 'peer_minh_anh',
            alias: 'Minh Anh 11A1',
            avatarId: 'avatar_book',
            gradeLevel: 'Lớp 11',
            role: 'host',
            micEnabled: false,
            camEnabled: true,
            statusNote: 'Đang giải bài 3 SGK',
          ),
          StudyRoomMemberTile(
            userId: 'peer_quang_huy',
            alias: 'Quang Huy 11B',
            avatarId: 'avatar_clock',
            gradeLevel: 'Lớp 11',
            role: 'member',
            micEnabled: false,
            camEnabled: false,
            statusNote: 'Đang tập trung 45p',
          ),
        ],
      ),
      const StudyRoomDetail(
        summary: PublicStudyRoomSummary(
          roomId: 'room_vat_ly_11',
          roomCode: 'PHY11A',
          title: 'Ôn Dao động cơ nâng cao',
          subjectCode: 'physics',
          gradeLevel: 'Lớp 11',
          targetLevel: 'challenge',
          targetLevelLabelVi: 'Thử thách cao',
          visibility: 'public',
          maxMembers: 4,
          memberCount: 1,
          aiCompanionEnabled: true,
          ownerAlias: 'Quang Huy 11B',
          ownerAvatarId: 'avatar_clock',
          matchScore: 75,
          matchReasonVi: 'Cùng Lớp 11 · Đúng môn Vật lí',
        ),
        members: <StudyRoomMemberTile>[
          StudyRoomMemberTile(
            userId: 'peer_quang_huy',
            alias: 'Quang Huy 11B',
            avatarId: 'avatar_clock',
            gradeLevel: 'Lớp 11',
            role: 'host',
            micEnabled: false,
            camEnabled: false,
            statusNote: 'Luyện đề chương 1',
          ),
        ],
      ),
    ];
  }

  late List<PublicStudentProfile> _peers;
  late List<StudyRoomDetail> _rooms;
  final Set<String> _blockedIds = <String>{};

  @override
  bool get isDebugFixture => true;

  @override
  Future<PublicStudentProfile> fetchPublicProfile(String userId) async {
    return _peers.firstWhere(
      (PublicStudentProfile p) => p.userId == userId,
      orElse: () => _peers.first,
    );
  }

  @override
  Future<List<PublicStudentProfile>> searchUsers({
    String query = '',
    String? gradeLevel,
    String? subjectCode,
  }) async {
    final String q = query.trim().toLowerCase();
    return _peers.where((PublicStudentProfile p) {
      if (_blockedIds.contains(p.userId)) return false;
      if (q.isNotEmpty && !p.alias.toLowerCase().contains(q)) return false;
      if (gradeLevel != null &&
          gradeLevel.trim().isNotEmpty &&
          p.gradeLevel != gradeLevel.trim()) {
        return false;
      }
      if (subjectCode != null &&
          subjectCode.trim().isNotEmpty &&
          !p.selectedSubjects.contains(subjectCode.trim())) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  @override
  Future<void> sendFriendRequest(
    String receiverUserId, {
    String messageVi = '',
  }) async {
    _peers = _peers.map((PublicStudentProfile p) {
      if (p.userId == receiverUserId && p.friendStatus == 'none') {
        return p.copyWith(
          friendStatus: 'outgoing_pending',
          pendingRequestId: 'req_$receiverUserId',
        );
      }
      return p;
    }).toList(growable: false);
  }

  @override
  Future<({List<FriendRequestItem> incoming, List<FriendRequestItem> outgoing})>
      fetchFriendRequests() async {
    final List<FriendRequestItem> incoming = _peers
        .where((PublicStudentProfile p) => p.friendStatus == 'incoming_pending')
        .map(
          (PublicStudentProfile p) => FriendRequestItem(
            requestId: p.pendingRequestId ?? 'req_${p.userId}',
            status: 'pending',
            messageVi: 'Xin kết bạn ôn thi cùng bạn!',
            peer: p,
          ),
        )
        .toList(growable: false);
    final List<FriendRequestItem> outgoing = _peers
        .where((PublicStudentProfile p) => p.friendStatus == 'outgoing_pending')
        .map(
          (PublicStudentProfile p) => FriendRequestItem(
            requestId: p.pendingRequestId ?? 'req_${p.userId}',
            status: 'pending',
            messageVi: 'Cùng học tập trung trên MindClock nhé!',
            peer: p,
          ),
        )
        .toList(growable: false);
    return (incoming: incoming, outgoing: outgoing);
  }

  @override
  Future<void> respondFriendRequest(String requestId, String decision) async {
    _peers = _peers.map((PublicStudentProfile p) {
      final String pid = p.pendingRequestId ?? 'req_${p.userId}';
      if (pid == requestId) {
        return p.copyWith(
          friendStatus: decision == 'accept' ? 'friends' : 'none',
        );
      }
      return p;
    }).toList(growable: false);
  }

  @override
  Future<List<PublicStudentProfile>> fetchFriends() async {
    return _peers
        .where(
          (PublicStudentProfile p) =>
              !_blockedIds.contains(p.userId) && p.friendStatus == 'friends',
        )
        .toList(growable: false);
  }

  @override
  Future<void> blockUser(String blockedUserId, {String reason = ''}) async {
    _blockedIds.add(blockedUserId);
  }

  @override
  Future<List<PublicStudyRoomSummary>> listPublicRooms({
    String? gradeLevel,
    String? subjectCode,
  }) async {
    return _rooms
        .map((StudyRoomDetail r) => r.summary)
        .where((PublicStudyRoomSummary s) {
          if (s.visibility != 'public') return false;
          if (gradeLevel != null &&
              gradeLevel.trim().isNotEmpty &&
              s.gradeLevel != gradeLevel.trim()) {
            return false;
          }
          if (subjectCode != null &&
              subjectCode.trim().isNotEmpty &&
              s.subjectCode != subjectCode.trim()) {
            return false;
          }
          return true;
        })
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
    final String id = 'room_${DateTime.now().microsecondsSinceEpoch}';
    final StudyRoomDetail created = StudyRoomDetail(
      summary: PublicStudyRoomSummary(
        roomId: id,
        roomCode: 'MC${(100 + _rooms.length).toString()}',
        title: title,
        subjectCode: subjectCode,
        gradeLevel: gradeLevel,
        targetLevel: targetLevel,
        targetLevelLabelVi:
            targetLevel == 'exam_prep' ? 'Đang ôn thi' : 'Cơ bản',
        visibility: visibility,
        maxMembers: maxMembers,
        memberCount: 1,
        aiCompanionEnabled: aiCompanionEnabled,
        ownerAlias: 'Bạn (Chủ phòng)',
        ownerAvatarId: 'avatar_sunrise',
      ),
      members: const <StudyRoomMemberTile>[
        StudyRoomMemberTile(
          userId: 'self_user',
          alias: 'Bạn (Chủ phòng)',
          avatarId: 'avatar_sunrise',
          role: 'host',
          micEnabled: false,
          camEnabled: false,
          statusNote: 'Đang tập trung',
          isSelf: true,
        ),
      ],
    );
    _rooms = <StudyRoomDetail>[created, ..._rooms];
    return created;
  }

  @override
  Future<StudyRoomDetail> joinRoom(
    String roomId, {
    String? roomCode,
    bool micEnabled = false,
    bool camEnabled = false,
    String statusNote = 'Đang tập trung',
  }) async {
    final int idx = _rooms.indexWhere(
      (StudyRoomDetail r) =>
          r.summary.roomId == roomId ||
          (roomCode != null && r.summary.roomCode == roomCode.trim().toUpperCase()),
    );
    final StudyRoomDetail target = idx >= 0 ? _rooms[idx] : _rooms.first;
    final bool hasSelf =
        target.members.any((StudyRoomMemberTile m) => m.isSelf);
    final List<StudyRoomMemberTile> nextMembers = hasSelf
        ? target.members
        : <StudyRoomMemberTile>[
            ...target.members,
            StudyRoomMemberTile(
              userId: 'self_user',
              alias: 'Bạn',
              avatarId: 'avatar_sunrise',
              gradeLevel: target.summary.gradeLevel,
              role: 'member',
              micEnabled: micEnabled,
              camEnabled: camEnabled,
              statusNote: statusNote,
              isSelf: true,
            ),
          ];
    final StudyRoomDetail updated = target.copyWith(
      members: nextMembers,
      summary: PublicStudyRoomSummary(
        roomId: target.summary.roomId,
        roomCode: target.summary.roomCode,
        title: target.summary.title,
        subjectCode: target.summary.subjectCode,
        gradeLevel: target.summary.gradeLevel,
        targetLevel: target.summary.targetLevel,
        targetLevelLabelVi: target.summary.targetLevelLabelVi,
        visibility: target.summary.visibility,
        maxMembers: target.summary.maxMembers,
        memberCount: nextMembers.length,
        aiCompanionEnabled: target.summary.aiCompanionEnabled,
        ownerAlias: target.summary.ownerAlias,
        ownerAvatarId: target.summary.ownerAvatarId,
        matchScore: target.summary.matchScore,
        matchReasonVi: target.summary.matchReasonVi,
      ),
    );
    if (idx >= 0) {
      _rooms = List<StudyRoomDetail>.from(_rooms)..[idx] = updated;
    }
    return updated;
  }

  @override
  Future<StudyRoomDetail> updateRoomMedia(
    String roomId, {
    bool? micEnabled,
    bool? camEnabled,
    bool? aiCompanionEnabled,
    String? statusNote,
  }) async {
    final int idx =
        _rooms.indexWhere((StudyRoomDetail r) => r.summary.roomId == roomId);
    if (idx < 0) return _rooms.first;
    final StudyRoomDetail target = _rooms[idx];
    final List<StudyRoomMemberTile> nextMembers = target.members
        .map((StudyRoomMemberTile m) => m.isSelf
            ? m.copyWith(
                micEnabled: micEnabled,
                camEnabled: camEnabled,
                statusNote: statusNote,
              )
            : m)
        .toList(growable: false);
    final StudyRoomDetail updated = target.copyWith(
      members: nextMembers,
      summary: PublicStudyRoomSummary(
        roomId: target.summary.roomId,
        roomCode: target.summary.roomCode,
        title: target.summary.title,
        subjectCode: target.summary.subjectCode,
        gradeLevel: target.summary.gradeLevel,
        targetLevel: target.summary.targetLevel,
        targetLevelLabelVi: target.summary.targetLevelLabelVi,
        visibility: target.summary.visibility,
        maxMembers: target.summary.maxMembers,
        memberCount: nextMembers.length,
        aiCompanionEnabled:
            aiCompanionEnabled ?? target.summary.aiCompanionEnabled,
        ownerAlias: target.summary.ownerAlias,
        ownerAvatarId: target.summary.ownerAvatarId,
      ),
    );
    _rooms = List<StudyRoomDetail>.from(_rooms)..[idx] = updated;
    return updated;
  }

  @override
  Future<void> leaveRoom(String roomId) async {
    final int idx =
        _rooms.indexWhere((StudyRoomDetail r) => r.summary.roomId == roomId);
    if (idx < 0) return;
    final StudyRoomDetail target = _rooms[idx];
    final List<StudyRoomMemberTile> nextMembers = target.members
        .where((StudyRoomMemberTile m) => !m.isSelf)
        .toList(growable: false);
    _rooms = List<StudyRoomDetail>.from(_rooms)
      ..[idx] = target.copyWith(members: nextMembers);
  }

  @override
  Future<StudyAiMatchResult> aiMatchGroups({
    String? subjectCode,
    String? gradeLevel,
    String? targetLevel,
  }) async {
    final List<PublicStudyRoomSummary> rooms = _rooms
        .map((StudyRoomDetail d) => d.summary)
        .where((PublicStudyRoomSummary s) => s.visibility == 'public')
        .toList(growable: false);
    final List<PublicStudentProfile> peers = _peers
        .where((PublicStudentProfile p) => !_blockedIds.contains(p.userId))
        .toList(growable: false);
    return StudyAiMatchResult(
      recommendedRooms: rooms,
      recommendedPeers: peers,
    );
  }
}
