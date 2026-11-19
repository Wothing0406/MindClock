import 'package:flutter/material.dart';

import '../../../../domain/models/daily_todo_task.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/models/timetable.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../view_models/guest_workspace_view_model.dart';

/// Card Lịch trình & To-do theo giờ trong ngày trên `TodayScreen`.
class DayScheduleTimelineCard extends StatelessWidget {
  const DayScheduleTimelineCard({
    super.key,
    required this.viewModel,
    required this.selectedDate,
    required this.now,
    required this.onSelectWeekday,
  });

  final GuestWorkspaceViewModel viewModel;
  final DateTime selectedDate;
  final DateTime now;
  final ValueChanged<int> onSelectWeekday;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final List<DayScheduleBlock> blocks =
        viewModel.timelineForDate(selectedDate);
    final int doneCount =
        blocks.where((DayScheduleBlock b) => b.isDone).length;
    final bool isViewingToday =
        formatDateIso(selectedDate) == formatDateIso(now);

    return MindClockCard(
      key: const ValueKey<String>('today-todo-timeline-card'),
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
                'Lịch trình & To-do',
                style: mc.sectionTitleStyle,
              ),
              MindClockStatusPill(
                label: blocks.isEmpty
                    ? '0 việc'
                    : '$doneCount/${blocks.length} việc xong',
                accentWarm: blocks.isNotEmpty && doneCount < blocks.length,
              ),
            ],
          ),
          SizedBox(height: mc.space4),
          Text(
            isViewingToday
                ? 'Hôm nay (${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}) · Gộp TKB, học thêm và To-do.'
                : '${WeeklyTimetable.weekdayLabel(selectedDate.weekday)} (${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')})',
            style: mc.captionStyle,
          ),
          SizedBox(height: mc.space12),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: <Widget>[
              MindClockButton(
                key: const ValueKey<String>('todo-add-btn'),
                label: 'Thêm việc / học thêm',
                icon: MindClockIconKind.plus,
                expand: false,
                onPressed: () => showAddDailyTaskSheet(
                  context: context,
                  viewModel: viewModel,
                  initialDate: selectedDate,
                ),
              ),
              MindClockButton(
                key: const ValueKey<String>('todo-open-calendar-timeline'),
                label: 'Xem lịch theo giờ',
                icon: MindClockIconKind.calendar,
                variant: MindClockButtonVariant.secondary,
                expand: false,
                onPressed: () => showDayCalendarTimelineSheet(
                  context: context,
                  viewModel: viewModel,
                  initialDate: selectedDate,
                  now: now,
                  onWeekdayChanged: onSelectWeekday,
                ),
              ),
            ],
          ),
          SizedBox(height: mc.space12),
          if (blocks.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(mc.space12),
              decoration: BoxDecoration(
                color: mc.paper,
                borderRadius: BorderRadius.circular(mc.radiusControl),
                border: Border.all(color: mc.outline),
              ),
              child: Text(
                'Chưa có tiết học hay việc tự thêm trong ngày này. Bấm "Thêm việc / học thêm" để lên lịch giờ và nhắc thông báo.',
                style: mc.captionStyle.copyWith(color: mc.ink),
              ),
            )
          else
            Column(
              children: blocks.map((DayScheduleBlock block) {
                return Padding(
                  padding: EdgeInsets.only(bottom: mc.space8),
                  child: _ScheduleBlockTile(
                    block: block,
                    status: block.statusAt(now, selectedDate),
                    onToggleDone: () =>
                        viewModel.toggleBlockDone(block, selectedDate),
                    onDelete: block.isFromTimetable
                        ? null
                        : () => viewModel.deleteDailyTodoTask(block.id),
                  ),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _ScheduleBlockTile extends StatelessWidget {
  const _ScheduleBlockTile({
    required this.block,
    required this.status,
    required this.onToggleDone,
    this.onDelete,
  });

  final DayScheduleBlock block;
  final ScheduleBlockStatus status;
  final VoidCallback onToggleDone;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final bool isDone = status == ScheduleBlockStatus.done;
    final bool isOngoing = status == ScheduleBlockStatus.ongoing;
    final bool isOverdue = status == ScheduleBlockStatus.overdue;

    final Color accentColor = isDone
        ? mc.primary
        : (isOngoing
            ? mc.sunrise
            : (isOverdue ? mc.error : mc.inkMuted));

    final String statusLabel = switch (status) {
      ScheduleBlockStatus.done => 'Đã xong',
      ScheduleBlockStatus.ongoing => 'Đang diễn ra',
      ScheduleBlockStatus.overdue => 'Quá giờ',
      ScheduleBlockStatus.upcoming => 'Sắp tới',
    };

    return Container(
      key: ValueKey<String>('todo-block-${block.id}'),
      padding: EdgeInsets.all(mc.space12),
      decoration: BoxDecoration(
        color: isDone ? mc.primarySoft : mc.paper,
        borderRadius: BorderRadius.circular(mc.radiusControl),
        border: Border.all(
          color: isOngoing ? mc.sunrise : (isDone ? mc.primary : mc.outline),
          width: isOngoing ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: mc.space8),
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
                      block.formattedTimeRange,
                      style: mc.captionStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: mc.ink,
                      ),
                    ),
                    Text(
                      '${block.category.labelVi} · $statusLabel',
                      style: mc.captionStyle.copyWith(color: accentColor),
                    ),
                  ],
                ),
                SizedBox(height: mc.space4),
                Text(
                  block.title,
                  style: mc.bodyStrongStyle.copyWith(
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (block.note.isNotEmpty) ...<Widget>[
                  SizedBox(height: mc.space4),
                  Text(block.note, style: mc.captionStyle),
                ],
              ],
            ),
          ),
          SizedBox(width: mc.space8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MindClockPressable(
                key: ValueKey<String>('todo-toggle-${block.id}'),
                selected: isDone,
                semanticLabel:
                    isDone ? 'Bỏ đánh dấu xong ${block.title}' : 'Đánh dấu Done ${block.title}',
                onPressed: onToggleDone,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: mc.space12,
                    vertical: mc.space8,
                  ),
                  decoration: BoxDecoration(
                    color: isDone ? mc.primary : mc.surface,
                    borderRadius: BorderRadius.circular(mc.radiusChip),
                    border: Border.all(
                      color: isDone ? mc.primary : mc.outline,
                    ),
                  ),
                  child: Text(
                    isDone ? 'Done' : 'Xong',
                    style: mc.chipLabelStyle.copyWith(
                      color: isDone ? mc.onPrimary : mc.ink,
                    ),
                  ),
                ),
              ),
              if (onDelete != null) ...<Widget>[
                SizedBox(height: mc.space4),
                MindClockPressable(
                  key: ValueKey<String>('todo-delete-${block.id}'),
                  semanticLabel: 'Xóa ${block.title}',
                  onPressed: onDelete,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: mc.space8,
                      vertical: mc.space4,
                    ),
                    child: Text(
                      'Xóa',
                      style: mc.captionStyle.copyWith(color: mc.error),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// BottomSheet thêm công việc / lịch học thêm / tự học trong ngày.
Future<void> showAddDailyTaskSheet({
  required BuildContext context,
  required GuestWorkspaceViewModel viewModel,
  required DateTime initialDate,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.mc.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.mc.radiusPaper),
      ),
    ),
    builder: (BuildContext sheetContext) {
      return _AddDailyTaskSheetBody(
        viewModel: viewModel,
        targetDate: initialDate,
      );
    },
  );
}

class _AddDailyTaskSheetBody extends StatefulWidget {
  const _AddDailyTaskSheetBody({
    required this.viewModel,
    required this.targetDate,
  });

  final GuestWorkspaceViewModel viewModel;
  final DateTime targetDate;

  @override
  State<_AddDailyTaskSheetBody> createState() => _AddDailyTaskSheetBodyState();
}

class _AddDailyTaskSheetBodyState extends State<_AddDailyTaskSheetBody> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DailyTodoCategory _category = DailyTodoCategory.extraClass;
  String? _subjectCode;
  int _startMinutes = 19 * 60 + 30;
  int _durationMinutes = 60;
  bool _remindOnTime = true;
  String? _errorVi;

  @override
  void initState() {
    super.initState();
    final List<String> selected = widget.viewModel.profile.selectedSubjectCodes;
    _subjectCode = selected.isNotEmpty ? selected.first : 'math';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _shiftStart(int delta) {
    setState(() {
      _startMinutes = ((_startMinutes + delta) % 1440 + 1440) % 1440;
    });
  }

  Future<void> _submit() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorVi = 'Nhập tên công việc hoặc buổi học thêm trước khi lưu.';
      });
      return;
    }
    await widget.viewModel.addDailyTodoTask(
      title: title,
      date: widget.targetDate,
      startMinutes: _startMinutes,
      durationMinutes: _durationMinutes,
      subjectCode: _subjectCode,
      category: _category,
      remindOnTime: _remindOnTime,
      note: _noteController.text,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Padding(
      padding: EdgeInsets.only(
        left: mc.space20,
        right: mc.space20,
        top: mc.space20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + mc.space20,
      ),
      child: SingleChildScrollView(
        key: const ValueKey<String>('todo-add-sheet'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Thêm lịch việc trong ngày', style: mc.sectionTitleStyle),
            SizedBox(height: mc.space4),
            Text(
              '${WeeklyTimetable.weekdayLabel(widget.targetDate.weekday)} · ${widget.targetDate.day.toString().padLeft(2, '0')}/${widget.targetDate.month.toString().padLeft(2, '0')}/${widget.targetDate.year}',
              style: mc.captionStyle,
            ),
            SizedBox(height: mc.space12),
            TextField(
              key: const ValueKey<String>('todo-title-input'),
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Tên việc / lớp học thêm',
                hintText: 'VD: Học thêm Toán thầy Minh, Làm 1 đề Hóa...',
                filled: true,
                fillColor: mc.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(mc.radiusControl),
                ),
              ),
            ),
            SizedBox(height: mc.space12),
            Text('Loại việc:', style: mc.bodyStrongStyle),
            SizedBox(height: mc.space8),
            Wrap(
              spacing: mc.space8,
              runSpacing: mc.space8,
              children: <DailyTodoCategory>[
                DailyTodoCategory.extraClass,
                DailyTodoCategory.selfStudy,
              ].map((DailyTodoCategory cat) {
                final bool selected = _category == cat;
                return MindClockPressable(
                  key: ValueKey<String>('todo-cat-${cat.id}'),
                  selected: selected,
                  semanticLabel: cat.labelVi,
                  onPressed: () => setState(() => _category = cat),
                  child: _SheetChoiceChip(
                    label: cat.labelVi,
                    selected: selected,
                  ),
                );
              }).toList(growable: false),
            ),
            SizedBox(height: mc.space12),
            Text('Giờ bắt đầu & thời lượng:', style: mc.bodyStrongStyle),
            SizedBox(height: mc.space8),
            Container(
              padding: EdgeInsets.all(mc.space12),
              decoration: BoxDecoration(
                color: mc.night,
                borderRadius: BorderRadius.circular(mc.radiusControl),
              ),
              child: Column(
                children: <Widget>[
                  Text(
                    '${formatMinutesClock(_startMinutes)} - ${formatMinutesClock(_startMinutes + _durationMinutes)}',
                    style: mc.sectionTitleStyle.copyWith(color: mc.nightText),
                  ),
                  SizedBox(height: mc.space8),
                  Wrap(
                    spacing: mc.space8,
                    runSpacing: mc.space8,
                    alignment: WrapAlignment.center,
                    children: <Widget>[
                      _TimeDeltaChip(label: '-15p', onPressed: () => _shiftStart(-15)),
                      _TimeDeltaChip(label: '+15p', onPressed: () => _shiftStart(15)),
                      _TimeDeltaChip(label: '+1g', onPressed: () => _shiftStart(60)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: mc.space8),
            Wrap(
              spacing: mc.space8,
              runSpacing: mc.space8,
              children: const <int>[30, 45, 60, 90].map((int mins) {
                return mins;
              }).map((int mins) {
                final bool selected = _durationMinutes == mins;
                return MindClockPressable(
                  key: ValueKey<String>('todo-dur-$mins'),
                  selected: selected,
                  semanticLabel: '$mins phút',
                  onPressed: () => setState(() => _durationMinutes = mins),
                  child: _SheetChoiceChip(
                    label: '$mins phút',
                    selected: selected,
                  ),
                );
              }).toList(growable: false),
            ),
            SizedBox(height: mc.space12),
            Text('Môn liên quan (tùy chọn):', style: mc.bodyStrongStyle),
            SizedBox(height: mc.space8),
            Wrap(
              spacing: mc.space8,
              runSpacing: mc.space8,
              children: SubjectCatalog.allSubjects.take(6).map((SubjectInfo s) {
                final bool selected = _subjectCode == s.code;
                return MindClockPressable(
                  selected: selected,
                  semanticLabel: s.nameVi,
                  onPressed: () => setState(() => _subjectCode = s.code),
                  child: _SheetChoiceChip(
                    label: s.nameVi,
                    selected: selected,
                  ),
                );
              }).toList(growable: false),
            ),
            SizedBox(height: mc.space12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Thông báo nhắc khi tới giờ',
                    style: mc.bodyStyle,
                  ),
                ),
                MindClockPressable(
                  key: const ValueKey<String>('todo-remind-toggle'),
                  selected: _remindOnTime,
                  semanticLabel: 'Thông báo nhắc khi tới giờ',
                  onPressed: () => setState(() => _remindOnTime = !_remindOnTime),
                  child: _SheetChoiceChip(
                    label: _remindOnTime ? 'Đang bật' : 'Tắt',
                    selected: _remindOnTime,
                  ),
                ),
              ],
            ),
            SizedBox(height: mc.space12),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
                filled: true,
                fillColor: mc.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(mc.radiusControl),
                ),
              ),
            ),
            if (_errorVi != null) ...<Widget>[
              SizedBox(height: mc.space8),
              MindClockNoticeBanner(message: _errorVi!),
            ],
            SizedBox(height: mc.space16),
            MindClockButton(
              key: const ValueKey<String>('todo-save-btn'),
              label: 'Lưu việc vào lịch',
              icon: MindClockIconKind.check,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Màn xem lịch trình ngày theo trục giờ Calendar 06:00–22:00 (phong cách Ảnh 1).
Future<void> showDayCalendarTimelineSheet({
  required BuildContext context,
  required GuestWorkspaceViewModel viewModel,
  required DateTime initialDate,
  required DateTime now,
  required ValueChanged<int> onWeekdayChanged,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.mc.night,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.mc.radiusPaper),
      ),
    ),
    builder: (BuildContext sheetContext) {
      return _CalendarDayTimelineSheet(
        viewModel: viewModel,
        initialDate: initialDate,
        now: now,
        onWeekdayChanged: onWeekdayChanged,
      );
    },
  );
}

class _CalendarDayTimelineSheet extends StatefulWidget {
  const _CalendarDayTimelineSheet({
    required this.viewModel,
    required this.initialDate,
    required this.now,
    required this.onWeekdayChanged,
  });

  final GuestWorkspaceViewModel viewModel;
  final DateTime initialDate;
  final DateTime now;
  final ValueChanged<int> onWeekdayChanged;

  @override
  State<_CalendarDayTimelineSheet> createState() =>
      _CalendarDayTimelineSheetState();
}

class _CalendarDayTimelineSheetState extends State<_CalendarDayTimelineSheet> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    widget.viewModel.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _pickWeekday(int weekday) {
    final int delta = weekday - _selectedDate.weekday;
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
    });
    widget.onWeekdayChanged(weekday);
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final List<DayScheduleBlock> blocks =
        widget.viewModel.timelineForDate(_selectedDate);
    final int mondayOffset = _selectedDate.weekday - 1;
    final DateTime monday = _selectedDate.subtract(Duration(days: mondayOffset));

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.86,
        child: Column(
          key: const ValueKey<String>('calendar-day-timeline-sheet'),
          children: <Widget>[
            Expanded(
              child: CustomScrollView(
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(mc.space16),
                      child: Wrap(
                        spacing: mc.space12,
                        runSpacing: mc.space8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                'Tháng ${_selectedDate.month} · ${_selectedDate.year}',
                                style: mc.sectionTitleStyle.copyWith(
                                  color: mc.nightText,
                                ),
                              ),
                              Text(
                                '${WeeklyTimetable.weekdayLabel(_selectedDate.weekday)}, ${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}',
                                style: mc.captionStyle.copyWith(
                                  color: mc.sunrise,
                                ),
                              ),
                            ],
                          ),
                          MindClockButton(
                            key: const ValueKey<String>('calendar-timeline-add'),
                            label: 'Thêm việc',
                            icon: MindClockIconKind.plus,
                            expand: false,
                            onPressed: () => showAddDailyTaskSheet(
                              context: context,
                              viewModel: widget.viewModel,
                              initialDate: _selectedDate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Dải T2..CN giống header Calendar (Ảnh 1), cuộn ngang an toàn ở 320dp/200%
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: mc.space12),
                      child: Row(
                        children: List<Widget>.generate(7, (int idx) {
                          final DateTime d = monday.add(Duration(days: idx));
                          final bool isSel = d.weekday == _selectedDate.weekday;
                          final String shortW = idx == 6 ? 'CN' : 'T${idx + 2}';
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: MindClockPressable(
                              selected: isSel,
                              semanticLabel: '$shortW ngày ${d.day}',
                              onPressed: () => _pickWeekday(d.weekday),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 50),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: mc.space8,
                                    vertical: mc.space8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSel ? mc.primary : mc.nightSurface,
                                    borderRadius:
                                        BorderRadius.circular(mc.radiusControl),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        shortW,
                                        style: mc.captionStyle.copyWith(
                                          color: mc.nightText,
                                        ),
                                      ),
                                      Text(
                                        '${d.day}',
                                        style: mc.bodyStrongStyle.copyWith(
                                          color: mc.nightText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: mc.space12)),
                  // Trục giờ 06:00 -> 22:00
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: mc.space16),
                    sliver: SliverList.builder(
                      itemCount: 17, // 06:00 đến 22:00
                      itemBuilder: (BuildContext ctx, int idx) {
                        final int hour = 6 + idx;
                        final int slotStart = hour * 60;
                        final int slotEnd = (hour + 1) * 60;
                        final List<DayScheduleBlock> hourBlocks = blocks
                            .where(
                              (DayScheduleBlock b) =>
                                  b.startMinutes >= slotStart &&
                                  b.startMinutes < slotEnd,
                            )
                            .toList(growable: false);

                        return Container(
                          padding: EdgeInsets.symmetric(vertical: mc.space8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: mc.nightSurface, width: 1),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 52),
                                child: Text(
                                  '${hour.toString().padLeft(2, '0')}:00',
                                  style: mc.captionStyle.copyWith(
                                    color: mc.nightText,
                                  ),
                                ),
                              ),
                              SizedBox(width: mc.space8),
                              Expanded(
                                child: hourBlocks.isEmpty
                                    ? const SizedBox(height: 28)
                                    : Column(
                                        children: hourBlocks.map(
                                          (DayScheduleBlock b) {
                                            final bool done = b.isDone;
                                            return Container(
                                              width: double.infinity,
                                              margin: EdgeInsets.only(
                                                bottom: mc.space4,
                                              ),
                                              padding: EdgeInsets.all(mc.space8),
                                              decoration: BoxDecoration(
                                                color: done
                                                    ? mc.primary
                                                    : mc.nightSurface,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  mc.radiusChip,
                                                ),
                                                border: Border(
                                                  left: BorderSide(
                                                    color: done
                                                        ? mc.sunrise
                                                        : mc.primary,
                                                    width: 4,
                                                  ),
                                                ),
                                              ),
                                              child: Wrap(
                                                spacing: mc.space8,
                                                runSpacing: mc.space8,
                                                alignment:
                                                    WrapAlignment.spaceBetween,
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                children: <Widget>[
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: <Widget>[
                                                      Text(
                                                        '${b.formattedTimeRange} · ${b.category.labelVi}',
                                                        style: mc.captionStyle
                                                            .copyWith(
                                                          color: mc.sunrise,
                                                        ),
                                                      ),
                                                      Text(
                                                        b.title,
                                                        style: mc
                                                            .bodyStrongStyle
                                                            .copyWith(
                                                          color: mc.nightText,
                                                          decoration: done
                                                              ? TextDecoration
                                                                  .lineThrough
                                                              : null,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  MindClockPressable(
                                                    semanticLabel:
                                                        'Đánh dấu Done ${b.title}',
                                                    onPressed: () => widget
                                                        .viewModel
                                                        .toggleBlockDone(
                                                      b,
                                                      _selectedDate,
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                        horizontal: mc.space8,
                                                        vertical: mc.space4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: done
                                                            ? mc.sunrise
                                                            : mc.night,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(
                                                          mc.radiusChip,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        done ? 'Done' : 'Xong',
                                                        style: mc.captionStyle
                                                            .copyWith(
                                                          color: done
                                                              ? mc.ink
                                                              : mc.nightText,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ).toList(growable: false),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(mc.space16),
              child: MindClockButton(
                key: const ValueKey<String>('calendar-timeline-close'),
                label: 'Đóng lịch ngày',
                variant: MindClockButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetChoiceChip extends StatelessWidget {
  const _SheetChoiceChip({
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mc.space12,
        vertical: mc.space8,
      ),
      decoration: BoxDecoration(
        color: selected ? mc.primarySoft : mc.paper,
        borderRadius: BorderRadius.circular(mc.radiusChip),
        border: Border.all(
          color: selected ? mc.primary : mc.outline,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Text(label, style: mc.chipLabelStyle),
    );
  }
}

class _TimeDeltaChip extends StatelessWidget {
  const _TimeDeltaChip({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return MindClockPressable(
      onPressed: onPressed,
      semanticLabel: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: mc.space12,
          vertical: mc.space8,
        ),
        decoration: BoxDecoration(
          color: mc.nightSurface,
          borderRadius: BorderRadius.circular(mc.radiusChip),
          border: Border.all(color: mc.sunrise),
        ),
        child: Text(
          label,
          style: mc.chipLabelStyle.copyWith(color: mc.nightText),
        ),
      ),
    );
  }
}
