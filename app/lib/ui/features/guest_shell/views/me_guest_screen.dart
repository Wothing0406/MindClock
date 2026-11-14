import 'package:flutter/widgets.dart';

import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../view_models/guest_workspace_view_model.dart';

/// Tab Tôi cho chế độ khách local (không có Đấu trường, không ép đăng nhập).
class MeGuestScreen extends StatelessWidget {
  const MeGuestScreen({
    super.key,
    required this.viewModel,
    required this.onEditProfileAndTimetable,
    required this.onResetGuestData,
  });

  final GuestWorkspaceViewModel viewModel;
  final VoidCallback onEditProfileAndTimetable;
  final VoidCallback onResetGuestData;

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
          const MindClockStatusPill(label: AppStrings.guestBadge),
          SizedBox(height: mc.space16),
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Trạng thái dịch vụ báo thức', style: mc.sectionTitleStyle),
                SizedBox(height: mc.space8),
                Text(
                  viewModel.isOsBridgeConnected
                      ? 'Đã nối dịch vụ báo thức hệ điều hành Android.'
                      : 'Chưa nối OS native (đang dùng giao diện lưu cấu hình cục bộ).',
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
            label: 'Xóa dữ liệu khách trên máy & bắt đầu lại',
            icon: MindClockIconKind.trash,
            variant: MindClockButtonVariant.subtle,
            onPressed: onResetGuestData,
          ),
        ],
      ),
    );
  }
}
