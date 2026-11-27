import 'package:flutter/material.dart';

import '../../../../domain/models/commitment_group_models.dart';
import '../../../../domain/models/community_models.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mam_pet_view.dart';
import '../../../core/widgets/mindclock_avatar_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';

Future<void> showCommitmentGroupSheet({
  required BuildContext context,
  required CommunityRepository repository,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.mc.paper,
    builder: (_) => FractionallySizedBox(
      heightFactor: .94,
      child: CommitmentGroupSheet(repository: repository),
    ),
  );
}

class CommitmentGroupSheet extends StatefulWidget {
  const CommitmentGroupSheet({super.key, required this.repository});
  final CommunityRepository repository;

  @override
  State<CommitmentGroupSheet> createState() => _CommitmentGroupSheetState();
}

class _CommitmentGroupSheetState extends State<CommitmentGroupSheet> {
  final TextEditingController _groupName = TextEditingController();
  final TextEditingController _petName = TextEditingController(text: 'Mầm');
  final TextEditingController _groupCode = TextEditingController();
  CommitmentGroupHub? _hub;
  List<PublicStudentProfile> _friends = const <PublicStudentProfile>[];
  bool _loading = true;
  bool _saving = false;
  String? _feedback;
  String? _selectedGroupId;

  CommitmentGroupDetail? get _currentGroup {
    final List<CommitmentGroupDetail> groups =
        _hub?.groups ?? const <CommitmentGroupDetail>[];
    if (groups.isEmpty) return null;
    return groups.firstWhere(
      (CommitmentGroupDetail item) => item.groupId == _selectedGroupId,
      orElse: () => groups.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _groupName.dispose();
    _petName.dispose();
    _groupCode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final CommitmentGroupHub hub =
          await widget.repository.fetchCommitmentGroupHub();
      final List<PublicStudentProfile> friends = hub.group?.isOwner == true
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
        _feedback = 'Chưa tải được nhóm. Hãy kiểm tra kết nối rồi thử lại.';
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

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
              mc.space20, mc.space16, mc.space12, mc.space8),
          child: Row(
            children: <Widget>[
              Expanded(child: Text('Nhóm cam kết', style: mc.screenTitleStyle)),
              MindClockPressable(
                semanticLabel: 'Đóng',
                onPressed: () => Navigator.of(context).pop(),
                child: MindClockIcon(MindClockIconKind.minus, color: mc.ink),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? Center(
                  child: Text('Đang tải nhóm...', style: mc.bodyStrongStyle))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    key: const ValueKey<String>('commitment-group-content'),
                    padding: EdgeInsets.fromLTRB(
                        mc.space20, mc.space8, mc.space20, mc.space20),
                    children: <Widget>[
                      if (_feedback != null) ...<Widget>[
                        MindClockNoticeBanner(
                            message: _feedback!, isWarm: false),
                        SizedBox(height: mc.space12),
                      ],
                      if (_currentGroup == null)
                        _buildEmpty(mc)
                      else
                        _buildGroup(mc),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmpty(MindClockTheme mc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if ((_hub?.incomingInvites ?? const <CommitmentGroupInviteItem>[])
            .isNotEmpty) ...<Widget>[
          Text('Lời mời đang chờ', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          for (final CommitmentGroupInviteItem invite in _hub!.incomingInvites)
            Padding(
              padding: EdgeInsets.only(bottom: mc.space8),
              child: MindClockCard(
                highlighted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(invite.groupName, style: mc.bodyStrongStyle),
                    Text('${invite.inviterAlias} mời bạn tham gia.',
                        style: mc.captionStyle),
                    SizedBox(height: mc.space8),
                    Wrap(
                        spacing: mc.space8,
                        runSpacing: mc.space8,
                        children: <Widget>[
                          MindClockButton(
                            key: ValueKey<String>(
                                'commitment-accept-${invite.inviteId}'),
                            label: 'Tham gia',
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
                                              invite.inviteId, 'decline'),
                                      'Đã từ chối lời mời.',
                                    ),
                          ),
                        ]),
                  ],
                ),
              ),
            ),
          SizedBox(height: mc.space12),
        ],
        MindClockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Tạo nhóm riêng', style: mc.sectionTitleStyle),
              SizedBox(height: mc.space4),
              Text(
                  'Tối đa 4 người. Pet chỉ tiến triển từ phiên học hợp lệ của nhóm.',
                  style: mc.captionStyle),
              SizedBox(height: mc.space12),
              TextField(
                key: const ValueKey<String>('commitment-group-name'),
                controller: _groupName,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Tên nhóm'),
                textInputAction: TextInputAction.next,
                maxLength: 60,
              ),
              TextField(
                key: const ValueKey<String>('commitment-pet-name'),
                controller: _petName,
                decoration: const InputDecoration(labelText: 'Tên pet'),
                maxLength: 40,
              ),
              MindClockButton(
                key: const ValueKey<String>('commitment-create'),
                label: _saving ? 'Đang tạo...' : 'Tạo nhóm',
                icon: MindClockIconKind.plus,
                onPressed: _saving || _groupName.text.trim().length < 2
                    ? null
                    : () => _act(
                          () async {
                            await widget.repository.createCommitmentGroup(
                              name: _groupName.text.trim(),
                              petName: _petName.text.trim().isEmpty
                                  ? 'Mầm'
                                  : _petName.text.trim(),
                            );
                          },
                          'Đã tạo nhóm cam kết.',
                        ),
              ),
            ],
          ),
        ),
        SizedBox(height: mc.space12),
        MindClockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Xin vào bằng mã nhóm', style: mc.sectionTitleStyle),
              SizedBox(height: mc.space8),
              TextField(
                key: const ValueKey<String>('commitment-group-code'),
                controller: _groupCode,
                onChanged: (_) => setState(() {}),
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Mã 6 ký tự'),
                maxLength: 12,
              ),
              MindClockButton(
                key: const ValueKey<String>('commitment-request-join'),
                label: 'Gửi yêu cầu',
                variant: MindClockButtonVariant.secondary,
                onPressed: _saving || _groupCode.text.trim().length < 4
                    ? null
                    : () => _act(
                          () => widget.repository
                              .requestCommitmentJoin(_groupCode.text),
                          'Đã gửi yêu cầu tới trưởng nhóm.',
                        ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroup(MindClockTheme mc) {
    final CommitmentGroupDetail group = _currentGroup!;
    final CommitmentPetSummary pet = group.pet;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (_hub!.groups.length > 1) ...<Widget>[
          Text('Pet của bạn', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: _hub!.groups
                .map((CommitmentGroupDetail item) => MindClockButton(
                      key:
                          ValueKey<String>('commitment-select-${item.groupId}'),
                      label: item.name,
                      variant: item.groupId == group.groupId
                          ? MindClockButtonVariant.primary
                          : MindClockButtonVariant.secondary,
                      expand: false,
                      onPressed: () =>
                          setState(() => _selectedGroupId = item.groupId),
                    ))
                .toList(growable: false),
          ),
          SizedBox(height: mc.space12),
        ],
        MindClockCard(
          highlighted: true,
          child: Column(
            children: <Widget>[
              MamPetView(
                stage: pet.stage,
                reaction: pet.todayCareCount > 0
                    ? MamPetReaction.happy
                    : MamPetReaction.idle,
                size: 132,
              ),
              Text(pet.name, style: mc.screenTitleStyle),
              SizedBox(height: mc.space4),
              Text('${pet.stageLabelVi} · Giai đoạn ${pet.stage}/4',
                  style: mc.bodyStrongStyle),
              SizedBox(height: mc.space12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: <Widget>[
                  MindClockStatusPill(
                      label: pet.currentStreakDays > 0
                          ? '${pet.milestoneLabelVi} (${pet.currentStreakDays} ngày)'
                          : 'Chuỗi nhóm ${pet.currentStreakDays} ngày',
                      accentWarm: pet.currentStreakDays > 0),
                  MindClockStatusPill(
                      label:
                          'Hôm nay ${pet.todayCareCount}/${group.members.length} người',
                      accentWarm: !pet.allMembersDoneToday),
                  MindClockStatusPill(label: '${pet.totalCareDays} ngày đủ nhóm'),
                  MindClockStatusPill(
                      label: '${pet.totalXp}/${pet.nextStageXp} EXP nhóm'),
                ],
              ),
              SizedBox(height: mc.space8),
              Text(
                  'Cả nhóm cùng hoàn thành trong ngày (giải câu sáng, học >= 5 phút hoặc báo cáo ngày) để cộng +1 Chuỗi nhóm (Chuỗi 1 -> Chuỗi 100).',
                  textAlign: TextAlign.center,
                  style: mc.captionStyle),
            ],
          ),
        ),
        SizedBox(height: mc.space16),
        Row(children: <Widget>[
          Expanded(child: Text(group.name, style: mc.sectionTitleStyle)),
          MindClockStatusPill(label: 'Mã ${group.groupCode}'),
        ]),
        SizedBox(height: mc.space8),
        if (group.isPrimary)
          const MindClockNoticeBanner(
            message: 'Pet này đang hiển thị trên màn Hôm nay.',
            isWarm: false,
          )
        else
          MindClockButton(
            key: ValueKey<String>('commitment-primary-${group.groupId}'),
            label: 'Đưa pet này lên Hôm nay',
            icon: MindClockIconKind.sunrise,
            variant: MindClockButtonVariant.secondary,
            onPressed: _saving
                ? null
                : () => _act(() async {
                      await widget.repository
                          .setPrimaryCommitmentGroup(group.groupId);
                    }, 'Đã đổi pet trên màn Hôm nay.'),
          ),
        SizedBox(height: mc.space8),
        for (final CommitmentGroupMemberItem member in group.members)
          Padding(
            padding: EdgeInsets.only(bottom: mc.space8),
            child: MindClockCard(
              padding: EdgeInsets.all(mc.space12),
              child: Row(children: <Widget>[
                MindClockAvatarView(avatarId: member.avatarId, size: 44),
                SizedBox(width: mc.space12),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(member.alias, style: mc.bodyStrongStyle),
                    Text(member.role == 'owner' ? 'Trưởng nhóm' : 'Thành viên',
                        style: mc.captionStyle),
                  ],
                )),
                if (group.isOwner && member.role != 'owner')
                  MindClockButton(
                    key: ValueKey<String>('commitment-kick-${member.userId}'),
                    label: 'Mời ra',
                    icon: MindClockIconKind.minus,
                    variant: MindClockButtonVariant.subtle,
                    expand: false,
                    onPressed: _saving
                        ? null
                        : () => _act(
                              () async {
                                await widget.repository.removeCommitmentMember(
                                    group.groupId, member.userId);
                              },
                              'Đã cập nhật thành viên.',
                            ),
                  ),
              ]),
            ),
          ),
        if (group.isOwner) ...<Widget>[
          SizedBox(height: mc.space8),
          Text('Mời bạn đã kết bạn', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          if (_friends.isEmpty)
            Text('Chưa có bạn phù hợp để mời.', style: mc.captionStyle)
          else
            for (final PublicStudentProfile friend in _friends)
              if (!group.members.any((m) => m.userId == friend.userId))
                Padding(
                  padding: EdgeInsets.only(bottom: mc.space8),
                  child: MindClockButton(
                    key: ValueKey<String>('commitment-invite-${friend.userId}'),
                    label: 'Mời ${friend.alias}',
                    icon: MindClockIconKind.plus,
                    variant: MindClockButtonVariant.secondary,
                    onPressed: _saving
                        ? null
                        : () => _act(
                              () => widget.repository.inviteCommitmentFriend(
                                  group.groupId, friend.userId),
                              'Đã gửi lời mời.',
                            ),
                  ),
                ),
          if (group.pendingRequests.isNotEmpty) ...<Widget>[
            SizedBox(height: mc.space8),
            Text('Yêu cầu tham gia', style: mc.sectionTitleStyle),
            SizedBox(height: mc.space8),
            for (final CommitmentJoinRequestItem request
                in group.pendingRequests)
              Padding(
                padding: EdgeInsets.only(bottom: mc.space8),
                child: MindClockCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(request.alias, style: mc.bodyStrongStyle),
                      SizedBox(height: mc.space8),
                      Wrap(spacing: mc.space8, children: <Widget>[
                        MindClockButton(
                          label: 'Duyệt',
                          expand: false,
                          onPressed: _saving
                              ? null
                              : () => _act(
                                    () async {
                                      await widget.repository
                                          .respondCommitmentJoinRequest(
                                              group.groupId,
                                              request.requestId,
                                              'accept');
                                    },
                                    'Đã duyệt thành viên.',
                                  ),
                        ),
                        MindClockButton(
                          label: 'Từ chối',
                          expand: false,
                          variant: MindClockButtonVariant.subtle,
                          onPressed: _saving
                              ? null
                              : () => _act(
                                    () async {
                                      await widget.repository
                                          .respondCommitmentJoinRequest(
                                              group.groupId,
                                              request.requestId,
                                              'reject');
                                    },
                                    'Đã từ chối yêu cầu.',
                                  ),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
          ],
        ],
        SizedBox(height: mc.space16),
        if (_hub!.groups.length < _hub!.membershipLimit) ...<Widget>[
          MindClockButton(
            key: const ValueKey<String>('commitment-create-another'),
            label:
                'Tạo thêm nhóm (${_hub!.groups.length}/${_hub!.membershipLimit})',
            icon: MindClockIconKind.plus,
            variant: MindClockButtonVariant.secondary,
            onPressed: _saving ? null : _showCreateAnotherDialog,
          ),
          SizedBox(height: mc.space8),
        ],
        MindClockButton(
          key: const ValueKey<String>('commitment-leave-or-delete'),
          label: group.isOwner ? 'Xóa nhóm' : 'Rời nhóm',
          icon:
              group.isOwner ? MindClockIconKind.trash : MindClockIconKind.minus,
          variant: MindClockButtonVariant.subtle,
          onPressed: _saving
              ? null
              : () => _act(
                    () => group.isOwner
                        ? widget.repository.deleteCommitmentGroup(group.groupId)
                        : widget.repository.leaveCommitmentGroup(group.groupId),
                    group.isOwner ? 'Đã xóa nhóm.' : 'Đã rời nhóm.',
                  ),
        ),
      ],
    );
  }

  Future<void> _showCreateAnotherDialog() async {
    _groupName.clear();
    _petName.text = 'Mầm';
    final bool? accepted = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        final MindClockTheme dialogMc = dialogContext.mc;
        return Dialog(
          backgroundColor: dialogMc.paper,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(dialogMc.radiusCard)),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(dialogMc.space20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Tạo thêm nhóm', style: dialogMc.sectionTitleStyle),
                SizedBox(height: dialogMc.space12),
                TextField(
                  controller: _groupName,
                  decoration: const InputDecoration(labelText: 'Tên nhóm'),
                  maxLength: 60,
                ),
                TextField(
                  controller: _petName,
                  decoration: const InputDecoration(labelText: 'Tên pet'),
                  maxLength: 40,
                ),
                SizedBox(height: dialogMc.space8),
                MindClockButton(
                  label: 'Tạo nhóm',
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                ),
                SizedBox(height: dialogMc.space8),
                MindClockButton(
                  label: 'Hủy',
                  variant: MindClockButtonVariant.subtle,
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (accepted != true || _groupName.text.trim().length < 2) return;
    await _act(() async {
      final CommitmentGroupDetail created =
          await widget.repository.createCommitmentGroup(
        name: _groupName.text.trim(),
        petName: _petName.text.trim().isEmpty ? 'Mầm' : _petName.text.trim(),
      );
      _selectedGroupId = created.groupId;
    }, 'Đã tạo thêm nhóm.');
  }
}
