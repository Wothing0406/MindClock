import 'package:flutter/material.dart';

import '../../../../domain/models/personal_flow_models.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../guest_shell/view_models/guest_workspace_view_model.dart';
import '../view_models/personal_flow_view_model.dart';
import 'daily_report_sheet.dart';
import 'streak_detail_sheet.dart';

/// Card Trending Streak & Báo cáo ngày trên màn `Hôm nay` (`T077`).
class TodayStreakCard extends StatefulWidget {
  const TodayStreakCard({
    super.key,
    required this.personalViewModel,
    this.workspaceViewModel,
    this.onReportSubmitted,
  });

  final PersonalFlowViewModel personalViewModel;
  final GuestWorkspaceViewModel? workspaceViewModel;
  final VoidCallback? onReportSubmitted;

  @override
  State<TodayStreakCard> createState() => _TodayStreakCardState();
}

class _TodayStreakCardState extends State<TodayStreakCard> {
  String? _loadedScope;

  @override
  void initState() {
    super.initState();
    widget.personalViewModel.addListener(_syncScope);
    _syncScope();
  }

  @override
  void didUpdateWidget(covariant TodayStreakCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personalViewModel != widget.personalViewModel) {
      oldWidget.personalViewModel.removeListener(_syncScope);
      widget.personalViewModel.addListener(_syncScope);
      _loadedScope = null;
      _syncScope();
    }
  }

  @override
  void dispose() {
    widget.personalViewModel.removeListener(_syncScope);
    super.dispose();
  }

  void _syncScope() {
    final PersonalFlowViewModel vm = widget.personalViewModel;
    final String scope =
        vm.authSession.isAuthenticated ? vm.authSession.ownerScopeKey : 'guest';
    if (_loadedScope == scope) return;
    _loadedScope = scope;
    if (!vm.authSession.isAuthenticated || vm.isDebugFixture) return;
    if (vm.progressSyncedAt != null && vm.dailyReportsLoaded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _loadedScope != scope) return;
      vm.refreshProgressAndHistory();
    });
  }

  List<StreakDayActivity> _sevenDays(ProgressSummary summary) {
    if (summary.recentDays.length >= 7) {
      return summary.recentDays.sublist(summary.recentDays.length - 7);
    }
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
    return List<StreakDayActivity>.generate(7, (int index) {
      final int offset = 6 - index;
      final DateTime d = now.subtract(Duration(days: offset));
      final String iso =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      return StreakDayActivity(
        date: iso,
        weekdayLabel: labels[d.weekday - 1],
        isToday: offset == 0,
        completed: offset == 0 && summary.todayCompleted,
        hasDailyReport: offset == 0 && summary.todayReportSubmitted,
        hasStudy: false,
        hasChallenge: false,
        xpEarned: 0,
      );
    });
  }

  Future<void> _openReport() async {
    final DailyReportSubmitResult? result = await showDailyReportSheet(
      context: context,
      viewModel: widget.personalViewModel,
      workspaceViewModel: widget.workspaceViewModel,
    );
    if (result != null) {
      widget.onReportSubmitted?.call();
    }
  }

  void _openDetail() {
    showStreakDetailSheet(
      context: context,
      viewModel: widget.personalViewModel,
      workspaceViewModel: widget.workspaceViewModel,
      onReportSubmitted: widget.onReportSubmitted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return ListenableBuilder(
      listenable: widget.personalViewModel,
      builder: (BuildContext context, _) {
        final PersonalFlowViewModel vm = widget.personalViewModel;
        final ProgressSummary summary = vm.progressSummary;
        final bool isSignedIn = vm.authSession.isAuthenticated;
        final List<StreakDayActivity> weekDays = _sevenDays(summary);

        return MindClockCard(
          key: const ValueKey<String>('today-streak-card'),
          highlighted: isSignedIn && summary.todayCompleted,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.all(mc.space8),
                    decoration: BoxDecoration(
                      color: summary.todayCompleted
                          ? mc.sunriseSoft
                          : mc.primarySoft,
                      borderRadius: BorderRadius.circular(mc.radiusControl),
                      border: Border.all(
                        color:
                            summary.todayCompleted ? mc.sunrise : mc.primary,
                      ),
                    ),
                    child: MindClockIcon(
                      MindClockIconKind.flame,
                      color: mc.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: mc.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Text(
                              isSignedIn
                                  ? '${summary.streak} ngày Streak'
                                  : 'Streak theo ngày',
                              key: const ValueKey<String>('today-streak-count'),
                              style: mc.sectionTitleStyle,
                            ),
                            if (isSignedIn)
                              MindClockStatusPill(
                                key: const ValueKey<String>(
                                    'today-streak-status'),
                                label: summary.todayCompleted
                                    ? 'Đã giữ hôm nay'
                                    : 'Chưa giữ hôm nay',
                                accentWarm: !summary.todayCompleted,
                              ),
                          ],
                        ),
                        SizedBox(height: mc.space4 / 2),
                        Text(
                          isSignedIn
                              ? 'Kỷ lục ${summary.bestStreak} ngày · Hoàn thành 1 báo cáo = +1 streak'
                              : 'Đăng nhập ở tab Tôi để giữ streak bằng báo cáo ngày và theo dõi lịch 14 ngày.',
                          style: mc.captionStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (isSignedIn) ...<Widget>[
                SizedBox(height: mc.space12),
                Row(
                  children: weekDays.map((StreakDayActivity day) {
                    return Expanded(
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: mc.space4 / 2),
                        child: MindClockPressable(
                          semanticLabel:
                              '${day.weekdayLabel} ${day.completed ? "đã giữ" : "chưa giữ"}',
                          onPressed: _openDetail,
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: mc.space8),
                            decoration: BoxDecoration(
                              color: day.completed
                                  ? (day.isToday
                                      ? mc.sunriseSoft
                                      : mc.primarySoft)
                                  : mc.paper,
                              borderRadius:
                                  BorderRadius.circular(mc.radiusChip),
                              border: Border.all(
                                color: day.isToday
                                    ? mc.sunrise
                                    : (day.completed
                                        ? mc.primary
                                        : mc.outline),
                                width: day.isToday ? 1.5 : 1,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    day.isToday ? 'Nay' : day.weekdayLabel,
                                    style: mc.captionStyle.copyWith(
                                      fontSize: 11,
                                      fontWeight: day.isToday
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: day.completed
                                          ? mc.primary
                                          : mc.surface,
                                      border: Border.all(
                                        color: day.completed
                                            ? mc.primary
                                            : mc.outline,
                                      ),
                                    ),
                                    child: day.completed
                                        ? Center(
                                            child: MindClockIcon(
                                              MindClockIconKind.check,
                                              color: mc.onPrimary,
                                              size: 12,
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: <Widget>[
                    MindClockButton(
                      key: const ValueKey<String>('today-open-daily-report'),
                      label: summary.todayReportSubmitted
                          ? 'Đã báo cáo · Xem lại'
                          : 'Hoàn thành báo cáo hôm nay',
                      icon: MindClockIconKind.check,
                      expand: false,
                      onPressed: _openReport,
                    ),
                    MindClockButton(
                      key: const ValueKey<String>('today-open-streak-detail'),
                      label: 'Xem chuỗi',
                      icon: MindClockIconKind.calendar,
                      variant: MindClockButtonVariant.secondary,
                      expand: false,
                      onPressed: _openDetail,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
