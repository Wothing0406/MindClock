import 'package:flutter/material.dart';

import '../../../../domain/models/daily_todo_task.dart';
import '../../../../domain/models/personal_flow_models.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../guest_shell/view_models/guest_workspace_view_model.dart';
import '../view_models/personal_flow_view_model.dart';

Future<DailyReportSubmitResult?> showDailyReportSheet({
  required BuildContext context,
  required PersonalFlowViewModel viewModel,
  GuestWorkspaceViewModel? workspaceViewModel,
}) async {
  return showModalBottomSheet<DailyReportSubmitResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.mc.paper,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: DailyReportSheet(
        viewModel: viewModel,
        workspaceViewModel: workspaceViewModel,
      ),
    ),
  );
}

class DailyReportSheet extends StatefulWidget {
  const DailyReportSheet({
    super.key,
    required this.viewModel,
    this.workspaceViewModel,
  });

  final PersonalFlowViewModel viewModel;
  final GuestWorkspaceViewModel? workspaceViewModel;

  @override
  State<DailyReportSheet> createState() => _DailyReportSheetState();
}

class _DailyReportSheetState extends State<DailyReportSheet> {
  final TextEditingController _noteController = TextEditingController();
  String _feeling = 'steady';
  int _tasksCompleted = 0;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    final int doneBlocks = widget.workspaceViewModel
            ?.timelineForDate(now)
            .where((DayScheduleBlock b) => b.isDone)
            .length ??
        0;
    _tasksCompleted = doneBlocks;

    final DailyReportRecord? todayReport = _findTodayReport(now);
    if (todayReport != null) {
      _feeling = todayReport.feeling;
      _noteController.text = todayReport.reflectionNote;
      if (todayReport.tasksCompleted > _tasksCompleted) {
        _tasksCompleted = todayReport.tasksCompleted;
      }
    }
  }

  DailyReportRecord? _findTodayReport(DateTime now) {
    final String ymd =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    for (final DailyReportRecord item in widget.viewModel.dailyReports) {
      if (item.localDate == ymd) return item;
    }
    return null;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final DailyReportSubmitResult? result =
        await widget.viewModel.submitDailyReport(
      tasksCompleted: _tasksCompleted,
      feeling: _feeling,
      reflectionNote: _noteController.text,
    );
    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (BuildContext context, _) {
        final PersonalFlowViewModel vm = widget.viewModel;
        final ProgressSummary summary = vm.progressSummary;
        final bool isAlreadyReported = summary.todayReportSubmitted;
        final List<String> sources = summary.todaySources;
        return Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                  mc.space20, mc.space16, mc.space12, mc.space8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Báo cáo học tập hôm nay',
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
                key: const ValueKey<String>('daily-report-content'),
                padding: EdgeInsets.fromLTRB(
                    mc.space20, mc.space8, mc.space20, mc.space24),
                children: <Widget>[
                  MindClockCard(
                    highlighted: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            MindClockIcon(
                              MindClockIconKind.flame,
                              color: summary.todayCompleted
                                  ? mc.primary
                                  : mc.sunrise,
                              size: 24,
                            ),
                            Text(
                              isAlreadyReported
                                  ? 'Đã hoàn thành báo cáo hôm nay'
                                  : 'Hoàn thành 1 báo cáo = +1 ngày Streak',
                              style: mc.sectionTitleStyle,
                            ),
                          ],
                        ),
                        SizedBox(height: mc.space8),
                        Text(
                          isAlreadyReported
                              ? 'Chuỗi hiện tại của bạn đang là ${summary.streak} ngày. Bạn có thể cập nhật lại ghi chú hôm nay bên dưới.'
                              : 'Xác nhận tổng kết ngày để giữ chuỗi streak (+5 XP, tối đa 1 lần/ngày) và cùng chăm Pet nhóm nếu có.',
                          style: mc.bodyStyle,
                        ),
                        SizedBox(height: mc.space12),
                        Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space8,
                          children: <Widget>[
                            MindClockStatusPill(
                              label: 'Việc xong: $_tasksCompleted',
                              accentWarm: _tasksCompleted > 0,
                            ),
                            MindClockStatusPill(
                              label: sources.contains('study')
                                  ? 'Đã có phiên học'
                                  : 'Chưa có phiên học',
                            ),
                            MindClockStatusPill(
                              label: sources.contains('challenge')
                                  ? 'Đã giải câu sáng'
                                  : 'Chưa giải câu sáng',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: mc.space16),
                  MindClockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Số việc hôm nay đã hoàn thành',
                            style: mc.bodyStrongStyle),
                        SizedBox(height: mc.space8),
                        Row(
                          children: <Widget>[
                            MindClockButton(
                              key: const ValueKey<String>(
                                  'daily-report-tasks-dec'),
                              label: '-1',
                              variant: MindClockButtonVariant.secondary,
                              expand: false,
                              onPressed: _tasksCompleted <= 0
                                  ? null
                                  : () => setState(() => _tasksCompleted -= 1),
                            ),
                            Expanded(
                              child: Text(
                                '$_tasksCompleted việc',
                                key: const ValueKey<String>(
                                    'daily-report-tasks-value'),
                                textAlign: TextAlign.center,
                                style: mc.sectionTitleStyle,
                              ),
                            ),
                            MindClockButton(
                              key: const ValueKey<String>(
                                  'daily-report-tasks-inc'),
                              label: '+1',
                              variant: MindClockButtonVariant.secondary,
                              expand: false,
                              onPressed: _tasksCompleted >= 50
                                  ? null
                                  : () => setState(() => _tasksCompleted += 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: mc.space12),
                  MindClockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Nhịp học hôm nay thế nào?',
                            style: mc.bodyStrongStyle),
                        SizedBox(height: mc.space8),
                        Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space8,
                          children: <({String id, String label})>[
                            (id: 'focused', label: 'Tập trung tốt'),
                            (id: 'steady', label: 'Ổn định · Đều nhịp'),
                            (id: 'tired', label: 'Hơi mệt nhưng vẫn cố'),
                          ].map((({String id, String label}) option) {
                            final bool selected = _feeling == option.id;
                            return MindClockPressable(
                              key: ValueKey<String>(
                                  'daily-report-feeling-${option.id}'),
                              selected: selected,
                              onPressed: () =>
                                  setState(() => _feeling = option.id),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: mc.space12,
                                  vertical: mc.space8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected ? mc.primary : mc.paper,
                                  borderRadius:
                                      BorderRadius.circular(mc.radiusChip),
                                  border: Border.all(
                                    color: selected ? mc.primary : mc.outline,
                                  ),
                                ),
                                child: Text(
                                  option.label,
                                  style: mc.chipLabelStyle.copyWith(
                                    color: selected ? mc.onPrimary : mc.ink,
                                  ),
                                ),
                              ),
                            );
                          }).toList(growable: false),
                        ),
                        SizedBox(height: mc.space12),
                        TextField(
                          key: const ValueKey<String>('daily-report-note'),
                          controller: _noteController,
                          maxLines: 3,
                          maxLength: 400,
                          decoration: const InputDecoration(
                            labelText: 'Ghi chú tổng kết ngắn (tùy chọn)',
                            hintText:
                                'Ví dụ: Xong đề Toán chương 2, mai ôn lại Lý.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (vm.dailyReportError != null) ...<Widget>[
                    SizedBox(height: mc.space12),
                    MindClockNoticeBanner(
                      message: vm.dailyReportError!,
                      isWarm: true,
                    ),
                  ],
                  if (!vm.authSession.isAuthenticated) ...<Widget>[
                    SizedBox(height: mc.space12),
                    const MindClockNoticeBanner(
                      message:
                          'Đăng nhập ở tab Tôi để lưu Báo cáo ngày và đồng bộ Streak lên máy chủ.',
                      isWarm: true,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  mc.space20, mc.space8, mc.space20, mc.space16),
              child: MindClockButton(
                key: const ValueKey<String>('daily-report-submit'),
                label: vm.dailyReportBusy
                    ? 'Đang lưu báo cáo...'
                    : isAlreadyReported
                        ? 'Cập nhật báo cáo hôm nay'
                        : 'Hoàn thành báo cáo · Giữ 1 Streak',
                icon: MindClockIconKind.check,
                onPressed: vm.dailyReportBusy || !vm.authSession.isAuthenticated
                    ? null
                    : _submit,
              ),
            ),
          ],
        );
      },
    );
  }
}
