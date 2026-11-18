import 'package:flutter/widgets.dart';

import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../personal_flow/view_models/personal_flow_view_model.dart';
import '../../personal_flow/views/account_auth_card.dart';
import '../view_models/guest_workspace_view_model.dart';

/// Tab Tôi cho chế độ khách local & tùy chọn đăng nhập online (không có Đấu trường).
class MeGuestScreen extends StatefulWidget {
  const MeGuestScreen({
    super.key,
    required this.viewModel,
    required this.onEditProfileAndTimetable,
    required this.onResetGuestData,
    this.personalViewModel,
    this.onDeleteAccount,
  });

  final GuestWorkspaceViewModel viewModel;
  final PersonalFlowViewModel? personalViewModel;
  final VoidCallback onEditProfileAndTimetable;
  final VoidCallback onResetGuestData;
  final Future<void> Function()? onDeleteAccount;

  @override
  State<MeGuestScreen> createState() => _MeGuestScreenState();
}

class _MeGuestScreenState extends State<MeGuestScreen> {
  bool _confirmingDeleteAccount = false;
  bool _deletingAccount = false;

  GuestWorkspaceViewModel get viewModel => widget.viewModel;
  PersonalFlowViewModel? get personalViewModel => widget.personalViewModel;
  VoidCallback get onEditProfileAndTimetable => widget.onEditProfileAndTimetable;
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
          MindClockStatusPill(
            label: viewModel.profile.alias.isNotEmpty
                ? '${viewModel.profile.alias} · ${viewModel.profile.gradeLevel ?? "Lớp 11"}'
                : 'Học sinh THPT',
            accentWarm: true,
          ),
          if (personalViewModel != null) ...<Widget>[
            SizedBox(height: mc.space16),
            AccountAuthCard(viewModel: personalViewModel!),
          ],
          SizedBox(height: mc.space16),
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Trạng thái dịch vụ báo thức', style: mc.sectionTitleStyle),
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
                        onPressed: () => viewModel.openPermissionSettings(action),
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
                          : () => setState(() => _confirmingDeleteAccount = false),
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
