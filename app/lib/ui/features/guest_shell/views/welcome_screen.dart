import 'package:flutter/widgets.dart';

import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';

/// Màn hình `S01` Chào mừng cho người dùng khách (không ép đăng nhập).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onStartGuestSetup,
    required this.onSkipLater,
    required this.onAlarmOnly,
  });

  final VoidCallback onStartGuestSetup;
  final VoidCallback onSkipLater;
  final VoidCallback onAlarmOnly;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return DecoratedBox(
      decoration: BoxDecoration(color: mc.paper),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mc.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const MindClockStatusPill(label: AppStrings.guestBadge),
              SizedBox(height: mc.space24),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(mc.space20),
                decoration: BoxDecoration(
                  color: mc.night,
                  borderRadius: BorderRadius.circular(mc.radiusPaper),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    MindClockIcon(
                      MindClockIconKind.sunrise,
                      color: mc.sunrise,
                      size: 32,
                    ),
                    SizedBox(height: mc.space12),
                    Text(
                      AppStrings.appName,
                      style: mc.sectionTitleStyle.copyWith(color: mc.sunrise),
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      AppStrings.welcomeTitle,
                      style: mc.screenTitleStyle.copyWith(color: mc.nightText),
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      AppStrings.welcomeSubtitle,
                      style: mc.bodyStyle.copyWith(color: mc.nightText),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space20),
              const MindClockNoticeBanner(
                message: AppStrings.guestPrivacyNote,
                isWarm: false,
              ),
              SizedBox(height: mc.space24),
              MindClockButton(
                key: const ValueKey<String>('guest-start-setup'),
                label: AppStrings.tryGuestCta,
                icon: MindClockIconKind.book,
                onPressed: onStartGuestSetup,
              ),
              SizedBox(height: mc.space12),
              MindClockButton(
                key: const ValueKey<String>('guest-alarm-only'),
                label: AppStrings.alarmOnlyCta,
                icon: MindClockIconKind.bell,
                variant: MindClockButtonVariant.secondary,
                onPressed: onAlarmOnly,
              ),
              SizedBox(height: mc.space12),
              MindClockButton(
                key: const ValueKey<String>('guest-skip-later'),
                label: AppStrings.setupLaterCta,
                variant: MindClockButtonVariant.subtle,
                onPressed: onSkipLater,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
