import 'package:flutter/widgets.dart';

import '../../../../data/debug/debug_fixture_community_repository.dart';
import '../../../../data/services/method_channel_media_picker_gateway.dart';
import '../../../../domain/models/community_models.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../../domain/services/media_picker_gateway.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_avatar_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../personal_flow/view_models/personal_flow_view_model.dart';
import '../../personal_flow/views/account_auth_card.dart';
import '../../personal_flow/views/profile_progress_card.dart';
import '../../community/views/commitment_group_sheet.dart';
import '../../study_focus/views/study_community_sheet.dart';
import '../view_models/guest_workspace_view_model.dart';

/// Tab Tôi: Hồ sơ học sinh, cộng đồng bạn học, đồng bộ tài khoản & quyền báo thức OS.
class MeGuestScreen extends StatefulWidget {
  const MeGuestScreen({
    super.key,
    required this.viewModel,
    required this.onEditProfileAndTimetable,
    required this.onResetGuestData,
    this.personalViewModel,
    this.communityRepository,
    this.mediaPickerGateway,
    this.onDeleteAccount,
    this.onRoomJoined,
  });

  final GuestWorkspaceViewModel viewModel;
  final PersonalFlowViewModel? personalViewModel;
  final CommunityRepository? communityRepository;
  final MediaPickerGateway? mediaPickerGateway;
  final VoidCallback onEditProfileAndTimetable;
  final VoidCallback onResetGuestData;
  final Future<void> Function()? onDeleteAccount;
  final ValueChanged<StudyRoomDetail>? onRoomJoined;

  @override
  State<MeGuestScreen> createState() => _MeGuestScreenState();
}

class _MeGuestScreenState extends State<MeGuestScreen> {
  bool _confirmingDeleteAccount = false;
  bool _deletingAccount = false;
  bool _pickingAvatar = false;
  String? _avatarFeedbackVi;

  Future<void> _pickAvatarFromDevice() async {
    if (_pickingAvatar) return;
    setState(() {
      _pickingAvatar = true;
      _avatarFeedbackVi = null;
    });
    final MediaPickerGateway gateway =
        widget.mediaPickerGateway ?? MethodChannelMediaPickerGateway();
    final MediaPickResult res = await gateway.pickAvatarImage();
    if (!mounted) return;
    if (res.picked && res.localPath != null) {
      final StudyProfile next = viewModel.profile.copyWith(
        customAvatarPath: res.localPath,
      );
      await viewModel.saveStudyProfile(next);
      if (!mounted) return;
      setState(() {
        _pickingAvatar = false;
        _avatarFeedbackVi = 'Đã cập nhật ảnh đại diện từ máy (lưu cục bộ).';
      });
      return;
    }
    setState(() {
      _pickingAvatar = false;
      if (!res.cancelled && res.errorMessageVi != null) {
        _avatarFeedbackVi = res.errorMessageVi;
      }
    });
  }

  Future<void> _clearCustomAvatar() async {
    final StudyProfile next = viewModel.profile.copyWith(
      clearCustomAvatarPath: true,
    );
    await viewModel.saveStudyProfile(next);
    if (!mounted) return;
    setState(() {
      _avatarFeedbackVi = 'Đã chuyển về avatar minh họa MindClock.';
    });
  }

  GuestWorkspaceViewModel get viewModel => widget.viewModel;
  PersonalFlowViewModel? get personalViewModel => widget.personalViewModel;
  VoidCallback get onEditProfileAndTimetable =>
      widget.onEditProfileAndTimetable;
  VoidCallback get onResetGuestData => widget.onResetGuestData;

  String _permissionLabel(OsPermissionState state) {
    switch (state) {
      case OsPermissionState.granted:
        return 'Đã cấp';
      case OsPermissionState.denied:
        return 'Chưa cấp';
      case OsPermissionState.unknown:
        return 'Chưa kiểm tra (chưa nối OS)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final AlarmPermissionSnapshot perms = viewModel.permissionSnapshot;

    return SingleChildScrollView(
      padding: EdgeInsets.all(mc.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AppStrings.navMe, style: mc.screenTitleStyle),
          SizedBox(height: mc.space12),
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    MindClockAvatarView(
                      avatarId: viewModel.profile.avatarId,
                      customAvatarPath: viewModel.profile.customAvatarPath,
                      size: 56,
                      selected: true,
                    ),
                    SizedBox(width: mc.space12),
                    Expanded(
                      child: MindClockStatusPill(
                        label: viewModel.profile.alias.isNotEmpty
                            ? '${viewModel.profile.alias} · ${viewModel.profile.gradeLevel ?? "Lớp 11"}'
                            : 'Học sinh THPT',
                        accentWarm: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: <Widget>[
                    MindClockButton(
                      key: const ValueKey<String>('me-open-commitment-group'),
                      label: 'Nhóm cam kết & Pet Mầm',
                      icon: MindClockIconKind.shield,
                      expand: false,
                      onPressed: () => showCommitmentGroupSheet(
                        context: context,
                        repository: widget.communityRepository ??
                            DebugFixtureCommunityRepository(),
                      ),
                    ),
                    MindClockButton(
                      key: const ValueKey<String>('me-pick-avatar-btn'),
                      label: _pickingAvatar
                          ? 'Đang mở thư viện...'
                          : 'Đổi ảnh đại diện từ máy',
                      icon: MindClockIconKind.edit,
                      variant: MindClockButtonVariant.secondary,
                      expand: false,
                      onPressed: _pickingAvatar ? null : _pickAvatarFromDevice,
                    ),
                    if (viewModel.profile.customAvatarPath != null)
                      MindClockButton(
                        key: const ValueKey<String>('me-clear-avatar-btn'),
                        label: 'Dùng avatar mặc định',
                        icon: MindClockIconKind.trash,
                        variant: MindClockButtonVariant.subtle,
                        expand: false,
                        onPressed: _clearCustomAvatar,
                      ),
                  ],
                ),
                if (_avatarFeedbackVi != null) ...<Widget>[
                  SizedBox(height: mc.space8),
                  Text(_avatarFeedbackVi!, style: mc.captionStyle),
                ],
              ],
            ),
          ),
          if (personalViewModel != null) ...<Widget>[
            SizedBox(height: mc.space16),
            AccountAuthCard(viewModel: personalViewModel!),
            SizedBox(height: mc.space16),
            ProfileProgressCard(viewModel: personalViewModel!),
          ],
          SizedBox(height: mc.space16),
          MindClockCard(
            key: const ValueKey<String>('me-community-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bạn học, Kết bạn & Hồ sơ công khai',
                  style: mc.sectionTitleStyle,
                ),
                SizedBox(height: mc.space4),
                Text(
                  'Tìm bạn cùng khối/môn, xem hồ sơ công khai, gửi lời mời kết bạn hoặc quét phòng học Meet. Giờ dậy, TKB chi tiết và email luôn ẩn.',
                  style: mc.captionStyle,
                ),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: <Widget>[
                    MindClockButton(
                      key: const ValueKey<String>('me-open-community-hub'),
                      label: 'Tìm bạn & Phòng học Meet',
                      icon: MindClockIconKind.user,
                      expand: false,
                      onPressed: () async {
                        final owner =
                            personalViewModel?.authSession.ownerScopeKey;
                        final CommunityRepository repo =
                            widget.communityRepository ??
                                DebugFixtureCommunityRepository();
                        final room = await showStudyCommunityHub(
                          context: context,
                          repository: repo,
                          currentProfile: viewModel.profile,
                        );
                        if (room != null &&
                            mounted &&
                            owner ==
                                personalViewModel?.authSession.ownerScopeKey) {
                          widget.onRoomJoined?.call(room);
                        }
                      },
                    ),
                    MindClockButton(
                      key: const ValueKey<String>('me-preview-public-profile'),
                      label: 'Xem thử hồ sơ công khai',
                      icon: MindClockIconKind.info,
                      variant: MindClockButtonVariant.secondary,
                      expand: false,
                      onPressed: () {
                        final CommunityRepository repo =
                            widget.communityRepository ??
                                DebugFixtureCommunityRepository();
                        showPublicStudentProfileDialog(
                          context: context,
                          profile: PublicStudentProfile(
                            userId: 'self',
                            alias: viewModel.profile.alias.isNotEmpty
                                ? viewModel.profile.alias
                                : 'Học sinh MindClock',
                            avatarId: viewModel.profile.avatarId,
                            gradeLevel:
                                viewModel.profile.gradeLevel ?? 'Lớp 11',
                            selectedSubjects:
                                viewModel.profile.selectedSubjectCodes,
                            goalLabel: viewModel.profile.goalLabel,
                            studyLevel: 'exam_prep',
                            studyLevelLabelVi: 'Đang ôn thi',
                            friendStatus: 'self',
                          ),
                          repository: repo,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: mc.space16),
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Trạng thái dịch vụ báo thức',
                    style: mc.sectionTitleStyle),
                SizedBox(height: mc.space8),
                Text(
                  viewModel.isOsBridgeConnected
                      ? 'Báo thức đã sẵn sàng.'
                      : 'Đang sử dụng chế độ báo thức tiêu chuẩn trên máy.',
                  style: mc.bodyStrongStyle,
                ),
                SizedBox(height: mc.space8),
                Text(
                  'Quyền báo thức chính xác: ${_permissionLabel(perms.exactAlarm)}',
                  style: mc.captionStyle,
                ),
                Text(
                  'Quyền thông báo: ${_permissionLabel(perms.notifications)}',
                  style: mc.captionStyle,
                ),
                Text(
                  'Quyền màn hình khóa: ${_permissionLabel(perms.fullScreenIntent)}',
                  style: mc.captionStyle,
                ),
                SizedBox(height: mc.space12),
                if (!viewModel.isOsBridgeConnected)
                  const MindClockNoticeBanner(
                    message: AppStrings.alarmOsUnboundExplain,
                    isWarm: false,
                  )
                else if (viewModel.needsOsPermissions) ...<Widget>[
                  const MindClockNoticeBanner(
                    message: AppStrings.alarmPermissionMissingExplain,
                  ),
                  SizedBox(height: mc.space12),
                  ...viewModel.missingPermissionActions.map(
                    (AlarmPermissionAction action) => Padding(
                      padding: EdgeInsets.only(bottom: mc.space8),
                      child: MindClockButton(
                        key: ValueKey<String>('me-perm-${action.wireAction}'),
                        label: viewModel.labelForPermissionAction(action),
                        icon: MindClockIconKind.warning,
                        variant: MindClockButtonVariant.secondary,
                        onPressed: () =>
                            viewModel.openPermissionSettings(action),
                      ),
                    ),
                  ),
                ] else
                  const MindClockNoticeBanner(
                    message:
                        'Android đã cấp đủ quyền cốt lõi (Exact Alarm, Thông báo, Toàn màn hình khóa).',
                    isWarm: false,
                  ),
                if (viewModel.isOsBridgeConnected) ...<Widget>[
                  SizedBox(height: mc.space8),
                  Text(
                    AppStrings.batteryOptimizationNote,
                    style: mc.captionStyle,
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('me-perm-battery'),
                    label: viewModel.labelForPermissionAction(
                      AlarmPermissionAction.batteryOptimizationSettings,
                    ),
                    icon: MindClockIconKind.clock,
                    variant: MindClockButtonVariant.subtle,
                    onPressed: () => viewModel.openPermissionSettings(
                      AlarmPermissionAction.batteryOptimizationSettings,
                    ),
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('me-refresh-os-status'),
                    label: 'Kiểm tra lại quyền báo thức OS',
                    icon: MindClockIconKind.check,
                    variant: MindClockButtonVariant.subtle,
                    onPressed: viewModel.refreshOsStatus,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: mc.space16),
          MindClockButton(
            key: const ValueKey<String>('me-edit-profile'),
            label: 'Chỉnh hồ sơ & Thời khóa biểu 7 ngày',
            icon: MindClockIconKind.edit,
            variant: MindClockButtonVariant.secondary,
            onPressed: onEditProfileAndTimetable,
          ),
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('me-reset-local'),
            label: 'Thiết lập lại dữ liệu ứng dụng',
            icon: MindClockIconKind.trash,
            variant: MindClockButtonVariant.subtle,
            onPressed: onResetGuestData,
          ),
          if (personalViewModel != null &&
              personalViewModel!.authSession.isAuthenticated &&
              widget.onDeleteAccount != null) ...<Widget>[
            SizedBox(height: mc.space16),
            if (!_confirmingDeleteAccount)
              MindClockButton(
                key: const ValueKey<String>('me-delete-account-btn'),
                label: 'Xóa tài khoản & dữ liệu trực tuyến',
                icon: MindClockIconKind.trash,
                variant: MindClockButtonVariant.subtle,
                onPressed: _deletingAccount
                    ? null
                    : () => setState(() => _confirmingDeleteAccount = true),
              )
            else
              MindClockCard(
                key: const ValueKey<String>('me-delete-account-confirm-card'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Xác nhận xóa tài khoản trực tuyến?',
                      style: mc.sectionTitleStyle,
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      'Hành động này xóa tài khoản, hồ sơ và lịch học đã đồng bộ trên máy chủ. Báo thức đã lưu trên thiết bị vẫn được giữ nguyên.',
                      style: mc.captionStyle,
                    ),
                    SizedBox(height: mc.space12),
                    MindClockButton(
                      key: const ValueKey<String>('me-delete-account-confirm'),
                      label: _deletingAccount
                          ? 'Đang xóa tài khoản...'
                          : 'Xác nhận xóa tài khoản',
                      icon: MindClockIconKind.trash,
                      variant: MindClockButtonVariant.primary,
                      onPressed: _deletingAccount
                          ? null
                          : () async {
                              setState(() => _deletingAccount = true);
                              try {
                                await widget.onDeleteAccount!();
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _deletingAccount = false;
                                    _confirmingDeleteAccount = false;
                                  });
                                }
                              }
                            },
                    ),
                    SizedBox(height: mc.space8),
                    MindClockButton(
                      key: const ValueKey<String>('me-delete-account-cancel'),
                      label: 'Giữ lại tài khoản',
                      icon: MindClockIconKind.check,
                      variant: MindClockButtonVariant.subtle,
                      onPressed: _deletingAccount
                          ? null
                          : () =>
                              setState(() => _confirmingDeleteAccount = false),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
