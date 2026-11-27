class CommitmentPetSummary {
  const CommitmentPetSummary({
    required this.keyName,
    required this.name,
    required this.stage,
    required this.stageLabelVi,
    required this.totalCareDays,
    required this.currentStreakDays,
    required this.todayCareCount,
    required this.totalXp,
    required this.nextStageXp,
    required this.progressionVersion,
    this.bestStreakDays = 0,
    this.memberCount = 1,
    this.allMembersDoneToday = false,
    this.streakMilestoneLabelVi,
    this.busyCountToday = 0,
    this.streakPreservedToday = false,
    this.shieldsAvailable = 0,
    this.myBusyQuotaUsed = 0,
    this.myBusyQuotaLimit = 2,
    this.busyTodayByMe = false,
  });

  factory CommitmentPetSummary.fromJson(Map<String, dynamic> json) {
    final int streak = (json['currentStreakDays'] as int?) ?? 0;
    return CommitmentPetSummary(
      keyName: json['key'] as String? ?? 'mam',
      name: json['name'] as String? ?? 'Mầm',
      stage: json['stage'] as int? ?? 1,
      stageLabelVi: json['stageLabelVi'] as String? ?? 'Mầm non',
      totalCareDays: json['totalCareDays'] as int? ?? 0,
      currentStreakDays: streak,
      bestStreakDays: (json['bestStreakDays'] as int?) ?? streak,
      todayCareCount: json['todayCareCount'] as int? ?? 0,
      memberCount: (json['memberCount'] as int?) ?? 1,
      allMembersDoneToday: json['allMembersDoneToday'] as bool? ?? false,
      streakMilestoneLabelVi: json['streakMilestoneLabelVi'] as String?,
      busyCountToday: json['busyCountToday'] as int? ?? 0,
      streakPreservedToday: json['streakPreservedToday'] as bool? ?? false,
      shieldsAvailable: json['shieldsAvailable'] as int? ?? 0,
      myBusyQuotaUsed: json['myBusyQuotaUsed'] as int? ?? 0,
      myBusyQuotaLimit: json['myBusyQuotaLimit'] as int? ?? 2,
      busyTodayByMe: json['busyTodayByMe'] as bool? ?? false,
      totalXp: json['totalXp'] as int? ?? 0,
      nextStageXp: json['nextStageXp'] as int? ?? 60,
      progressionVersion:
          json['progressionVersion'] as String? ?? 'pet-progression-v0.1',
    );
  }

  final String keyName;
  final String name;
  final int stage;
  final String stageLabelVi;
  final int totalCareDays;
  final int currentStreakDays;
  final int bestStreakDays;
  final int todayCareCount;
  final int memberCount;
  final bool allMembersDoneToday;
  final String? streakMilestoneLabelVi;
  final int busyCountToday;
  final bool streakPreservedToday;
  final int shieldsAvailable;
  final int myBusyQuotaUsed;
  final int myBusyQuotaLimit;
  final bool busyTodayByMe;
  final int totalXp;
  final int nextStageXp;
  final String progressionVersion;

  String get milestoneLabelVi =>
      streakMilestoneLabelVi ??
      (currentStreakDays >= 100
          ? 'Chuỗi 100+'
          : (currentStreakDays > 0
              ? 'Chuỗi $currentStreakDays'
              : 'Chưa mở chuỗi'));
}

class CommitmentGroupMemberItem {
  const CommitmentGroupMemberItem({
    required this.userId,
    required this.alias,
    required this.avatarId,
    required this.role,
    required this.isSelf,
  });
  factory CommitmentGroupMemberItem.fromJson(Map<String, dynamic> json) =>
      CommitmentGroupMemberItem(
        userId: json['userId'] as String? ?? '',
        alias: json['alias'] as String? ?? 'Học sinh MindClock',
        avatarId: json['avatarId'] as String? ?? 'avatar_sunrise',
        role: json['role'] as String? ?? 'member',
        isSelf: json['isSelf'] as bool? ?? false,
      );
  final String userId;
  final String alias;
  final String avatarId;
  final String role;
  final bool isSelf;
}

class CommitmentJoinRequestItem {
  const CommitmentJoinRequestItem({
    required this.requestId,
    required this.userId,
    required this.alias,
    required this.avatarId,
  });
  factory CommitmentJoinRequestItem.fromJson(Map<String, dynamic> json) =>
      CommitmentJoinRequestItem(
        requestId: json['requestId'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        alias: json['alias'] as String? ?? 'Học sinh MindClock',
        avatarId: json['avatarId'] as String? ?? 'avatar_sunrise',
      );
  final String requestId;
  final String userId;
  final String alias;
  final String avatarId;
}

class CommitmentGroupDetail {
  const CommitmentGroupDetail({
    required this.groupId,
    required this.groupCode,
    required this.name,
    required this.ownerId,
    required this.isOwner,
    required this.isPrimary,
    required this.maxMembers,
    required this.members,
    required this.pendingRequests,
    required this.pet,
  });
  factory CommitmentGroupDetail.fromJson(Map<String, dynamic> json) =>
      CommitmentGroupDetail(
        groupId: json['groupId'] as String? ?? '',
        groupCode: json['groupCode'] as String? ?? '',
        name: json['name'] as String? ?? 'Nhóm cam kết',
        ownerId: json['ownerId'] as String? ?? '',
        isOwner: json['isOwner'] as bool? ?? false,
        isPrimary: json['isPrimary'] as bool? ?? false,
        maxMembers: json['maxMembers'] as int? ?? 4,
        members: (json['members'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .map(CommitmentGroupMemberItem.fromJson)
            .toList(growable: false),
        pendingRequests:
            (json['pendingRequests'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(CommitmentJoinRequestItem.fromJson)
                .toList(growable: false),
        pet: CommitmentPetSummary.fromJson(
            json['pet'] as Map<String, dynamic>? ?? <String, dynamic>{}),
      );
  final String groupId;
  final String groupCode;
  final String name;
  final String ownerId;
  final bool isOwner;
  final bool isPrimary;
  final int maxMembers;
  final List<CommitmentGroupMemberItem> members;
  final List<CommitmentJoinRequestItem> pendingRequests;
  final CommitmentPetSummary pet;
}

class CommitmentGroupInviteItem {
  const CommitmentGroupInviteItem({
    required this.inviteId,
    required this.groupId,
    required this.groupName,
    required this.inviterAlias,
    required this.expiresAt,
  });
  factory CommitmentGroupInviteItem.fromJson(Map<String, dynamic> json) =>
      CommitmentGroupInviteItem(
        inviteId: json['inviteId'] as String? ?? '',
        groupId: json['groupId'] as String? ?? '',
        groupName: json['groupName'] as String? ?? 'Nhóm cam kết',
        inviterAlias: json['inviterAlias'] as String? ?? 'Học sinh MindClock',
        expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      );
  final String inviteId;
  final String groupId;
  final String groupName;
  final String inviterAlias;
  final DateTime? expiresAt;
}

class CommitmentGroupHub {
  const CommitmentGroupHub({
    required this.groups,
    required this.incomingInvites,
    required this.membershipLimit,
  });
  factory CommitmentGroupHub.fromJson(Map<String, dynamic> json) =>
      CommitmentGroupHub(
        groups: (json['groups'] as List<dynamic>? ??
                (json['group'] is Map<String, dynamic>
                    ? <dynamic>[json['group']]
                    : const <dynamic>[]))
            .whereType<Map<String, dynamic>>()
            .map(CommitmentGroupDetail.fromJson)
            .toList(growable: false),
        incomingInvites:
            (json['incomingInvites'] as List<dynamic>? ?? const <dynamic>[])
                .whereType<Map<String, dynamic>>()
                .map(CommitmentGroupInviteItem.fromJson)
                .toList(growable: false),
        membershipLimit: json['membershipLimit'] as int? ?? 3,
      );
  final List<CommitmentGroupDetail> groups;
  CommitmentGroupDetail? get group => groups.isEmpty ? null : groups.first;
  final List<CommitmentGroupInviteItem> incomingInvites;
  final int membershipLimit;
}
