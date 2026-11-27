import 'package:flutter/material.dart';

import '../../../../domain/models/personal_flow_models.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../guest_shell/view_models/guest_workspace_view_model.dart';
import '../view_models/personal_flow_view_model.dart';
import 'daily_report_sheet.dart';

Future<void> showStreakDetailSheet({
  required BuildContext context,
  required PersonalFlowViewModel viewModel,
  GuestWorkspaceViewModel? workspaceViewModel,
  VoidCallback? onReportSubmitted,
}) async {
  if (viewModel.authSession.isAuthenticated) {
    viewModel.refreshProgressAndHistory();
    viewModel.loadDailyReports();
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.mc.paper,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.92,
      child: StreakDetailSheet(
        viewModel: viewModel,
        workspaceViewModel: workspaceViewModel,
        onReportSubmitted: onReportSubmitted,
      ),
    ),
  );
}

class StreakDetailSheet extends StatefulWidget {
  const StreakDetailSheet({
    super.key,
    required this.viewModel,
    this.workspaceViewModel,
    this.onReportSubmitted,
  });

  final PersonalFlowViewModel viewModel;
  final GuestWorkspaceViewModel? workspaceViewModel;
  final VoidCallback? onReportSubmitted;

  @override
  State<StreakDetailSheet> createState() => _StreakDetailSheetState();
}

class _StreakDetailSheetState extends State<StreakDetailSheet> {
  String? _selectedDate;

  List<StreakDayActivity> _resolvedDays(ProgressSummary summary) {
    if (summary.recentDays.isNotEmpty) return summary.recentDays;
    final DateTime now = DateTime.now();
    const List<String> labels = <String>[
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'CN',
    ];
    return List<StreakDayActivity>.generate(14, (int index) {
      final int offset = 13 - index;
      final DateTime d = now.subtract(Duration(days: offset));
      final String iso =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return StreakDayActivity(
        date: iso,
        weekdayLabel: labels[d.weekday - 1],
        isToday: offset == 0,
        completed: false,
        hasDailyReport: false,
        hasStudy: false,
        hasChallenge: false,
        xpEarned: 0,
      );
    });
  }

  String _shortDayNumber(String isoDate) {
    final List<String> parts = isoDate.split('-');
    if (parts.length == 3) return parts[2];
    return isoDate;
  }

  String _displayDateVi(String isoDate) {
    final List<String> parts = isoDate.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    return isoDate;
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (BuildContext context, _) {
        final PersonalFlowViewModel vm = widget.viewModel;
        final ProgressSummary summary = vm.progressSummary;
        final List<StreakDayActivity> days = _resolvedDays(summary);
        final StreakDayActivity selectedDay = days.firstWhere(
          (StreakDayActivity d) => d.date == _selectedDate,
          orElse: () => days.last,
        );

        return Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                  mc.space20, mc.space16, mc.space12, mc.space8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Chuỗi Streak & Báo cáo ngày',
                      style: mc.screenTitleStyle,
                    ),
                  ),
                  MindClockPressable(
                    semanticLabel: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(),
                    child: MindClockIcon(MindClockIconKind.minus, color: mc.ink),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey<String>('streak-detail-content'),
                padding: EdgeInsets.fromLTRB(
                    mc.space20, mc.space8, mc.space20, mc.space24),
                children: <Widget>[
                  MindClockCard(
                    highlighted: summary.todayCompleted,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.all(mc.space8),
                              decoration: BoxDecoration(
                                color: summary.todayCompleted
                                    ? mc.sunriseSoft
                                    : mc.paper,
                                borderRadius:
                                    BorderRadius.circular(mc.radiusControl),
                                border: Border.all(
                                  color: summary.todayCompleted
                                      ? mc.sunrise
                                      : mc.outline,
                                ),
                              ),
                              child: MindClockIcon(
                                MindClockIconKind.flame,
                                color: summary.todayCompleted
                                    ? mc.primary
                                    : mc.inkMuted,
                                size: 28,
                              ),
                            ),
                            SizedBox(width: mc.space12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '${summary.streak} ngày Streak',
                                    key: const ValueKey<String>(
                                        'streak-detail-hero-count'),
                                    style: mc.screenTitleStyle,
                                  ),
                                  Text(
                                    summary.todayCompleted
                                        ? 'Hôm nay đã giữ nhịp thành công.'
                                        : 'Hoàn thành 1 báo cáo ngày, phiên học 5p hoặc câu sáng để giữ streak hôm nay.',
                                    style: mc.captionStyle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: mc.space12),
                        Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space8,
                          children: <Widget>[
                            MindClockStatusPill(
                              label: 'Kỷ lục ${summary.bestStreak} ngày',
                              accentWarm: summary.bestStreak > 0,
                            ),
                            MindClockStatusPill(
                              label: 'Tổng ${summary.totalActiveDays} ngày',
                            ),
                            MindClockStatusPill(
                              label: summary.todayReportSubmitted
                                  ? 'Báo cáo hôm nay: Đã nộp'
                                  : 'Báo cáo hôm nay: Chưa nộp',
                              accentWarm: !summary.todayReportSubmitted,
                            ),
                          ],
                        ),
                        SizedBox(height: mc.space12),
                        MindClockButton(
                          key: const ValueKey<String>(
                              'streak-detail-open-report'),
                          label: summary.todayReportSubmitted
                              ? 'Xem / Sửa báo cáo hôm nay'
                              : 'Hoàn thành báo cáo hôm nay',
                          icon: MindClockIconKind.check,
                          onPressed: () async {
                            final DailyReportSubmitResult? res =
                                await showDailyReportSheet(
                              context: context,
                              viewModel: vm,
                              workspaceViewModel: widget.workspaceViewModel,
                            );
                            if (res != null) {
                              widget.onReportSubmitted?.call();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: mc.space16),
                  MindClockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Lịch 14 ngày gần nhất',
                            style: mc.sectionTitleStyle),
                        SizedBox(height: mc.space4),
                        Text(
                          'Chạm vào từng ngày để xem hoạt động đã giữ streak.',
                          style: mc.captionStyle,
                        ),
                        SizedBox(height: mc.space12),
                        for (int rowStart = 0;
                            rowStart < days.length;
                            rowStart += 7)
                          Padding(
                            padding: EdgeInsets.only(
                                bottom: rowStart + 7 < days.length
                                    ? mc.space8
                                    : 0),
                            child: Row(
                              children: List<Widget>.generate(7, (int col) {
                                final int idx = rowStart + col;
                                if (idx >= days.length) {
                                  return const Expanded(child: SizedBox());
                                }
                                final StreakDayActivity day = days[idx];
                                final bool isSelected =
                                    day.date == selectedDay.date;
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: mc.space4 / 2),
                                    child: MindClockPressable(
                                      key: ValueKey<String>(
                                          'streak-day-${day.date}'),
                                      selected: isSelected,
                                      semanticLabel:
                                          '${day.weekdayLabel} ${_displayDateVi(day.date)} ${day.completed ? "đã giữ streak" : "chưa hoàn thành"}',
                                      onPressed: () => setState(
                                          () => _selectedDate = day.date),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                            vertical: mc.space8,
                                            horizontal: mc.space4 / 2),
                                        decoration: BoxDecoration(
                                          color: day.completed
                                              ? (day.isToday
                                                  ? mc.sunriseSoft
                                                  : mc.primarySoft)
                                              : mc.paper,
                                          borderRadius: BorderRadius.circular(
                                              mc.radiusChip),
                                          border: Border.all(
                                            color: isSelected
                                                ? mc.ink
                                                : (day.completed
                                                    ? mc.primary
                                                    : mc.outline),
                                            width: isSelected ? 1.8 : 1,
                                          ),
                                        ),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: <Widget>[
                                              Text(
                                                day.isToday
                                                    ? 'Nay'
                                                    : day.weekdayLabel,
                                                style: mc.captionStyle.copyWith(
                                                  fontSize: 11,
                                                  fontWeight: day.isToday
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _shortDayNumber(day.date),
                                                style:
                                                    mc.chipLabelStyle.copyWith(
                                                  color: day.completed
                                                      ? mc.primary
                                                      : mc.inkMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        SizedBox(height: mc.space12),
                        Container(
                          key: const ValueKey<String>(
                              'streak-selected-day-breakdown'),
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
                              Text(
                                '${selectedDay.isToday ? "Hôm nay · " : ""}${selectedDay.weekdayLabel} (${_displayDateVi(selectedDay.date)})',
                                style: mc.bodyStrongStyle,
                              ),
                              SizedBox(height: mc.space4),
                              Text(
                                selectedDay.completed
                                    ? 'Đã giữ 1 ngày streak (+${selectedDay.xpEarned} EXP)'
                                    : 'Chưa có hoạt động giữ streak trong ngày này.',
                                style: mc.captionStyle,
                              ),
                              if (selectedDay.completed) ...<Widget>[
                                SizedBox(height: mc.space8),
                                Wrap(
                                  spacing: mc.space8,
                                  runSpacing: mc.space8,
                                  children: <Widget>[
                                    if (selectedDay.hasDailyReport)
                                      const MindClockStatusPill(
                                        label: 'Báo cáo ngày',
                                        accentWarm: true,
                                      ),
                                    if (selectedDay.hasStudy)
                                      const MindClockStatusPill(
                                        label: 'Tự học >= 5p',
                                      ),
                                    if (selectedDay.hasChallenge)
                                      const MindClockStatusPill(
                                        label: 'Câu ôn sáng',
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: mc.space16),
                  MindClockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Nhật ký Báo cáo ngày',
                            style: mc.sectionTitleStyle),
                        SizedBox(height: mc.space8),
                        if (!vm.authSession.isAuthenticated)
                          Text(
                            'Đăng nhập để lưu và xem lại lịch sử báo cáo ngày.',
                            style: mc.bodyStyle,
                          )
                        else if (vm.dailyReports.isEmpty)
                          Text(
                            'Chưa có báo cáo ngày nào. Hoàn thành báo cáo hôm nay để mở chuỗi đầu tiên!',
                            style: mc.bodyStyle,
                          )
                        else
                          for (final DailyReportRecord report
                              in vm.dailyReports)
                            Padding(
                              padding: EdgeInsets.only(bottom: mc.space8),
                              child: Container(
                                key: ValueKey<String>(
                                    'daily-report-item-${report.localDate}'),
                                width: double.infinity,
                                padding: EdgeInsets.all(mc.space12),
                                decoration: BoxDecoration(
                                  color: mc.paper,
                                  borderRadius:
                                      BorderRadius.circular(mc.radiusControl),
                                  border: Border.all(color: mc.outline),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Wrap(
                                      spacing: mc.space8,
                                      runSpacing: mc.space4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: <Widget>[
                                        Text(
                                          _displayDateVi(report.localDate),
                                          style: mc.bodyStrongStyle,
                                        ),
                                        MindClockStatusPill(
                                          label: report.feelingLabelVi,
                                          accentWarm: true,
                                        ),
                                        if (report.xpAwarded > 0)
                                          MindClockStatusPill(
                                            label: '+${report.xpAwarded} EXP',
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: mc.space4),
                                    Text(
                                      'Học ${report.studyMinutes} phút · ${report.tasksCompleted} việc xong'
                                      '${report.challengeCompleted ? " · Đã giải câu sáng" : ""}',
                                      style: mc.captionStyle,
                                    ),
                                    if (report.reflectionNote.isNotEmpty) ...<Widget>[
                                      SizedBox(height: mc.space4),
                                      Text(
                                        report.reflectionNote,
                                        style: mc.bodyStyle,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
