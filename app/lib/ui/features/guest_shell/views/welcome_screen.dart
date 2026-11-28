import 'package:flutter/widgets.dart';

import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../view_models/guest_workspace_view_model.dart';

/// Màn hình `S01` Chào mừng MindClock.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onStartAuth,
    this.onAlarmOnly,
    this.workspaceViewModel,
  });

  final VoidCallback onStartAuth;
  final VoidCallback? onAlarmOnly;
  final GuestWorkspaceViewModel? workspaceViewModel;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return DecoratedBox(
      decoration: BoxDecoration(color: mc.paper),
      child: SafeArea(
        child: SingleChildScrollView(
          padding:
              EdgeInsets.symmetric(horizontal: mc.space16, vertical: mc.space8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const MindClockStatusPill(label: 'Ứng dụng học tập THPT'),
              SizedBox(height: mc.space8),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(mc.space16),
                decoration: BoxDecoration(
                  color: mc.surface,
                  borderRadius: BorderRadius.circular(mc.radiusPaper),
                  border: Border.all(color: mc.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MindClockIcon(
                      MindClockIconKind.sunrise,
                      color: mc.primary,
                      size: 28,
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      AppStrings.appName,
                      style: mc.sectionTitleStyle.copyWith(color: mc.primary),
                    ),
                    SizedBox(height: mc.space4),
                    Text(
                      'Dậy đúng giờ. Nghĩ bằng chính mình.',
                      style: mc.screenTitleStyle.copyWith(color: mc.ink),
                    ),
                    SizedBox(height: mc.space4),
                    Text(
                      'Báo thức kỷ luật, câu hỏi ôn tập theo môn mỗi sáng và không gian học tập trung cùng AI.',
                      style: mc.bodyStyle.copyWith(color: mc.inkMuted),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space12),
              MindClockButton(
                key: const ValueKey<String>('welcome-auth-start'),
                label: 'Bắt đầu ngay (Đăng ký / Đăng nhập)',
                icon: MindClockIconKind.user,
                onPressed: onStartAuth,
              ),
              SizedBox(height: mc.space12),
              Container(
                key: const ValueKey<String>('welcome-permission-guide'),
                width: double.infinity,
                padding: EdgeInsets.all(mc.space12),
                decoration: BoxDecoration(
                  color: mc.surface,
                  borderRadius: BorderRadius.circular(mc.radiusControl),
                  border: Border.all(color: mc.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Quyền ứng dụng',
                      style: mc.bodyStrongStyle,
                    ),
                    SizedBox(height: mc.space4),
                    Text(
                      (workspaceViewModel != null &&
                              workspaceViewModel!.needsOsPermissions)
                          ? 'Cần cấp quyền thông báo & báo thức ngay để chuông reo đúng giờ.'
                          : (workspaceViewModel != null &&
                                  workspaceViewModel!.isOsBridgeConnected)
                              ? 'Đã cấp đủ quyền báo thức và thông báo.'
                              : 'Cấp quyền thông báo & báo thức để chuông hoạt động ổn định.',
                      style: mc.captionStyle.copyWith(color: mc.ink),
                    ),
                    if (workspaceViewModel != null &&
                        workspaceViewModel!.needsOsPermissions &&
                        workspaceViewModel!
                            .missingPermissionActions.isNotEmpty) ...<Widget>[
                      SizedBox(height: mc.space8),
                      Wrap(
                        spacing: mc.space8,
                        runSpacing: mc.space8,
                        children: workspaceViewModel!.missingPermissionActions
                            .map(
                              (AlarmPermissionAction action) => MindClockButton(
                                key: ValueKey<String>(
                                  'welcome-perm-${action.wireAction}',
                                ),
                                label: workspaceViewModel!
                                    .labelForPermissionAction(action),
                                icon: MindClockIconKind.bell,
                                variant: MindClockButtonVariant.secondary,
                                expand: false,
                                onPressed: () => workspaceViewModel!
                                    .openPermissionSettings(action),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
