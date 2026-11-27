import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../domain/models/commitment_group_models.dart';
import '../../../../domain/models/community_models.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mam_pet_view.dart';
import '../../../core/widgets/mindclock_avatar_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';

/// Màn hình Nhóm cam kết chuyên biệt (phong cách bình minh trên trang vở + Hero thẻ tối).
class CommitmentGroupScreen extends StatefulWidget {
  const CommitmentGroupScreen({
    super.key,
    required this.repository,
    this.initialGroupId,
  });

  final CommunityRepository repository;
  final String? initialGroupId;

  @override
  State<CommitmentGroupScreen> createState() => _CommitmentGroupScreenState();
}

class _CommitmentGroupScreenState extends State<CommitmentGroupScreen> {
  CommitmentGroupHub? _hub;
  List<PublicStudentProfile> _friends = const <PublicStudentProfile>[];
  bool _loading = true;
  bool _saving = false;
  String? _feedback;
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
    _load();
  }

  CommitmentGroupDetail? get _currentGroup {
    final List<CommitmentGroupDetail> groups =
        _hub?.groups ?? const <CommitmentGroupDetail>[];
    if (groups.isEmpty) return null;
    return groups.firstWhere(
      (CommitmentGroupDetail item) => item.groupId == _selectedGroupId,
      orElse: () => groups.first,
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final CommitmentGroupHub hub =
          await widget.repository.fetchCommitmentGroupHub();
      final List<PublicStudentProfile> friends =
          hub.groups.any((CommitmentGroupDetail g) => g.isOwner)
              ? await widget.repository.fetchFriends()
              : const <PublicStudentProfile>[];
      if (!mounted) return;
      setState(() {
        _hub = hub;
        _selectedGroupId = hub.groups.any((CommitmentGroupDetail item) =>
                item.groupId == _selectedGroupId)
            ? _selectedGroupId
            : hub.group?.groupId;
        _friends = friends;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _feedback = 'Chưa tải được dữ liệu nhóm. Hãy kiểm tra kết nối.';
      });
    }
  }

  Future<void> _act(Future<void> Function() action, String success) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _feedback = null;
    });
    try {
      await action();
      await _load();
      if (!mounted) return;
      setState(() => _feedback = success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _feedback = 'Thao tác chưa hoàn tất. Hãy thử lại.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyGroupCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    setState(() => _feedback = 'Đã sao chép mã nhóm $code.');
  }

  Future<void> _openCreateGroupDialog() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController petCtrl = TextEditingController(text: 'Mầm');
    final bool? created = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final MindClockTheme mc = context.mc;
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setLocal) => AlertDialog(
            backgroundColor: mc.surface,
            title: Text('Tạo nhóm giữ chuỗi', style: mc.sectionTitleStyle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Tối đa 4 thành viên. Cả nhóm hoàn thành trong ngày để cộng +1 Chuỗi.',
                    style: mc.captionStyle,
                  ),
                  SizedBox(height: mc.space12),
                  TextField(
                    key: const ValueKey<String>('group-screen-create-name'),
                    controller: nameCtrl,
                    onChanged: (_) => setLocal(() {}),
                    decoration: const InputDecoration(labelText: 'Tên nhóm'),
                    maxLength: 60,
                  ),
                  TextField(
                    key: const ValueKey<String>('group-screen-create-pet'),
                    controller: petCtrl,
                    decoration: const InputDecoration(labelText: 'Tên pet nhóm'),
                    maxLength: 40,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                key: const ValueKey<String>('group-screen-create-submit'),
                onPressed: nameCtrl.text.trim().length < 2
                    ? null
                    : () => Navigator.of(dialogContext).pop(true),
                child: const Text('Tạo nhóm'),
              ),
            ],
          ),
        );
      },
    );

    if (created == true && mounted) {
      final String name = nameCtrl.text.trim();
      final String petName =
          petCtrl.text.trim().isEmpty ? 'Mầm' : petCtrl.text.trim();
      await _act(
        () => widget.repository.createCommitmentGroup(name: name, petName: petName),
        'Đã tạo nhóm "$name". Chia sẻ mã để mời bạn vào giữ chuỗi!',
      );
    }
    nameCtrl.dispose();
    petCtrl.dispose();
  }

  Future<void> _openJoinByCodeDialog() async {
    final TextEditingController codeCtrl = TextEditingController();
    final bool? submitted = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final MindClockTheme mc = context.mc;
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setLocal) => AlertDialog(
            backgroundColor: mc.surface,
            title: Text('Nhập mã vào nhóm', style: mc.sectionTitleStyle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Nhập mã 6 ký tự từ trưởng nhóm để gửi yêu cầu tham gia.',
                  style: mc.captionStyle,
                ),
                SizedBox(height: mc.space12),
                TextField(
                  key: const ValueKey<String>('group-screen-join-code'),
                  controller: codeCtrl,
                  onChanged: (_) => setLocal(() {}),
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Mã nhóm'),
                  maxLength: 12,
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                key: const ValueKey<String>('group-screen-join-submit'),
                onPressed: codeCtrl.text.trim().length < 4
                    ? null
                    : () => Navigator.of(dialogContext).pop(true),
                child: const Text('Gửi yêu cầu'),
              ),
            ],
          ),
        );
      },
    );

    if (submitted == true && mounted) {
      final String code = codeCtrl.text.trim().toUpperCase();
      await _act(
        () => widget.repository.requestCommitmentJoin(code),
        'Đã gửi yêu cầu tham gia mã $code.',
      );
    }
    codeCtrl.dispose();
  }

  Future<void> _openBusyTodayDialog(CommitmentGroupDetail group) async {
    String selectedReason = 'exam';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final MindClockTheme mc = context.mc;
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setLocal) => AlertDialog(
            backgroundColor: mc.surface,
            title: Text('Xin phép bận hôm nay', style: mc.sectionTitleStyle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Khi bạn báo bận (${group.pet.myBusyQuotaUsed}/${group.pet.myBusyQuotaLimit} lượt tháng này), các bạn còn lại hoàn thành sẽ bảo lưu nguyên Chuỗi nhóm thay vì tụt về 0.',
                  style: mc.captionStyle,
                ),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: <Widget>[
                    for (final (String code, String label) in const <(String, String)>[
                      ('exam', 'Đi thi / Kiểm tra'),
                      ('family', 'Việc gia đình'),
                      ('sick', 'Nghỉ ốm'),
                    ])
                      ChoiceChip(
                        key: ValueKey<String>('group-busy-reason-$code'),
                        label: Text(label),
                        selected: selectedReason == code,
                        onSelected: (_) => setLocal(() => selectedReason = code),
                      ),
                  ],
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Đóng'),
              ),
              FilledButton(
                key: const ValueKey<String>('group-busy-confirm-btn'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Xác nhận bảo lưu'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      await _act(
        () => widget.repository.reportCommitmentBusyToday(
          group.groupId,
          reason: selectedReason,
        ),
        'Đã ghi nhận xin phép bận hôm nay · Chuỗi nhóm sẽ được bảo lưu.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final List<CommitmentGroupDetail> groups =
        _hub?.groups ?? const <CommitmentGroupDetail>[];
    final CommitmentGroupDetail? group = _currentGroup;
    final int limit = _hub?.membershipLimit ?? 3;

    return Scaffold(
      backgroundColor: mc.paper,
      appBar: AppBar(
        backgroundColor: mc.paper,
        elevation: 0,
        title: Text('Nhóm giữ chuỗi', style: mc.sectionTitleStyle),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('group-screen-join-action'),
            tooltip: 'Nhập mã nhóm',
            onPressed: _saving ? null : _openJoinByCodeDialog,
            icon: MindClockIcon(MindClockIconKind.lock, color: mc.ink),
          ),
          IconButton(
            key: const ValueKey<String>('group-screen-create-action'),
            tooltip: 'Tạo nhóm mới',
            onPressed: (_saving || groups.length >= limit)
                ? null
                : _openCreateGroupDialog,
            icon: MindClockIcon(MindClockIconKind.plus, color: mc.primary),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? Center(child: Text('Đang tải nhóm...', style: mc.bodyStrongStyle))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: EdgeInsets.all(mc.space20),
                  children: <Widget>[
                    if (_feedback != null) ...<Widget>[
                      MindClockNoticeBanner(message: _feedback!, isWarm: false),
                      SizedBox(height: mc.space12),
                    ],
                    if ((_hub?.incomingInvites ??
                            const <CommitmentGroupInviteItem>[])
                        .isNotEmpty) ...<Widget>[
                      Text('Lời mời vào nhóm', style: mc.sectionTitleStyle),
                      SizedBox(height: mc.space8),
                      for (final CommitmentGroupInviteItem invite
                          in _hub!.incomingInvites)
                        Padding(
                          padding: EdgeInsets.only(bottom: mc.space8),
                          child: MindClockCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(invite.groupName, style: mc.bodyStrongStyle),
                                Text('Từ ${invite.inviterAlias}',
                                    style: mc.captionStyle),
                                SizedBox(height: mc.space8),
                                Wrap(
                                  spacing: mc.space8,
                                  runSpacing: mc.space8,
                                  children: <Widget>[
                                    MindClockButton(
                                      label: 'Tham gia',
                                      icon: MindClockIconKind.check,
                                      expand: false,
                                      onPressed: _saving
                                          ? null
                                          : () => _act(
                                                () => widget.repository
                                                    .respondCommitmentInvite(
                                                        invite.inviteId, 'accept'),
                                                'Đã tham gia nhóm.',
                                              ),
                                    ),
                                    MindClockButton(
                                      label: 'Từ chối',
                                      variant: MindClockButtonVariant.subtle,
                                      expand: false,
                                      onPressed: _saving
                                          ? null
                                          : () => _act(
                                                () => widget.repository
                                                    .respondCommitmentInvite(
                                                        invite.inviteId,
                                                        'decline'),
                                                'Đã từ chối lời mời.',
                                              ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: mc.space12),
                    ],
                    if (groups.isEmpty)
                      _buildEmptyHero(mc)
                    else ...<Widget>[
                      _buildGroupSwitcher(mc, groups, group!, limit),
                      SizedBox(height: mc.space12),
                      _buildGroupHeroCard(mc, group),
                      SizedBox(height: mc.space16),
                      _buildMembersSection(mc, group),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyHero(MindClockTheme mc) {
    return Container(
      key: const ValueKey<String>('group-screen-empty-hero'),
      padding: EdgeInsets.all(mc.space24),
      decoration: BoxDecoration(
        color: mc.surface,
        borderRadius: BorderRadius.circular(mc.radiusPaper),
        border: Border.all(color: mc.outline),
      ),
      child: Column(
        children: <Widget>[
          const MamPetView(stage: 1, reaction: MamPetReaction.idle, size: 108),
          SizedBox(height: mc.space12),
          Text(
            'Nuôi Pet & Giữ Chuỗi cùng bạn bè',
            textAlign: TextAlign.center,
            style: mc.sectionTitleStyle.copyWith(color: mc.ink),
          ),
          SizedBox(height: mc.space8),
          Text(
            'Mỗi nhóm tối đa 4 người. Cả nhóm cùng học hoặc báo cáo ngày để tăng Chuỗi 1 → Chuỗi 100+.',
            textAlign: TextAlign.center,
            style: mc.captionStyle.copyWith(color: mc.inkMuted),
          ),
          SizedBox(height: mc.space16),
          MindClockButton(
            key: const ValueKey<String>('group-empty-create-btn'),
            label: 'Tạo nhóm mới',
            icon: MindClockIconKind.plus,
            onPressed: _saving ? null : _openCreateGroupDialog,
          ),
          SizedBox(height: mc.space8),
          MindClockButton(
            key: const ValueKey<String>('group-empty-join-btn'),
            label: 'Nhập mã vào nhóm',
            icon: MindClockIconKind.lock,
            variant: MindClockButtonVariant.secondary,
            onPressed: _saving ? null : _openJoinByCodeDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSwitcher(
    MindClockTheme mc,
    List<CommitmentGroupDetail> groups,
    CommitmentGroupDetail selected,
    int limit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Nhóm của bạn (${groups.length}/$limit)',
          style: mc.captionStyle,
        ),
        SizedBox(height: mc.space8),
        Wrap(
          spacing: mc.space8,
          runSpacing: mc.space8,
          children: groups.map((CommitmentGroupDetail item) {
            final bool isActive = item.groupId == selected.groupId;
            return MindClockPressable(
              key: ValueKey<String>('group-chip-${item.groupId}'),
              onPressed: () => setState(() => _selectedGroupId = item.groupId),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: mc.space12,
                  vertical: mc.space8,
                ),
                decoration: BoxDecoration(
                  color: isActive ? mc.primary : mc.surface,
                  borderRadius: BorderRadius.circular(mc.radiusControl),
                  border: Border.all(
                    color: isActive ? mc.primary : mc.outline,
                  ),
                ),
                child: Text(
                  '${item.name} · ${item.pet.milestoneLabelVi}',
                  style: mc.captionStyle.copyWith(
                    color: isActive ? mc.onPrimary : mc.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  Widget _buildGroupHeroCard(MindClockTheme mc, CommitmentGroupDetail group) {
    final CommitmentPetSummary pet = group.pet;
    final int totalMembers = group.members.isEmpty ? 1 : group.members.length;
    final double ratio =
        (pet.todayCareCount / totalMembers).clamp(0.0, 1.0).toDouble();

    return Container(
      key: const ValueKey<String>('group-screen-hero-card'),
      padding: EdgeInsets.all(mc.space20),
      decoration: BoxDecoration(
        color: mc.surface,
        borderRadius: BorderRadius.circular(mc.radiusPaper),
        border: Border.all(
          color: pet.allMembersDoneToday ? mc.sunrise : mc.primary,
          width: 1.5,
        ),
      ),
      child: Column(
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: <Widget>[
              Text(
                group.name,
                style: mc.sectionTitleStyle.copyWith(color: mc.ink),
              ),
              MindClockPressable(
                key: const ValueKey<String>('group-copy-code-btn'),
                onPressed: () => _copyGroupCode(group.groupCode),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: mc.space12,
                    vertical: mc.space4,
                  ),
                  decoration: BoxDecoration(
                    color: mc.primarySoft,
                    borderRadius: BorderRadius.circular(mc.radiusChip),
                    border: Border.all(color: mc.primary.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Mã: ${group.groupCode} (Chép)',
                    style: mc.captionStyle.copyWith(
                      color: mc.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: mc.space12),
          MamPetView(
            stage: pet.stage,
            reaction: pet.allMembersDoneToday
                ? MamPetReaction.celebrate
                : (pet.todayCareCount > 0
                    ? MamPetReaction.happy
                    : MamPetReaction.idle),
            size: 112,
          ),
          SizedBox(height: mc.space8),
          Text(
            '${pet.name} · ${pet.stageLabelVi}',
            style: mc.bodyStrongStyle.copyWith(color: mc.ink),
          ),
          SizedBox(height: mc.space8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: mc.space12,
                  vertical: mc.space4,
                ),
                decoration: BoxDecoration(
                  color: mc.sunriseSoft,
                  borderRadius: BorderRadius.circular(mc.radiusChip),
                ),
                child: Text(
                  pet.currentStreakDays > 0
                      ? '${pet.milestoneLabelVi} (${pet.currentStreakDays} ngày)'
                      : 'Chưa mở chuỗi',
                  style: mc.captionStyle.copyWith(
                    color: mc.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: mc.space12,
                  vertical: mc.space4,
                ),
                decoration: BoxDecoration(
                  color: mc.primarySoft,
                  borderRadius: BorderRadius.circular(mc.radiusChip),
                ),
                child: Text(
                  'Hôm nay ${pet.todayCareCount}/$totalMembers người',
                  style: mc.captionStyle.copyWith(
                    color: mc.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: mc.space12),
          ClipRRect(
            borderRadius: BorderRadius.circular(mc.radiusChip),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: mc.primarySoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                pet.allMembersDoneToday ? mc.sunrise : mc.primary,
              ),
            ),
          ),
          SizedBox(height: mc.space8),
          Text(
            pet.allMembersDoneToday
                ? 'Cả nhóm đã hoàn thành hôm nay!'
                : (pet.streakPreservedToday
                    ? 'Hôm nay có ${pet.busyCountToday} bạn báo bận · Đang bảo lưu ${pet.milestoneLabelVi}.'
                    : 'Cả nhóm cùng hoàn thành trong ngày để tăng +1 Chuỗi.'),
            textAlign: TextAlign.center,
            style: mc.captionStyle.copyWith(color: mc.inkMuted),
          ),
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('group-busy-today-btn'),
            label: pet.busyTodayByMe
                ? 'Đã báo bận hôm nay (${pet.myBusyQuotaUsed}/${pet.myBusyQuotaLimit})'
                : 'Báo bận hôm nay (còn ${pet.myBusyQuotaLimit - pet.myBusyQuotaUsed}/${pet.myBusyQuotaLimit} lượt)',
            icon: MindClockIconKind.shield,
            variant: MindClockButtonVariant.secondary,
            onPressed: (_saving ||
                    pet.busyTodayByMe ||
                    pet.myBusyQuotaUsed >= pet.myBusyQuotaLimit)
                ? null
                : () => _openBusyTodayDialog(group),
          ),
          if (!group.isPrimary) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockButton(
              label: 'Chọn làm Pet chính ngoài màn hình',
              icon: MindClockIconKind.sunrise,
              variant: MindClockButtonVariant.secondary,
              onPressed: _saving
                  ? null
                  : () => _act(
                        () => widget.repository
                            .setPrimaryCommitmentGroup(group.groupId),
                        'Đã đặt làm nhóm chính.',
                      ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembersSection(
      MindClockTheme mc, CommitmentGroupDetail group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Thành viên (${group.members.length}/${group.maxMembers})',
          style: mc.sectionTitleStyle,
        ),
        SizedBox(height: mc.space8),
        for (final CommitmentGroupMemberItem m in group.members)
          Padding(
            padding: EdgeInsets.only(bottom: mc.space8),
            child: MindClockCard(
              padding: EdgeInsets.all(mc.space12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      MindClockAvatarView(avatarId: m.avatarId, size: 42),
                      SizedBox(width: mc.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(m.alias, style: mc.bodyStrongStyle),
                            Text(
                              m.role == 'owner' ? 'Trưởng nhóm' : 'Thành viên',
                              style: mc.captionStyle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (group.isOwner && m.role != 'owner') ...<Widget>[
                    SizedBox(height: mc.space8),
                    MindClockButton(
                      label: 'Mời ra',
                      variant: MindClockButtonVariant.subtle,
                      expand: false,
                      onPressed: _saving
                          ? null
                          : () => _act(
                                () => widget.repository.removeCommitmentMember(
                                  group.groupId,
                                  m.userId,
                                ),
                                'Đã mời thành viên rời nhóm.',
                              ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (group.isOwner && group.pendingRequests.isNotEmpty) ...<Widget>[
          SizedBox(height: mc.space12),
          Text('Yêu cầu xin vào nhóm', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          for (final CommitmentJoinRequestItem req in group.pendingRequests)
            Padding(
              padding: EdgeInsets.only(bottom: mc.space8),
              child: MindClockCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                        child: Text(req.alias, style: mc.bodyStrongStyle)),
                    MindClockButton(
                      label: 'Duyệt',
                      expand: false,
                      onPressed: _saving
                          ? null
                          : () => _act(
                                () => widget.repository.respondCommitmentJoinRequest(
                                  group.groupId,
                                  req.requestId,
                                  'accept',
                                ),
                                'Đã duyệt thành viên mới.',
                              ),
                    ),
                  ],
                ),
              ),
            ),
        ],
        if (group.isOwner &&
            group.members.length < group.maxMembers &&
            _friends.isNotEmpty) ...<Widget>[
          SizedBox(height: mc.space12),
          Text('Mời bạn bè vào giữ chuỗi', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          for (final PublicStudentProfile f in _friends)
            if (!group.members
                .any((CommitmentGroupMemberItem m) => m.userId == f.userId))
              Padding(
                padding: EdgeInsets.only(bottom: mc.space8),
                child: MindClockCard(
                  padding: EdgeInsets.all(mc.space12),
                  child: Row(
                    children: <Widget>[
                      MindClockAvatarView(avatarId: f.avatarId, size: 38),
                      SizedBox(width: mc.space12),
                      Expanded(
                        child: Text(f.alias, style: mc.bodyStrongStyle),
                      ),
                      MindClockButton(
                        label: 'Mời',
                        icon: MindClockIconKind.plus,
                        expand: false,
                        onPressed: _saving
                            ? null
                            : () => _act(
                                  () => widget.repository.inviteCommitmentFriend(
                                    group.groupId,
                                    f.userId,
                                  ),
                                  'Đã gửi lời mời tới ${f.alias}.',
                                ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ],
    );
  }
}
