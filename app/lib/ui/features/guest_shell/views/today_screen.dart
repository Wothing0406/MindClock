import 'package:flutter/widgets.dart';

import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/study_focus_models.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/models/timetable.dart';
import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../study_focus/view_models/study_focus_view_model.dart';
import '../view_models/guest_workspace_view_model.dart';

/// Màn hình `S04` Hôm nay (khách local, không có Đấu trường).
class TodayScreen extends StatelessWidget {
  const TodayScreen({
    super.key,
    required this.viewModel,
    required this.onCreateAlarm,
    required this.onEditAlarm,
    required this.onOpenTimetableAndProfile,
    this.studyViewModel,
    this.onOpenStudySpace,
    this.lastActionBanner,
  });

  final GuestWorkspaceViewModel viewModel;
  final VoidCallback onCreateAlarm;
  final ValueChanged<AlarmConfig> onEditAlarm;
  final VoidCallback onOpenTimetableAndProfile;
  final StudyFocusViewModel? studyViewModel;
  final VoidCallback? onOpenStudySpace;
  final String? lastActionBanner;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final StudyProfile profile = viewModel.profile;
    final List<AlarmConfig> alarms = viewModel.alarms;

    final int todayWeekday = DateTime.now().weekday;
    final DaySchedule todaySchedule = viewModel.timetable.dayFor(todayWeekday);

    return SingleChildScrollView(
      padding: EdgeInsets.all(mc.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(AppStrings.navToday, style: mc.screenTitleStyle),
              const MindClockStatusPill(label: AppStrings.guestBadge),
            ],
          ),
          if (lastActionBanner != null) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockNoticeBanner(message: lastActionBanner!, isWarm: false),
          ],
          if (viewModel.needsOsPermissions) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const MindClockNoticeBanner(
                    message: AppStrings.alarmPermissionMissingExplain,
                  ),
                  if (viewModel.missingPermissionActions.isNotEmpty) ...<Widget>[
                    SizedBox(height: mc.space12),
                    ...viewModel.missingPermissionActions.map(
                      (AlarmPermissionAction action) => Padding(
                        padding: EdgeInsets.only(bottom: mc.space8),
                        child: MindClockButton(
                          key: ValueKey<String>(
                            'today-perm-${action.wireAction}',
                          ),
                          label: viewModel.labelForPermissionAction(action),
                          icon: MindClockIconKind.warning,
                          variant: MindClockButtonVariant.secondary,
                          onPressed: () =>
                              viewModel.openPermissionSettings(action),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (viewModel.scheduleChangedSinceAlarmSave &&
              alarms.isNotEmpty) ...<Widget>[
            SizedBox(height: mc.space12),
            const MindClockNoticeBanner(
              message: AppStrings.wakeScheduleChangedNotice,
            ),
          ],
          SizedBox(height: mc.space16),
          if (alarms.isEmpty)
            MindClockCard(
              highlighted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Chưa có báo thức nào', style: mc.sectionTitleStyle),
                  SizedBox(height: mc.space8),
                  Text(
                    'Đặt giờ báo thức local và xem phép tính gợi ý giờ dậy theo lịch học.',
                    style: mc.bodyStyle,
                  ),
                  SizedBox(height: mc.space12),
                  MindClockButton(
                    key: const ValueKey<String>('today-add-first-alarm'),
                    label: 'Đặt báo thức đầu tiên',
                    icon: MindClockIconKind.bell,
                    onPressed: onCreateAlarm,
                  ),
                ],
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...alarms.map((AlarmConfig alarm) {
                  final String statusText =
                      viewModel.statusLabelForAlarm(alarm);
                  final String repeatText = alarm.repeatWeekdays.isEmpty
                      ? 'Một lần'
                      : alarm.repeatWeekdays
                          .map(WeeklyTimetable.shortWeekdayLabel)
                          .join(', ');
                  return Padding(
                    padding: EdgeInsets.only(bottom: mc.space12),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(mc.space16),
                      decoration: BoxDecoration(
                        color: mc.night,
                        borderRadius: BorderRadius.circular(mc.radiusCard),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Wrap(
                            spacing: mc.space8,
                            runSpacing: mc.space8,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              Text(
                                alarm.formattedTime,
                                key: ValueKey<String>(
                                    'alarm-card-time-${alarm.id}'),
                                style: mc.alarmHeroStyle,
                              ),
                              MindClockStatusPill(
                                label: statusText,
                                accentWarm: !viewModel.isOsBridgeConnected ||
                                    alarm.syncStatus !=
                                        AlarmSyncStatus.scheduledReady ||
                                    !viewModel.permissionSnapshot.allGranted,
                              ),
                            ],
                          ),
                          SizedBox(height: mc.space8),
                          Text(
                            '$repeatText · ${alarm.soundOption.labelVi} · '
                            '${alarm.vibrateEnabled ? "Có rung" : "Không rung"}',
                            style: mc.captionStyle.copyWith(color: mc.nightText),
                          ),
                          SizedBox(height: mc.space4),
                          Text(
                            viewModel.explainAlarmModeAndSubject(alarm),
                            style: mc.captionStyle.copyWith(color: mc.sunrise),
                          ),
                          SizedBox(height: mc.space12),
                          Wrap(
                            spacing: mc.space8,
                            runSpacing: mc.space8,
                            children: <Widget>[
                              MindClockPressable(
                                key: ValueKey<String>(
                                    'alarm-toggle-${alarm.id}'),
                                semanticLabel:
                                    alarm.enabled ? 'Tắt báo thức' : 'Bật báo thức',
                                onPressed: () => viewModel.toggleAlarmEnabled(
                                  alarm.id,
                                  !alarm.enabled,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: mc.space12,
                                    vertical: mc.space8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: alarm.enabled
                                        ? mc.primary
                                        : mc.nightSurface,
                                    borderRadius:
                                        BorderRadius.circular(mc.radiusChip),
                                    border: Border.all(color: mc.sunrise),
                                  ),
                                  child: Text(
                                    alarm.enabled ? 'Đang bật' : 'Đang tắt',
                                    style: mc.chipLabelStyle.copyWith(
                                      color: mc.nightText,
                                    ),
                                  ),
                                ),
                              ),
                              MindClockPressable(
                                key: ValueKey<String>(
                                    'alarm-edit-${alarm.id}'),
                                semanticLabel: 'Sửa báo thức',
                                onPressed: () => onEditAlarm(alarm),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: mc.space12,
                                    vertical: mc.space8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mc.nightSurface,
                                    borderRadius:
                                        BorderRadius.circular(mc.radiusChip),
                                    border: Border.all(color: mc.outline),
                                  ),
                                  child: Text(
                                    'Sửa giờ / chế độ',
                                    style: mc.chipLabelStyle.copyWith(
                                      color: mc.nightText,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                MindClockButton(
                  key: const ValueKey<String>('today-add-another-alarm'),
                  label: 'Thêm cấu hình báo thức',
                  icon: MindClockIconKind.plus,
                  variant: MindClockButtonVariant.secondary,
                  onPressed: onCreateAlarm,
                ),
              ],
            ),
          SizedBox(height: mc.space16),
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Hồ sơ & Lịch hôm nay', style: mc.sectionTitleStyle),
                SizedBox(height: mc.space8),
                if (profile.alarmOnlyMode)
                  Text(
                    'Đang ở chế độ Chỉ báo thức. Bạn có thể bổ sung lớp và môn bất kỳ lúc nào.',
                    style: mc.bodyStyle,
                  )
                else ...<Widget>[
                  Text(
                    'Lớp: ${profile.gradeLevel ?? "Chưa chọn"} · Mục tiêu: '
                    '${profile.goalLabel.isEmpty ? "Chưa đặt" : profile.goalLabel}',
                    style: mc.bodyStyle,
                  ),
                  SizedBox(height: mc.space4),
                  Text(
                    profile.selectedSubjectCodes.isEmpty
                        ? 'Môn học: Chưa chọn môn'
                        : 'Môn học: ${profile.selectedSubjectCodes.map(SubjectCatalog.nameFor).join(", ")}',
                    style: mc.captionStyle,
                  ),
                ],
                SizedBox(height: mc.space8),
                Text(
                  todaySchedule.isRestDay
                      ? '${WeeklyTimetable.weekdayLabel(todayWeekday)}: Ngày nghỉ.'
                      : todaySchedule.entries.isEmpty
                          ? '${WeeklyTimetable.weekdayLabel(todayWeekday)}: Chưa có tiết học.'
                          : '${WeeklyTimetable.weekdayLabel(todayWeekday)}: '
                              '${todaySchedule.sortedEntries.map((TimetableEntry e) => "${e.formattedStartTime} ${SubjectCatalog.nameFor(e.subjectCode)}").join(" · ")}',
                  style: mc.captionStyle.copyWith(color: mc.ink),
                ),
                SizedBox(height: mc.space12),
                MindClockButton(
                  key: const ValueKey<String>('today-edit-timetable-profile'),
                  label: 'Sửa thời khóa biểu 7 ngày & hồ sơ',
                  icon: MindClockIconKind.calendar,
                  variant: MindClockButtonVariant.subtle,
                  onPressed: onOpenTimetableAndProfile,
                ),
              ],
            ),
          ),
          if (onOpenStudySpace != null) ...<Widget>[
            SizedBox(height: mc.space16),
            _buildStudySpaceEntryCard(context, mc),
          ],
        ],
      ),
    );
  }

  Widget _buildStudySpaceEntryCard(BuildContext context, MindClockTheme mc) {
    final StudyFocusSessionSnapshot? active = studyViewModel?.activeSnapshot;
    final List<StudyTaskChoice> suggestions = StudyTaskChoice.buildSuggestions(
      profile: viewModel.profile,
      timetable: viewModel.timetable,
      now: studyViewModel?.currentTime ?? DateTime.now(),
    );
    final String suggestedTitle = suggestions.first.title;
    final bool hasOngoing = active != null && active.status.isOngoing;
    final String ctaLabel;
    if (active != null && active.status == StudyFocusStatus.interrupted) {
      ctaLabel = 'Mở phiên đã gián đoạn';
    } else if (hasOngoing) {
      ctaLabel = 'Quay lại phiên học';
    } else {
      ctaLabel = AppStrings.studyStartCta;
    }

    return MindClockCard(
      highlighted: hasOngoing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AppStrings.studySpaceTitle, style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          Text(
            hasOngoing
                ? 'Đang mở: ${active.taskTitle} (${formatDurationClock(studyViewModel!.remainingSeconds)})'
                : 'Gợi ý hôm nay: $suggestedTitle · Timer cục bộ, tự chọn mức tập trung.',
            style: mc.bodyStyle,
          ),
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('today-open-study-space'),
            label: ctaLabel,
            icon: MindClockIconKind.play,
            onPressed: onOpenStudySpace,
          ),
        ],
      ),
    );
  }
}
