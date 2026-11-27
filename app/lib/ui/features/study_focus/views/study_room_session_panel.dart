import 'package:flutter/material.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../../domain/models/community_models.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../view_models/study_room_session_view_model.dart';
import 'study_community_sheet.dart';

class StudyRoomSessionPanel extends StatelessWidget {
  const StudyRoomSessionPanel(
      {super.key,
      required this.viewModel,
      required this.repository,
      this.animateAi = true});
  final StudyRoomSessionViewModel viewModel;
  final CommunityRepository repository;
  final bool animateAi;

  Future<void> _removeMember(
    BuildContext context,
    StudyRoomMemberTile member,
  ) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Mời thành viên ra?'),
            content: Text(
              '${member.alias} sẽ rời phòng và không thể tự vào lại phòng này.',
            ),
            actions: <Widget>[
              TextButton(
                key: const ValueKey<String>('room-remove-cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Giữ lại'),
              ),
              FilledButton(
                key: const ValueKey<String>('room-remove-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Mời ra'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await viewModel.removeMember(member.userId);
  }

  Future<void> _deleteRoom(BuildContext context) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Xóa phòng học?'),
            content: const Text(
              'Phòng và danh sách thành viên sẽ bị xóa. Đồng hồ học cá nhân vẫn tiếp tục.',
            ),
            actions: <Widget>[
              TextButton(
                key: const ValueKey<String>('room-delete-cancel'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Quay lại'),
              ),
              FilledButton(
                key: const ValueKey<String>('room-delete-confirm'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Xóa phòng'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await viewModel.deleteRoom();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final vm = viewModel;
        final room = vm.room;
        final mc = context.mc;
        if (room == null) return const SizedBox.shrink();
        final self = room.members.where((m) => m.isSelf).firstOrNull;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              repository.isDebugFixture
                  ? 'Phòng thử nghiệm'
                  : vm.syncedAt == null
                      ? 'Danh sách lúc vào phòng · Đang chờ cập nhật'
                      : 'Đã cập nhật danh sách thành viên',
              style: mc.captionStyle),
          Text('Phòng này chưa truyền cuộc gọi âm thanh/video.',
              style: mc.captionStyle),
          SizedBox(height: mc.space8),
          Wrap(spacing: mc.space8, runSpacing: mc.space8, children: [
            MindClockButton(
                key: const ValueKey('room-refresh'),
                label: vm.isBusy ? 'Đang cập nhật...' : 'Cập nhật phòng',
                expand: false,
                onPressed: vm.isBusy ? null : vm.refresh),
            if (vm.isHost)
              MindClockButton(
                  key: const ValueKey('room-open-settings'),
                  label: 'Cài đặt phòng',
                  variant: MindClockButtonVariant.secondary,
                  expand: false,
                  onPressed: vm.isMutating
                      ? null
                      : () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: mc.paper,
                          builder: (_) => RoomSettingsEditor(
                              viewModel: vm, initialSettings: room.summary))),
          ]),
          SizedBox(height: mc.space8),
          MeetStudyRoomGrid(
              room: room,
              repository: repository,
              animateAi: animateAi,
              controlsEnabled: !vm.isMutating,
              onToggleMic: () =>
                  vm.updateMedia(micEnabled: !(self?.micEnabled ?? false)),
              onToggleCam: () =>
                  vm.updateMedia(camEnabled: !(self?.camEnabled ?? false)),
              onToggleAi: vm.isHost
                  ? () => vm.updateMedia(
                      aiCompanionEnabled: !room.summary.aiCompanionEnabled)
                  : null,
              onRemoveMember:
                  vm.isHost ? (member) => _removeMember(context, member) : null,
              onDeleteRoom: vm.isHost ? () => _deleteRoom(context) : null,
              onLeaveRoom: vm.leave),
          if (vm.message != null) ...<Widget>[
            SizedBox(height: mc.space8),
            Text(vm.message!, style: mc.bodyStyle.copyWith(color: mc.error)),
          ],
        ]);
      });
}

class RoomSettingsEditor extends StatefulWidget {
  const RoomSettingsEditor(
      {super.key, required this.viewModel, required this.initialSettings});
  final StudyRoomSessionViewModel viewModel;
  final PublicStudyRoomSummary initialSettings;
  @override
  State<RoomSettingsEditor> createState() => _RoomSettingsEditorState();
}

class _RoomSettingsEditorState extends State<RoomSettingsEditor> {
  late final TextEditingController _title;
  late int _capacity;
  late String _visibility;
  late bool _ai;
  late final String _originalTitle;
  late final int _originalCapacity;
  late final String _originalVisibility;
  late final bool _originalAi;
  String? _error;
  @override
  void initState() {
    super.initState();
    final summary = widget.initialSettings;
    _originalTitle = summary.title;
    _originalCapacity = _capacity = summary.maxMembers;
    _originalVisibility = _visibility = summary.visibility;
    _originalAi = _ai = summary.aiCompanionEnabled;
    _title = TextEditingController(text: summary.title);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.length < 2 || title.length > 80) {
      setState(() => _error = 'Tên phòng cần từ 2 đến 80 ký tự.');
      return;
    }
    final changed = title != _originalTitle ||
        _capacity != _originalCapacity ||
        _visibility != _originalVisibility ||
        _ai != _originalAi;
    if (!changed) {
      Navigator.of(context).pop();
      return;
    }
    final saved = await widget.viewModel.saveSettings(
        title: title == _originalTitle ? null : title,
        maxMembers: _capacity == _originalCapacity ? null : _capacity,
        visibility: _visibility == _originalVisibility ? null : _visibility,
        aiCompanionEnabled: _ai == _originalAi ? null : _ai);
    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
    } else {
      setState(() =>
          _error = widget.viewModel.message ?? 'Chưa lưu được cài đặt phòng.');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final mc = context.mc;
        final vm = widget.viewModel;
        final count = vm.room?.members.length ?? 0;
        return SafeArea(
            child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(mc.space20, mc.space20, mc.space20,
                    mc.space20 + MediaQuery.viewInsetsOf(context).bottom),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Cài đặt phòng', style: mc.sectionTitleStyle),
                      if (vm.room == null)
                        Text('Phòng đã đóng hoặc bạn không còn quyền truy cập.',
                            style: mc.bodyStyle),
                      SizedBox(height: mc.space12),
                      TextField(
                          key: const ValueKey('room-settings-title'),
                          controller: _title,
                          decoration:
                              const InputDecoration(labelText: 'Tên phòng')),
                      SizedBox(height: mc.space12),
                      Text('Giới hạn người · Hiện có $count người',
                          style: mc.bodyStrongStyle),
                      Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space8,
                          children: [
                            for (final value in [2, 3, 4, 5, 6, 7, 8])
                              MindClockPressable(
                                  key:
                                      ValueKey('room-settings-capacity-$value'),
                                  selected: _capacity == value,
                                  semanticLabel: '$value người',
                                  onPressed: value < count || vm.isMutating
                                      ? null
                                      : () => setState(() => _capacity = value),
                                  child: MindClockStatusPill(
                                      label: '$value',
                                      accentWarm: _capacity == value)),
                          ]),
                      SizedBox(height: mc.space12),
                      Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space8,
                          children: [
                            for (final value in ['public', 'invite_only'])
                              MindClockPressable(
                                  key: ValueKey('room-settings-$value'),
                                  selected: _visibility == value,
                                  onPressed: vm.isMutating
                                      ? null
                                      : () =>
                                          setState(() => _visibility = value),
                                  child: MindClockStatusPill(
                                      label: value == 'public'
                                          ? 'Công khai'
                                          : 'Chỉ mời',
                                      accentWarm: _visibility == value)),
                            MindClockPressable(
                                key: const ValueKey('room-settings-ai'),
                                selected: _ai,
                                onPressed: vm.isMutating
                                    ? null
                                    : () => setState(() => _ai = !_ai),
                                child: MindClockStatusPill(
                                    label: _ai ? 'Có AI' : 'Không dùng AI',
                                    accentWarm: _ai)),
                          ]),
                      SizedBox(height: mc.space8),
                      Text('Đổi sang chỉ mời vẫn giữ người đang trong phòng.',
                          style: mc.captionStyle),
                      if (_error != null)
                        Text(_error!,
                            style: mc.bodyStyle.copyWith(color: mc.error)),
                      SizedBox(height: mc.space12),
                      MindClockButton(
                          key: const ValueKey('room-settings-save'),
                          label: vm.isMutating ? 'Đang lưu...' : 'Lưu cài đặt',
                          onPressed:
                              vm.isMutating || !vm.isHost ? null : _save),
                      SizedBox(height: mc.space8),
                      MindClockButton(
                          label: 'Đóng',
                          variant: MindClockButtonVariant.subtle,
                          onPressed: () => Navigator.of(context).pop()),
                    ])));
      });
}
