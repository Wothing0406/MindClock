import 'dart:async';
import 'package:flutter/widgets.dart';

import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/alarm_occurrence.dart';
import '../../../../domain/models/daily_study_plan.dart';
import '../../../../domain/models/study_focus_models.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/models/timetable.dart';
import '../../../../domain/services/morning_question_selector.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_avatar_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../study_focus/view_models/study_focus_view_model.dart';
import '../../community/views/today_pet_card.dart';
import '../../personal_flow/view_models/personal_flow_view_model.dart';
import '../../personal_flow/views/today_streak_card.dart';
import '../view_models/guest_workspace_view_model.dart';
import 'day_schedule_timeline_card.dart';

/// Màn hình `S04` Hôm nay (Dashboard cá nhân hóa đa môn & TKB tuần).
class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.viewModel,
    required this.onCreateAlarm,
    required this.onEditAlarm,
    required this.onOpenTimetableAndProfile,
    this.personalViewModel,
    this.studyViewModel,
    this.communityRepository,
    this.onOpenStudySpace,
    this.onSelectTab,
    this.lastActionBanner,
  });

  final GuestWorkspaceViewModel viewModel;
  final VoidCallback onCreateAlarm;
  final ValueChanged<AlarmConfig> onEditAlarm;
  final VoidCallback onOpenTimetableAndProfile;
  final PersonalFlowViewModel? personalViewModel;
  final StudyFocusViewModel? studyViewModel;
  final CommunityRepository? communityRepository;
  final VoidCallback? onOpenStudySpace;
  final ValueChanged<int>? onSelectTab;
  final String? lastActionBanner;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  final ValueNotifier<int> _petRefreshTick = ValueNotifier<int>(0);
  late int _selectedWeekday;
  late DateTime _currentTime;
  Timer? _clockTicker;

  @override
  void initState() {
    super.initState();
    _selectedWeekday = DateTime.now().weekday;
    _currentTime = DateTime.now();
    _clockTicker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    _petRefreshTick.dispose();
    super.dispose();
  }

  String _formatAlarmCountdown(AlarmConfig alarm, DateTime now) {
    DateTime candidate =
        DateTime(now.year, now.month, now.day, alarm.hour, alarm.minute);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    if (alarm.repeatWeekdays.isNotEmpty) {
      for (int i = 0; i < 7; i++) {
        final DateTime d = DateTime(
            now.year, now.month, now.day + i, alarm.hour, alarm.minute);
        if (alarm.repeatWeekdays.contains(d.weekday) && d.isAfter(now)) {
          candidate = d;
          break;
        }
      }
    }
    final Duration diff = candidate.difference(now);
    final int hours = diff.inHours;
    final int minutes = diff.inMinutes % 60;
    final int seconds = diff.inSeconds % 60;
    if (hours > 0) {
      return 'Còn $hours giờ $minutes phút $seconds giây';
    } else if (minutes > 0) {
      return 'Còn $minutes phút $seconds giây';
    } else {
      return 'Còn $seconds giây chuẩn bị reo!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final StudyProfile profile = widget.viewModel.profile;
    final List<AlarmConfig> alarms = widget.viewModel.alarms;

    final int currentRealWeekday = DateTime.now().weekday;
    final DaySchedule selectedDaySchedule =
        widget.viewModel.timetable.dayFor(_selectedWeekday);

    final AlarmConfig? activeAlarm = alarms.cast<AlarmConfig?>().firstWhere(
          (AlarmConfig? a) => a?.enabled == true,
          orElse: () => alarms.isNotEmpty ? alarms.first : null,
        );

    final MorningQuestionProposal? morningProposal = activeAlarm != null
        ? MorningQuestionSelector.resolveForAlarm(
            alarm: activeAlarm,
            profile: profile,
            timetable: widget.viewModel.timetable,
            weekday: _selectedWeekday,
          )
        : null;

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
              MindClockAvatarView(
                avatarId: profile.avatarId,
                customAvatarPath: profile.customAvatarPath,
                size: 36,
                selected: true,
              ),
              Text(AppStrings.navToday, style: mc.screenTitleStyle),
              MindClockStatusPill(
                label:
                    '${profile.alias.isNotEmpty ? profile.alias : "Học sinh"} · ${profile.gradeLevel ?? "Lớp 11"}',
                accentWarm: true,
              ),
            ],
          ),
          // 0. Khung đồng hồ thời gian thực (Realtime Clock Hero - đồng bộ trang vở sáng)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: mc.space12, bottom: mc.space12),
            padding: EdgeInsets.all(mc.space16),
            decoration: BoxDecoration(
              color: mc.surface,
              borderRadius: BorderRadius.circular(mc.radiusCard),
              border: Border.all(color: mc.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: <Widget>[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: <Widget>[
                          Text(
                            '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}',
                            key: const ValueKey<String>(
                                'today-realtime-clock-hm'),
                            style: mc.alarmHeroStyle.copyWith(
                              fontSize: 32,
                              letterSpacing: -1,
                              color: mc.ink,
                            ),
                          ),
                          SizedBox(width: mc.space4),
                          Text(
                            ':${_currentTime.second.toString().padLeft(2, '0')}',
                            key: const ValueKey<String>(
                                'today-realtime-clock-sec'),
                            style: mc.alarmHeroStyle.copyWith(
                              fontSize: 20,
                              color: mc.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: mc.primarySoft,
                          borderRadius: BorderRadius.circular(mc.radiusChip),
                          border: Border.all(
                              color: mc.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: mc.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Thời gian thực',
                              style:
                                  mc.captionStyle.copyWith(color: mc.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: mc.space4),
                Text(
                  '${WeeklyTimetable.weekdayLabel(_currentTime.weekday)}, ngày ${_currentTime.day.toString().padLeft(2, '0')}/${_currentTime.month.toString().padLeft(2, '0')}/${_currentTime.year}',
                  style: mc.bodyStyle.copyWith(color: mc.inkMuted),
                ),
                SizedBox(height: mc.space12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                      horizontal: mc.space12, vertical: mc.space8),
                  decoration: BoxDecoration(
                    color: mc.sunriseSoft,
                    borderRadius: BorderRadius.circular(mc.radiusControl),
                  ),
                  child: Row(
                    children: <Widget>[
                      MindClockIcon(
                        MindClockIconKind.bell,
                        color: mc.primary,
                        size: 18,
                      ),
                      SizedBox(width: mc.space8),
                      Expanded(
                        child: Text(
                          activeAlarm != null && activeAlarm.enabled
                              ? '${_formatAlarmCountdown(activeAlarm, _currentTime)} · Chuông ${activeAlarm.formattedTime}'
                              : 'Báo thức đang tắt · Chạm thẻ bên dưới để bật giờ dậy',
                          style: mc.captionStyle.copyWith(
                            color: mc.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.lastActionBanner != null) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockNoticeBanner(
              message: widget.lastActionBanner!,
              isWarm: false,
            ),
          ],
          SizedBox(height: mc.space12),
          _buildFeatureDirectory(
            context: context,
            mc: mc,
            activeAlarm: activeAlarm,
            morningProposal: morningProposal,
            selectedDaySchedule: selectedDaySchedule,
          ),
          if (widget.personalViewModel != null) ...<Widget>[
            SizedBox(height: mc.space12),
            TodayStreakCard(
              personalViewModel: widget.personalViewModel!,
              workspaceViewModel: widget.viewModel,
              onReportSubmitted: () => _petRefreshTick.value++,
            ),
          ],
          if (widget.viewModel.needsOsPermissions) ...<Widget>[
            SizedBox(height: mc.space12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(mc.space12),
              decoration: BoxDecoration(
                color: mc.sunriseSoft,
                borderRadius: BorderRadius.circular(mc.radiusControl),
                border: Border.all(color: mc.sunrise),
              ),
              child: Row(
                children: <Widget>[
                  MindClockIcon(
                    MindClockIconKind.warning,
                    color: mc.ink,
                    size: 20,
                  ),
                  SizedBox(width: mc.space8),
                  Expanded(
                    child: Text(
                      'Cần cấp quyền hệ thống để chuông reo đúng giờ.',
                      style: mc.captionStyle.copyWith(
                        color: mc.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (widget.viewModel.missingPermissionActions.isNotEmpty)
                    MindClockPressable(
                      key: const ValueKey<String>('today-grant-perm-quick'),
                      onPressed: () => widget.viewModel.openPermissionSettings(
                        widget.viewModel.missingPermissionActions.first,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: mc.space12,
                          vertical: mc.space4 + 2,
                        ),
                        decoration: BoxDecoration(
                          color: mc.surface,
                          borderRadius: BorderRadius.circular(mc.radiusChip),
                          border: Border.all(color: mc.sunrise),
                        ),
                        child: Text(
                          'Cấp quyền',
                          style: mc.chipLabelStyle.copyWith(color: mc.ink),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (widget.viewModel.scheduleChangedSinceAlarmSave &&
              alarms.isNotEmpty) ...<Widget>[
            SizedBox(height: mc.space12),
            const MindClockNoticeBanner(
              message: AppStrings.wakeScheduleChangedNotice,
            ),
          ],
          if (profile.confirmedPlan != null &&
              profile.confirmedPlan!.items.isNotEmpty) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockCard(
              key: const ValueKey<String>('today-confirmed-plan-card'),
              highlighted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: mc.space8,
                    runSpacing: mc.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text('Kế hoạch hôm nay', style: mc.sectionTitleStyle),
                      MindClockStatusPill(
                        label: profile.confirmedPlan!.sourceLabelVi,
                      ),
                    ],
                  ),
                  SizedBox(height: mc.space8),
                  ...profile.confirmedPlan!.items.map(
                    (DailyPlanItem item) => Padding(
                      padding: EdgeInsets.only(bottom: mc.space8),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(mc.space12),
                        decoration: BoxDecoration(
                          color: mc.paper,
                          borderRadius: BorderRadius.circular(mc.radiusControl),
                          border: Border.all(color: mc.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: mc.space8,
                              runSpacing: mc.space4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                Text(item.titleVi, style: mc.bodyStrongStyle),
                                MindClockStatusPill(
                                  label: item.hasApprovedQuestions
                                      ? 'Sẵn sàng ôn'
                                      : 'Tự ôn tập',
                                  accentWarm: !item.hasApprovedQuestions,
                                ),
                              ],
                            ),
                            SizedBox(height: mc.space4),
                            Text(item.reasonVi, style: mc.captionStyle),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: mc.space16),

          // 1. Dải chọn ngày trong tuần (TKB 7 ngày)
          Text('Thời khóa biểu & Chuẩn bị bài', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List<Widget>.generate(7, (int index) {
                final int weekday = index + 1;
                final bool isSelected = weekday == _selectedWeekday;
                final bool isToday = weekday == currentRealWeekday;
                final String label = WeeklyTimetable.shortWeekdayLabel(weekday);
                return Padding(
                  padding: EdgeInsets.only(right: mc.space8),
                  child: MindClockPressable(
                    key: ValueKey<String>('weekday-picker-$weekday'),
                    semanticLabel: WeeklyTimetable.weekdayLabel(weekday),
                    selected: isSelected,
                    onPressed: () => setState(() => _selectedWeekday = weekday),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: mc.space12,
                        vertical: mc.space8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? mc.primary
                            : (isToday ? mc.sunriseSoft : mc.surface),
                        borderRadius: BorderRadius.circular(mc.radiusChip),
                        border: Border.all(
                          color: isSelected
                              ? mc.primary
                              : (isToday ? mc.sunrise : mc.outline),
                          width: isSelected || isToday ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            label,
                            style: mc.chipLabelStyle.copyWith(
                              color: isSelected
                                  ? mc.onPrimary
                                  : (isToday ? mc.ink : mc.bodyStyle.color),
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          if (isToday)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isSelected ? mc.onPrimary : mc.sunrise,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: mc.space12),

          // 2. Thẻ chi tiết tiết học & Chuẩn bị bài của ngày được chọn
          MindClockCard(
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
                      WeeklyTimetable.weekdayLabel(_selectedWeekday),
                      style: mc.sectionTitleStyle,
                    ),
                    if (_selectedWeekday == currentRealWeekday)
                      const MindClockStatusPill(
                        label: 'Hôm nay',
                        accentWarm: true,
                      ),
                  ],
                ),
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
                  SizedBox(height: mc.space8),
                ],
                if (selectedDaySchedule.isRestDay)
                  Text(
                    'Ngày nghỉ: Không có lịch học cố định. Bạn có thể tự học hoặc dành thời gian phục hồi năng lượng.',
                    style: mc.bodyStyle,
                  )
                else if (selectedDaySchedule.entries.isEmpty)
                  Text(
                    'Chưa có lịch học trên lớp cho ngày này. Bạn có thể tự học hoặc tạo phiên tập trung.',
                    style: mc.bodyStyle,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: selectedDaySchedule.sortedEntries
                        .map((TimetableEntry entry) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: mc.space4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 52,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: mc.primarySoft,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                entry.formattedStartTime,
                                textAlign: TextAlign.center,
                                style: mc.captionStyle.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: mc.ink,
                                ),
                              ),
                            ),
                            SizedBox(width: mc.space8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    SubjectCatalog.nameFor(entry.subjectCode),
                                    style: mc.bodyStyle.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (entry.note.isNotEmpty)
                                    Text(
                                      entry.note,
                                      style: mc.captionStyle.copyWith(
                                        color: mc.ink,
                                      ),
                                    )
                                  else
                                    Text(
                                      'Ôn nhanh công thức & bài tập trước giờ vào lớp',
                                      style: mc.captionStyle,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                SizedBox(height: mc.space12),
                MindClockButton(
                  key: const ValueKey<String>('today-edit-timetable-profile'),
                  label: 'Sửa thời khóa biểu 7 ngày & hồ sơ',
                  icon: MindClockIconKind.calendar,
                  variant: MindClockButtonVariant.subtle,
                  onPressed: widget.onOpenTimetableAndProfile,
                ),
              ],
            ),
          ),
          SizedBox(height: mc.space12),
          DayScheduleTimelineCard(
            viewModel: widget.viewModel,
            selectedDate: _currentTime.add(
              Duration(days: _selectedWeekday - _currentTime.weekday),
            ),
            now: _currentTime,
            onSelectWeekday: (int weekday) {
              setState(() => _selectedWeekday = weekday);
            },
          ),
          SizedBox(height: mc.space16),

          // 3. Báo thức tiếp theo & Câu ôn sáng được gợi ý
          if (alarms.isEmpty)
            MindClockCard(
              highlighted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Chưa có báo thức nào', style: mc.sectionTitleStyle),
                  SizedBox(height: mc.space8),
                  Text(
                    'Đặt giờ báo thức và xem gợi ý giờ dậy phù hợp với thời khóa biểu hôm nay.',
                    style: mc.bodyStyle,
                  ),
                  SizedBox(height: mc.space12),
                  MindClockButton(
                    key: const ValueKey<String>('today-add-first-alarm'),
                    label: 'Đặt báo thức đầu tiên',
                    icon: MindClockIconKind.bell,
                    onPressed: widget.onCreateAlarm,
                  ),
                ],
              ),
            )
          else ...<Widget>[
            if (morningProposal != null && activeAlarm != null) ...<Widget>[
              Builder(
                builder: (BuildContext context) {
                  final AlarmOccurrenceRecord? todayOcc =
                      widget.viewModel.occurrenceForToday(activeAlarm.id);
                  final String occLabel =
                      todayOcc?.dashboardStatusLabelVi ?? 'Đang chờ';
                  final bool isDone =
                      todayOcc?.state == AlarmOccurrenceState.completed;
                  final bool isWaitingAnswer =
                      todayOcc?.isWaitingQuestion ?? false;
                  final bool isEndedWithoutReward =
                      todayOcc?.state == AlarmOccurrenceState.skipped ||
                          todayOcc?.state == AlarmOccurrenceState.dismissed;
                  return MindClockCard(
                    key: const ValueKey<String>('today-morning-occurrence-card'),
                    highlighted: isWaitingAnswer,
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
                              'Câu hỏi buổi sáng',
                              style: mc.sectionTitleStyle,
                            ),
                            MindClockStatusPill(
                              key: const ValueKey<String>(
                                'today-morning-occurrence-status',
                              ),
                              label: occLabel,
                              accentWarm: isWaitingAnswer ||
                                  (todayOcc?.hasSyncError ?? false),
                            ),
                          ],
                        ),
                        SizedBox(height: mc.space8),
                        Text(
                          '${morningProposal.subjectNameVi} · ${morningProposal.topicNameVi}',
                          style:
                              mc.bodyStyle.copyWith(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: mc.space4),
                        Text(
                          isDone
                              ? 'Bạn đã hoàn thành câu sáng hôm nay. Không cần làm lại.'
                              : isEndedWithoutReward
                                  ? 'Lượt chuông hôm nay đã khép lại ($occLabel).'
                                  : isWaitingAnswer
                                      ? (todayOcc?.hasSyncError == true
                                          ? 'Bài làm chưa đồng bộ được máy chủ. Mở lại để gửi tiếp mà không mất lượt.'
                                          : 'Câu sáng đang mở. Chạm bên dưới để hoàn thành.')
                                      : 'Hiện câu hỏi ngay khi chuông ${activeAlarm.formattedTime} reo.',
                          style: mc.captionStyle.copyWith(color: mc.ink),
                        ),
                        if (isWaitingAnswer &&
                            widget.onSelectTab != null) ...<Widget>[
                          SizedBox(height: mc.space12),
                          MindClockButton(
                            key: const ValueKey<String>(
                              'today-resume-morning-question',
                            ),
                            label: 'Tiếp tục câu hỏi buổi sáng',
                            icon: MindClockIconKind.book,
                            onPressed: () => widget.onSelectTab!(1),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: mc.space12),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ...alarms.map((AlarmConfig alarm) {
                  final String statusText =
                      widget.viewModel.statusLabelForAlarm(alarm);
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
                        color: mc.surface,
                        borderRadius: BorderRadius.circular(mc.radiusCard),
                        border: Border.all(
                          color: alarm.enabled ? mc.primary : mc.outline,
                          width: alarm.enabled ? 1.5 : 1,
                        ),
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
                                style: mc.alarmHeroStyle.copyWith(
                                  color: mc.ink,
                                ),
                              ),
                              Wrap(
                                spacing: mc.space8,
                                runSpacing: mc.space8,
                                children: <Widget>[
                                  MindClockStatusPill(
                                    label: alarm.mode == AlarmMode.challenge
                                        ? 'Thử thách'
                                        : 'Thường',
                                    accentWarm:
                                        alarm.mode == AlarmMode.challenge,
                                  ),
                                  MindClockStatusPill(
                                    key: ValueKey<String>(
                                        'alarm-os-status-${alarm.id}'),
                                    label: statusText,
                                    accentWarm: !widget
                                            .viewModel.isOsBridgeConnected ||
                                        alarm.syncStatus !=
                                            AlarmSyncStatus.scheduledReady ||
                                        !widget.viewModel.permissionSnapshot
                                            .allGranted,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: mc.space8),
                          Text(
                            '$repeatText · ${alarm.soundOption.labelVi} · '
                            '${alarm.vibrateEnabled ? "Có rung" : "Không rung"}',
                            style:
                                mc.captionStyle.copyWith(color: mc.inkMuted),
                          ),
                          SizedBox(height: mc.space4),
                          Text(
                            widget.viewModel.explainAlarmModeAndSubject(alarm),
                            style: mc.captionStyle.copyWith(
                              color: mc.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: mc.space12),
                          Wrap(
                            spacing: mc.space8,
                            runSpacing: mc.space8,
                            children: <Widget>[
                              MindClockPressable(
                                key: ValueKey<String>(
                                    'alarm-toggle-${alarm.id}'),
                                semanticLabel: alarm.enabled
                                    ? 'Tắt báo thức'
                                    : 'Bật báo thức',
                                onPressed: () =>
                                    widget.viewModel.toggleAlarmEnabled(
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
                                        : mc.paper,
                                    borderRadius:
                                        BorderRadius.circular(mc.radiusChip),
                                    border: Border.all(
                                      color: alarm.enabled
                                          ? mc.primary
                                          : mc.outline,
                                    ),
                                  ),
                                  child: Text(
                                    alarm.enabled ? 'Đang bật' : 'Đang tắt',
                                    style: mc.chipLabelStyle.copyWith(
                                      color: alarm.enabled
                                          ? mc.onPrimary
                                          : mc.ink,
                                    ),
                                  ),
                                ),
                              ),
                              MindClockPressable(
                                key: ValueKey<String>('alarm-edit-${alarm.id}'),
                                semanticLabel: 'Sửa báo thức',
                                onPressed: () => widget.onEditAlarm(alarm),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: mc.space12,
                                    vertical: mc.space8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: mc.paper,
                                    borderRadius:
                                        BorderRadius.circular(mc.radiusChip),
                                    border: Border.all(color: mc.outline),
                                  ),
                                  child: Text(
                                    'Sửa báo thức',
                                    style: mc.chipLabelStyle.copyWith(
                                      color: mc.ink,
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
                  label: 'Thêm báo thức mới',
                  icon: MindClockIconKind.plus,
                  variant: MindClockButtonVariant.secondary,
                  onPressed: widget.onCreateAlarm,
                ),
              ],
            ),
          ],
          if (widget.onOpenStudySpace != null) ...<Widget>[
            SizedBox(height: mc.space16),
            _buildStudySpaceEntryCard(context, mc),
          ],
          if (widget.communityRepository != null) ...<Widget>[
            SizedBox(height: mc.space16),
            Text(
              'Động lực & Nhóm cam kết',
              style: mc.sectionTitleStyle,
            ),
            SizedBox(height: mc.space8),
            TodayPetCard(
              repository: widget.communityRepository!,
              refreshTick: _petRefreshTick,
            ),
          ],
          const SizedBox(height: 76),
        ],
      ),
    );
  }

  Widget _buildFeatureDirectory({
    required BuildContext context,
    required MindClockTheme mc,
    required AlarmConfig? activeAlarm,
    required MorningQuestionProposal? morningProposal,
    required DaySchedule selectedDaySchedule,
  }) {
    final StudyFocusSessionSnapshot? activeStudy =
        widget.studyViewModel?.activeSnapshot;
    final int pendingTodos =
        widget.viewModel.dailyTasks.where((t) => !t.isDone).length;

    final List<
        ({
          String key,
          String title,
          String subtitle,
          MindClockIconKind icon,
          VoidCallback? onTap,
          bool highlight,
        })> tiles = <({
      String key,
      String title,
      String subtitle,
      MindClockIconKind icon,
      VoidCallback? onTap,
      bool highlight,
    })>[
      (
        key: 'today-dir-alarm',
        title: 'Báo thức',
        subtitle: activeAlarm != null
            ? '${activeAlarm.formattedTime} · ${activeAlarm.mode == AlarmMode.challenge ? "Thử thách" : "Thường"}'
            : 'Chưa đặt chuông',
        icon: MindClockIconKind.bell,
        onTap: activeAlarm != null
            ? () => widget.onEditAlarm(activeAlarm)
            : widget.onCreateAlarm,
        highlight: activeAlarm == null,
      ),
      (
        key: 'today-dir-practice',
        title: 'Luyện tập',
        subtitle: morningProposal != null
            ? 'Môn ${morningProposal.subjectNameVi}'
            : 'Câu ôn GDPT 2018',
        icon: MindClockIconKind.book,
        onTap: widget.onSelectTab != null ? () => widget.onSelectTab!(1) : null,
        highlight: false,
      ),
      (
        key: 'today-dir-study',
        title: 'Không gian học',
        subtitle: (activeStudy != null && activeStudy.status.isOngoing)
            ? 'Đang mở · ${activeStudy.taskTitle}'
            : 'Tự học · Đốt nến · AI',
        icon: MindClockIconKind.clock,
        onTap: widget.onOpenStudySpace ??
            (widget.onSelectTab != null ? () => widget.onSelectTab!(1) : null),
        highlight: activeStudy != null && activeStudy.status.isOngoing,
      ),
      (
        key: 'today-dir-timetable',
        title: 'TKB & Việc ngày',
        subtitle:
            '${selectedDaySchedule.entries.length} tiết · $pendingTodos việc',
        icon: MindClockIconKind.calendar,
        onTap: widget.onOpenTimetableAndProfile,
        highlight: false,
      ),
      (
        key: 'today-dir-arena',
        title: 'Đấu trường',
        subtitle: '3 Tướng · BXH · Shop',
        icon: MindClockIconKind.arena,
        onTap: widget.onSelectTab != null ? () => widget.onSelectTab!(2) : null,
        highlight: false,
      ),
      (
        key: 'today-dir-profile',
        title: 'Nhóm & Hồ sơ',
        subtitle: 'Pet nhóm · Quyền OS',
        icon: MindClockIconKind.user,
        onTap: widget.onSelectTab != null ? () => widget.onSelectTab!(3) : null,
        highlight: false,
      ),
    ];

    Widget buildTile(
      ({
        String key,
        String title,
        String subtitle,
        MindClockIconKind icon,
        VoidCallback? onTap,
        bool highlight,
      }) item,
    ) {
      return MindClockPressable(
        key: ValueKey<String>(item.key),
        semanticLabel: '${item.title}: ${item.subtitle}',
        onPressed: item.onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(mc.space12),
          decoration: BoxDecoration(
            color: item.highlight ? mc.sunriseSoft : mc.surface,
            borderRadius: BorderRadius.circular(mc.radiusControl),
            border: Border.all(
              color: item.highlight ? mc.sunrise : mc.outline,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(mc.space8),
                decoration: BoxDecoration(
                  color: item.highlight ? mc.surface : mc.primarySoft,
                  borderRadius: BorderRadius.circular(mc.radiusChip),
                ),
                child: MindClockIcon(item.icon, color: mc.primary, size: 18),
              ),
              SizedBox(width: mc.space8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: mc.bodyStrongStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: mc.space4 / 2),
                    Text(
                      item.subtitle,
                      style: mc.captionStyle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return MindClockCard(
      key: const ValueKey<String>('today-feature-directory'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Danh mục tính năng', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space4),
          Text(
            'Chọn nhanh từng phần trong MindClock để bắt đầu ngay:',
            style: mc.captionStyle,
          ),
          SizedBox(height: mc.space12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              if (constraints.maxWidth < 300) {
                return Column(
                  children: tiles
                      .map((t) => Padding(
                            padding: EdgeInsets.only(bottom: mc.space8),
                            child: buildTile(t),
                          ))
                      .toList(),
                );
              }
              final List<Widget> rows = <Widget>[];
              for (int i = 0; i < tiles.length; i += 2) {
                rows.add(
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i + 2 < tiles.length ? mc.space8 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: buildTile(tiles[i])),
                        SizedBox(width: mc.space8),
                        Expanded(
                          child: i + 1 < tiles.length
                              ? buildTile(tiles[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(children: rows);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStudySpaceEntryCard(BuildContext context, MindClockTheme mc) {
    final StudyFocusSessionSnapshot? active =
        widget.studyViewModel?.activeSnapshot;
    final List<StudyTaskChoice> suggestions = StudyTaskChoice.buildSuggestions(
      profile: widget.viewModel.profile,
      timetable: widget.viewModel.timetable,
      now: widget.studyViewModel?.currentTime ?? DateTime.now(),
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
                ? 'Đang mở: ${active.taskTitle} (${formatDurationClock(widget.studyViewModel!.remainingSeconds)})'
                : 'Gợi ý hôm nay: $suggestedTitle · Bấm để bắt đầu tập trung.',
            style: mc.bodyStyle,
          ),
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('today-open-study-space'),
            label: ctaLabel,
            icon: MindClockIconKind.play,
            onPressed: widget.onOpenStudySpace,
          ),
        ],
      ),
    );
  }
}
