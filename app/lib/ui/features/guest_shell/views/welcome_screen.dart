import 'package:flutter/widgets.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';

/// Màn hình `S01` Chào mừng MindClock.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onStartAuth,
    this.onAlarmOnly,
  });

  final VoidCallback onStartAuth;
  final VoidCallback? onAlarmOnly;

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
              const MindClockNoticeBanner(
                key: ValueKey<String>('welcome-no-guest-notice'),
                message:
                    'Đăng ký hoặc đăng nhập để lưu lịch học, báo thức và tiến độ ôn tập của bạn.',
                isWarm: false,
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
                      'Thông báo, báo thức, camera và micro chỉ được hỏi khi bạn chủ động sử dụng.',
                      style: mc.captionStyle.copyWith(color: mc.ink),
                    ),
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
