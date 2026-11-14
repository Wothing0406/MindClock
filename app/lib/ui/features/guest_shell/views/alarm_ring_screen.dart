import 'package:flutter/widgets.dart';

import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';

/// Màn hình `S07` chuông đang reo nền đêm trên Flutter (khớp trạng thái với `AlarmRingActivity`).
///
/// Quy tắc:
/// - Nền đêm `mc.night`, giờ cỡ lớn `mc.alarmHeroStyle`.
/// - `Dừng khẩn cấp` luôn hiện ở mọi chế độ.
/// - `Hoãn 5 phút` CHỈ hiện ở `AlarmMode.normal`; ẩn hoàn toàn ở `AlarmMode.challenge`.
class AlarmRingScreen extends StatelessWidget {
  const AlarmRingScreen({
    super.key,
    required this.payload,
    required this.onOpenQuestion,
    required this.onEmergencyStop,
    this.onSnooze5Min,
  });

  final AlarmRingPayload payload;
  final VoidCallback onOpenQuestion;
  final VoidCallback onEmergencyStop;
  final VoidCallback? onSnooze5Min;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final bool isChallenge = payload.mode == AlarmMode.challenge;
    final String? subjectCode = payload.subjectCode;
    final String subtitle = subjectCode != null && subjectCode.isNotEmpty
        ? '${payload.label} · ${SubjectCatalog.nameFor(subjectCode)}'
        : payload.label;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: mc.night,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mc.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: mc.space16),
              MindClockStatusPill(
                label: isChallenge
                    ? AppStrings.challengeModeTitle
                    : AppStrings.normalModeTitle,
                accentWarm: isChallenge,
              ),
              SizedBox(height: mc.space24),
              Text(
                payload.formattedTime,
                key: const ValueKey<String>('ring-screen-time'),
                style: mc.alarmHeroStyle,
              ),
              SizedBox(height: mc.space12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: mc.sectionTitleStyle.copyWith(color: mc.nightText),
              ),
              SizedBox(height: mc.space8),
              Text(
                isChallenge
                    ? AppStrings.ringChallengeHint
                    : AppStrings.ringNormalHint,
                textAlign: TextAlign.center,
                style: mc.captionStyle.copyWith(color: mc.sunrise),
              ),
              SizedBox(height: mc.space32),
              MindClockButton(
                key: const ValueKey<String>('ring-open-question'),
                label: AppStrings.ringOpenQuestion,
                icon: MindClockIconKind.book,
                onPressed: onOpenQuestion,
              ),
              if (!isChallenge && onSnooze5Min != null) ...<Widget>[
                SizedBox(height: mc.space12),
                MindClockButton(
                  key: const ValueKey<String>('ring-snooze-5m'),
                  label: AppStrings.ringSnooze5m,
                  icon: MindClockIconKind.clock,
                  variant: MindClockButtonVariant.secondary,
                  onPressed: onSnooze5Min,
                ),
              ],
              SizedBox(height: mc.space16),
              MindClockButton(
                key: const ValueKey<String>('ring-emergency-stop'),
                label: AppStrings.ringEmergencyStop,
                icon: MindClockIconKind.warning,
                variant: MindClockButtonVariant.subtle,
                onPressed: onEmergencyStop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
