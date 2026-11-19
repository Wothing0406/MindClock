import 'subject_catalog.dart';

/// Hồ sơ học sinh công khai (opt-in projection; tuyệt đối không chứa email/TKB chi tiết/giờ dậy).
class PublicStudentProfile {
  const PublicStudentProfile({
    required this.userId,
    required this.alias,
    this.avatarId = 'avatar_sunrise',
    this.gradeLevel = 'Lớp 11',
    this.selectedSubjects = const <String>[],
    this.goalLabel = '',
    this.studyLevel = 'basic',
    this.studyLevelLabelVi = 'Cơ bản',
    this.friendStatus = 'none',
    this.pendingRequestId,
    this.matchScore,
    this.matchReasonVi,
  });

  final String userId;
  final String alias;
  final String avatarId;
  final String gradeLevel;
  final List<String> selectedSubjects;
  final String goalLabel;
  final String studyLevel;
  final String studyLevelLabelVi;
  final String friendStatus; // self | friends | outgoing_pending | incoming_pending | none
  final String? pendingRequestId;
  final int? matchScore;
  final String? matchReasonVi;

  String get subjectSummaryVi {
    if (selectedSubjects.isEmpty) return 'Chưa cập nhật môn';
    return selectedSubjects.map(SubjectCatalog.nameFor).join(', ');
  }

  PublicStudentProfile copyWith({
    String? friendStatus,
    String? pendingRequestId,
  }) {
    return PublicStudentProfile(
      userId: userId,
      alias: alias,
      avatarId: avatarId,
      gradeLevel: gradeLevel,
      selectedSubjects: selectedSubjects,
      goalLabel: goalLabel,
      studyLevel: studyLevel,
      studyLevelLabelVi: studyLevelLabelVi,
      friendStatus: friendStatus ?? this.friendStatus,
      pendingRequestId: pendingRequestId ?? this.pendingRequestId,
      matchScore: matchScore,
      matchReasonVi: matchReasonVi,
    );
  }

  factory PublicStudentProfile.fromJson(Map<String, dynamic> json) {
    final List<String> rawSubjects =
        (json['selectedSubjects'] as List<dynamic>? ?? <dynamic>[])
            .whereType<String>()
            .toList(growable: false);
    return PublicStudentProfile(
      userId: json['userId'] as String? ?? '',
      alias: json['alias'] as String? ?? 'Học sinh MindClock',
      avatarId: json['avatarId'] as String? ?? 'avatar_sunrise',
      gradeLevel: json['gradeLevel'] as String? ?? 'Lớp 11',
      selectedSubjects: rawSubjects,
      goalLabel: json['goalLabel'] as String? ?? '',
      studyLevel: json['studyLevel'] as String? ?? 'basic',
      studyLevelLabelVi: json['studyLevelLabelVi'] as String? ?? 'Cơ bản',
      friendStatus: json['friendStatus'] as String? ?? 'none',
      pendingRequestId: json['pendingRequestId'] as String?,
      matchScore: (json['matchScore'] as num?)?.toInt(),
      matchReasonVi: json['matchReasonVi'] as String?,
    );
  }
}

class FriendRequestItem {
  const FriendRequestItem({
    required this.requestId,
    required this.status,
    required this.messageVi,
    required this.peer,
    this.createdAt,
  });

  final String requestId;
  final String status;
  final String messageVi;
  final PublicStudentProfile peer;
  final String? createdAt;

  factory FriendRequestItem.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawPeer =
        json['peer'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return FriendRequestItem(
      requestId: json['requestId'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      messageVi: json['messageVi'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      peer: PublicStudentProfile.fromJson(rawPeer),
    );
  }
}

class PublicStudyRoomSummary {
  const PublicStudyRoomSummary({
    required this.roomId,
    required this.roomCode,
    required this.title,
    required this.subjectCode,
    required this.gradeLevel,
    required this.targetLevel,
    required this.targetLevelLabelVi,
    required this.visibility,
    required this.maxMembers,
    required this.memberCount,
    required this.aiCompanionEnabled,
    required this.ownerAlias,
    required this.ownerAvatarId,
    this.status = 'active',
    this.matchScore,
    this.matchReasonVi,
  });

  final String roomId;
  final String roomCode;
  final String title;
  final String subjectCode;
  final String gradeLevel;
  final String targetLevel;
  final String targetLevelLabelVi;
  final String visibility; // public | invite_only
  final int maxMembers;
  final int memberCount;
  final bool aiCompanionEnabled;
  final String ownerAlias;
  final String ownerAvatarId;
  final String status;
  final int? matchScore;
  final String? matchReasonVi;

  String get subjectNameVi => SubjectCatalog.nameFor(subjectCode);

  factory PublicStudyRoomSummary.fromJson(Map<String, dynamic> json) {
    return PublicStudyRoomSummary(
      roomId: json['roomId'] as String? ?? '',
      roomCode: json['roomCode'] as String? ?? '',
      title: json['title'] as String? ?? 'Phòng học chung',
      subjectCode: json['subjectCode'] as String? ?? 'TOAN',
      gradeLevel: json['gradeLevel'] as String? ?? 'Lớp 11',
      targetLevel: json['targetLevel'] as String? ?? 'basic',
      targetLevelLabelVi: json['targetLevelLabelVi'] as String? ?? 'Cơ bản',
      visibility: json['visibility'] as String? ?? 'public',
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 4,
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 1,
      aiCompanionEnabled: json['aiCompanionEnabled'] as bool? ?? true,
      ownerAlias: json['ownerAlias'] as String? ?? 'Trưởng phòng',
      ownerAvatarId: json['ownerAvatarId'] as String? ?? 'avatar_sunrise',
      status: json['status'] as String? ?? 'active',
      matchScore: (json['matchScore'] as num?)?.toInt(),
      matchReasonVi: json['matchReasonVi'] as String?,
    );
  }
}

class StudyRoomMemberTile {
  const StudyRoomMemberTile({
    required this.userId,
    required this.alias,
    this.avatarId = 'avatar_sunrise',
    this.gradeLevel = 'Lớp 11',
    this.role = 'member',
    this.micEnabled = false,
    this.camEnabled = false,
    this.statusNote = 'Đang tập trung',
    this.isSelf = false,
  });

  final String userId;
  final String alias;
  final String avatarId;
  final String gradeLevel;
  final String role;
  final bool micEnabled;
  final bool camEnabled;
  final String statusNote;
  final bool isSelf;

  StudyRoomMemberTile copyWith({
    bool? micEnabled,
    bool? camEnabled,
    String? statusNote,
  }) {
    return StudyRoomMemberTile(
      userId: userId,
      alias: alias,
      avatarId: avatarId,
      gradeLevel: gradeLevel,
      role: role,
      micEnabled: micEnabled ?? this.micEnabled,
      camEnabled: camEnabled ?? this.camEnabled,
      statusNote: statusNote ?? this.statusNote,
      isSelf: isSelf,
    );
  }

  factory StudyRoomMemberTile.fromJson(Map<String, dynamic> json) {
    return StudyRoomMemberTile(
      userId: json['userId'] as String? ?? '',
      alias: json['alias'] as String? ?? 'Thành viên',
      avatarId: json['avatarId'] as String? ?? 'avatar_sunrise',
      gradeLevel: json['gradeLevel'] as String? ?? 'Lớp 11',
      role: json['role'] as String? ?? 'member',
      micEnabled: json['micEnabled'] as bool? ?? false,
      camEnabled: json['camEnabled'] as bool? ?? false,
      statusNote: json['statusNote'] as String? ?? 'Đang tập trung',
      isSelf: json['isSelf'] as bool? ?? false,
    );
  }
}

class StudyRoomDetail {
  const StudyRoomDetail({
    required this.summary,
    required this.members,
  });

  final PublicStudyRoomSummary summary;
  final List<StudyRoomMemberTile> members;

  StudyRoomDetail copyWith({
    PublicStudyRoomSummary? summary,
    List<StudyRoomMemberTile>? members,
  }) {
    return StudyRoomDetail(
      summary: summary ?? this.summary,
      members: members ?? this.members,
    );
  }

  factory StudyRoomDetail.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawMembers =
        json['members'] as List<dynamic>? ?? <dynamic>[];
    return StudyRoomDetail(
      summary: PublicStudyRoomSummary.fromJson(json),
      members: rawMembers
          .whereType<Map<String, dynamic>>()
          .map(StudyRoomMemberTile.fromJson)
          .toList(growable: false),
    );
  }
}

class StudyAiMatchResult {
  const StudyAiMatchResult({
    required this.recommendedRooms,
    required this.recommendedPeers,
  });

  final List<PublicStudyRoomSummary> recommendedRooms;
  final List<PublicStudentProfile> recommendedPeers;

  factory StudyAiMatchResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawRooms =
        json['recommendedRooms'] as List<dynamic>? ?? <dynamic>[];
    final List<dynamic> rawPeers =
        json['recommendedPeers'] as List<dynamic>? ?? <dynamic>[];
    return StudyAiMatchResult(
      recommendedRooms: rawRooms
          .whereType<Map<String, dynamic>>()
          .map(PublicStudyRoomSummary.fromJson)
          .toList(growable: false),
      recommendedPeers: rawPeers
          .whereType<Map<String, dynamic>>()
          .map(PublicStudentProfile.fromJson)
          .toList(growable: false),
    );
  }
}
