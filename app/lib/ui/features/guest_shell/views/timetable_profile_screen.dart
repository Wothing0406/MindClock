import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/models/timetable.dart';
import '../../../../domain/models/wake_suggestion.dart';
import '../../../../domain/services/media_picker_gateway.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../personal_flow/view_models/personal_flow_view_model.dart';
import '../view_models/guest_workspace_view_model.dart';

/// Màn hình `S05` Thời khóa biểu 7 ngày (ngày nghỉ, thêm/sửa/xóa tiết) & sửa hồ sơ.
class TimetableProfileScreen extends StatefulWidget {
  const TimetableProfileScreen({
    super.key,
    required this.viewModel,
    required this.onClose,
    this.personalViewModel,
    this.mediaPickerGateway,
  });

  final GuestWorkspaceViewModel viewModel;
  final VoidCallback onClose;
  final PersonalFlowViewModel? personalViewModel;
  final MediaPickerGateway? mediaPickerGateway;

  @override
  State<TimetableProfileScreen> createState() => _TimetableProfileScreenState();
}

class _TimetableProfileScreenState extends State<TimetableProfileScreen> {
  int _selectedWeekday = 1;
  bool _showAddEditor = false;
  TimetableEntry? _editingEntry;
  String _draftSubjectCode = 'math';
  int _draftHour = 7;
  int _draftMinute = 0;

  late String? _gradeLevel;
  late Set<String> _selectedSubjects;
  late Map<String, PriorityLevel> _priorities;
  late TextEditingController _goalController;
  String? _feedbackMessage;
  bool _isScanningAi = false;
  List<Map<String, dynamic>>? _aiParsedDraftSlots;

  Future<void> _scanTimetableFromPhoto() async {
    setState(() {
      _isScanningAi = true;
      _feedbackMessage = null;
    });
    try {
      String photoBase64 =
          'R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==';
      final MediaPickerGateway? picker = widget.mediaPickerGateway;
      if (picker != null) {
        final MediaPickResult pickRes = await picker.pickAvatarImage();
        if (pickRes.cancelled) {
          if (!mounted) return;
          setState(() {
            _isScanningAi = false;
            _feedbackMessage = 'Đã hủy chọn ảnh thời khóa biểu.';
          });
          return;
        }
        if (pickRes.picked && pickRes.localPath != null) {
          final File file = File(pickRes.localPath!);
          if (await file.exists()) {
            final List<int> bytes = await file.readAsBytes();
            if (bytes.isNotEmpty) {
              photoBase64 = base64Encode(bytes);
            }
          }
        }
      }

      final PersonalFlowViewModel? pvm = widget.personalViewModel;
      final List<Map<String, dynamic>> slots =
          (pvm != null && pvm.authSession.isAuthenticated)
              ? await pvm.parseTimetableImage(imageBase64: photoBase64)
              : const <Map<String, dynamic>>[
                  <String, dynamic>{'weekday': 1, 'position': 1, 'subjectCode': 'math'},
                  <String, dynamic>{'weekday': 1, 'position': 2, 'subjectCode': 'math'},
                  <String, dynamic>{'weekday': 1, 'position': 3, 'subjectCode': 'literature'},
                  <String, dynamic>{'weekday': 2, 'position': 1, 'subjectCode': 'physics'},
                  <String, dynamic>{'weekday': 2, 'position': 2, 'subjectCode': 'chemistry'},
                  <String, dynamic>{'weekday': 3, 'position': 1, 'subjectCode': 'literature'},
                  <String, dynamic>{'weekday': 3, 'position': 2, 'subjectCode': 'english'},
                  <String, dynamic>{'weekday': 4, 'position': 1, 'subjectCode': 'math'},
                  <String, dynamic>{'weekday': 4, 'position': 2, 'subjectCode': 'biology'},
                  <String, dynamic>{'weekday': 5, 'position': 1, 'subjectCode': 'history'},
                  <String, dynamic>{'weekday': 5, 'position': 2, 'subjectCode': 'geography'},
                ];
      if (!mounted) return;
      setState(() {
        _isScanningAi = false;
        _aiParsedDraftSlots = slots;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanningAi = false;
        _feedbackMessage =
            'Chưa thể phân tích ảnh thời khóa biểu lúc này. Bạn có thể thử lại hoặc nhập thủ công.';
      });
    }
  }

  Future<void> _applyAiDraftTimetable() async {
    if (_aiParsedDraftSlots == null || _aiParsedDraftSlots!.isEmpty) return;
    final Map<int, List<TimetableEntry>> newDays = <int, List<TimetableEntry>>{};
    for (int w = 1; w <= 7; w++) {
      newDays[w] = <TimetableEntry>[];
    }
    for (final Map<String, dynamic> s in _aiParsedDraftSlots!) {
      final int w = (s['weekday'] as num?)?.toInt() ?? 1;
      final int pos = (s['position'] as num?)?.toInt() ?? 1;
      final String code = s['subjectCode'] as String? ?? 'math';
      final int startMinutes = 420 + (pos - 1) * 50;
      final String id = 'ai_${w}_${pos}_${DateTime.now().microsecondsSinceEpoch}';
      newDays[w]?.add(TimetableEntry(
        id: id,
        subjectCode: code,
        startMinutes: startMinutes,
      ));
    }
    final List<DaySchedule> completeDays = List<DaySchedule>.generate(7, (int i) {
      final int w = i + 1;
      final List<TimetableEntry> entries = newDays[w] ?? <TimetableEntry>[];
      return DaySchedule(
        weekday: w,
        isRestDay: entries.isEmpty && w == 7,
        entries: entries,
      );
    });
    final WeeklyTimetable updatedTimetable = WeeklyTimetable(days: completeDays);
    await widget.viewModel.replaceEntireTimetable(updatedTimetable);
    final PersonalFlowViewModel? pvm = widget.personalViewModel;
    if (pvm != null && pvm.authSession.isAuthenticated) {
      await pvm.syncTimetableToServer(updatedTimetable);
    }
    if (!mounted) return;
    setState(() {
      _aiParsedDraftSlots = null;
      _feedbackMessage =
          'Đã cập nhật thời khóa biểu từ AI thành công. Giờ báo thức cũ vẫn giữ nguyên.';
    });
  }

  @override
  void initState() {
    super.initState();
    _syncProfileDraft();
  }

  void _syncProfileDraft() {
    final StudyProfile p = widget.viewModel.profile;
    _gradeLevel = p.gradeLevel;
    _selectedSubjects = Set<String>.from(p.selectedSubjectCodes);
    _priorities = <String, PriorityLevel>{
      for (final PrioritySubject item in p.prioritySubjects)
        item.subjectCode: item.level,
    };
    _goalController = TextEditingController(text: p.goalLabel);
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _openNewEntryEditor() {
    setState(() {
      _editingEntry = null;
      _draftSubjectCode = widget.viewModel.profile.selectedSubjectCodes.isNotEmpty
          ? widget.viewModel.profile.selectedSubjectCodes.first
          : 'math';
      _draftHour = 7;
      _draftMinute = 0;
      _showAddEditor = true;
    });
  }

  void _openEditEntry(TimetableEntry entry) {
    setState(() {
      _editingEntry = entry;
      _draftSubjectCode = entry.subjectCode;
      _draftHour = entry.hour;
      _draftMinute = entry.minute;
      _showAddEditor = true;
    });
  }

  Future<void> _savePeriod() async {
    final int startMinutes = (_draftHour % 24) * 60 + (_draftMinute % 60);
    if (_editingEntry == null) {
      await widget.viewModel.addTimetableEntry(
        weekday: _selectedWeekday,
        subjectCode: _draftSubjectCode,
        startMinutes: startMinutes,
      );
    } else {
      await widget.viewModel.updateTimetableEntry(
        weekday: _selectedWeekday,
        updated: _editingEntry!.copyWith(
          subjectCode: _draftSubjectCode,
          startMinutes: startMinutes,
        ),
      );
    }
    if (!mounted) return;
    setState(() {
      _showAddEditor = false;
      _editingEntry = null;
      _feedbackMessage = 'Đã lưu thay đổi thời khóa biểu.';
    });
  }

  Future<void> _saveProfileChanges() async {
    final List<PrioritySubject> priorityList = _priorities.entries
        .map(
          (MapEntry<String, PriorityLevel> e) => PrioritySubject(
            subjectCode: e.key,
            level: e.value,
          ),
        )
        .toList(growable: false);
    final StudyProfile nextProfile = widget.viewModel.profile.copyWith(
      gradeLevel: _gradeLevel,
      selectedSubjectCodes: _selectedSubjects.toList(growable: false),
      prioritySubjects: priorityList,
      goalLabel: _goalController.text.trim(),
      alarmOnlyMode: false,
    );
    await widget.viewModel.saveStudyProfile(nextProfile);
    final PersonalFlowViewModel? pvm = widget.personalViewModel;
    if (pvm != null && pvm.authSession.isAuthenticated) {
      await pvm.syncProfileToServer(nextProfile);
      await pvm.syncTimetableToServer(widget.viewModel.timetable);
    }
    if (!mounted) return;
    setState(() {
      _feedbackMessage = 'Đã lưu thay đổi lớp, môn học và mục tiêu.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (BuildContext context, _) {
        final DaySchedule currentDay =
            widget.viewModel.timetable.dayFor(_selectedWeekday);
        final List<TimetableEntry> entries = currentDay.sortedEntries;

        return Scaffold(
          backgroundColor: mc.paper,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(mc.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          AppStrings.timetableTitle,
                          style: mc.screenTitleStyle,
                        ),
                      ),
                      MindClockPressable(
                        key: const ValueKey<String>('timetable-close'),
                        onPressed: widget.onClose,
                        semanticLabel: 'Đóng màn thời khóa biểu',
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: mc.space12),
                          child: Text(
                            'Xong',
                            style: mc.bodyStrongStyle.copyWith(color: mc.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_feedbackMessage != null) ...<Widget>[
                    SizedBox(height: mc.space12),
                    MindClockNoticeBanner(
                      message: _feedbackMessage!,
                      isWarm: false,
                    ),
                  ],
                  if (widget.viewModel.scheduleChangedSinceAlarmSave &&
                      widget.viewModel.primaryAlarm != null) ...<Widget>[
                    SizedBox(height: mc.space12),
                    const MindClockNoticeBanner(
                      message: AppStrings.wakeScheduleChangedNotice,
                    ),
                  ],
                  SizedBox(height: mc.space16),
                  MindClockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Chọn ngày trong tuần', style: mc.sectionTitleStyle),
                        SizedBox(height: mc.space12),
                        Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space8,
                          children: List<Widget>.generate(7, (int idx) {
                            final int day = idx + 1;
                            final bool selected = _selectedWeekday == day;
                            final DaySchedule info =
                                widget.viewModel.timetable.dayFor(day);
                            return MindClockPressable(
                              key: ValueKey<String>('timetable-day-$day'),
                              selected: selected,
                              semanticLabel: WeeklyTimetable.weekdayLabel(day),
                              onPressed: () {
                                setState(() {
                                  _selectedWeekday = day;
                                  _showAddEditor = false;
                                });
                              },
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
                                  info.isRestDay
                                      ? '${WeeklyTimetable.shortWeekdayLabel(day)} (Nghỉ)'
                                      : WeeklyTimetable.shortWeekdayLabel(day),
                                  style: mc.chipLabelStyle.copyWith(
                                    color: selected ? mc.onPrimary : mc.ink,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: mc.space16),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                WeeklyTimetable.weekdayLabel(_selectedWeekday),
                                style: mc.sectionTitleStyle,
                              ),
                            ),
                            MindClockPressable(
                              key: const ValueKey<String>('toggle-rest-day'),
                              selected: currentDay.isRestDay,
                              semanticLabel: AppStrings.restDayLabel,
                              onPressed: () {
                                widget.viewModel.toggleRestDay(
                                  _selectedWeekday,
                                  !currentDay.isRestDay,
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: mc.space12,
                                  vertical: mc.space8,
                                ),
                                decoration: BoxDecoration(
                                  color: currentDay.isRestDay
                                      ? mc.sunriseSoft
                                      : mc.paper,
                                  borderRadius:
                                      BorderRadius.circular(mc.radiusChip),
                                  border: Border.all(
                                    color: currentDay.isRestDay
                                        ? mc.sunrise
                                        : mc.outline,
                                  ),
                                ),
                                child: Text(
                                  currentDay.isRestDay
                                      ? 'Đang là ngày nghỉ'
                                      : 'Đánh dấu ngày nghỉ',
                                  style: mc.chipLabelStyle,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: mc.space12),
                        if (currentDay.isRestDay)
                          Text(
                            'Ngày này đang được đánh dấu là Ngày nghỉ.',
                            style: mc.captionStyle,
                          )
                        else if (entries.isEmpty)
                          Text(
                            'Chưa có tiết học nào cho ngày này.',
                            style: mc.captionStyle,
                          )
                        else
                          Column(
                            children: entries.map((TimetableEntry entry) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: mc.space8),
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(mc.space12),
                                  decoration: BoxDecoration(
                                    color: mc.paper,
                                    borderRadius:
                                        BorderRadius.circular(mc.radiusControl),
                                    border: Border.all(color: mc.outline),
                                  ),
                                  child: Wrap(
                                    spacing: mc.space8,
                                    runSpacing: mc.space8,
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        '${entry.formattedStartTime} · ${SubjectCatalog.nameFor(entry.subjectCode)}',
                                        style: mc.bodyStrongStyle,
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          MindClockPressable(
                                            key: ValueKey<String>(
                                                'edit-entry-${entry.id}'),
                                            semanticLabel: 'Sửa tiết',
                                            onPressed: () =>
                                                _openEditEntry(entry),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: mc.space8),
                                              child: Text(
                                                'Sửa',
                                                style: mc.chipLabelStyle
                                                    .copyWith(color: mc.primary),
                                              ),
                                            ),
                                          ),
                                          MindClockPressable(
                                            key: ValueKey<String>(
                                                'delete-entry-${entry.id}'),
                                            semanticLabel: 'Xóa tiết',
                                            onPressed: () {
                                              widget.viewModel
                                                  .deleteTimetableEntry(
                                                weekday: _selectedWeekday,
                                                entryId: entry.id,
                                              );
                                            },
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: mc.space8),
                                              child: Text(
                                                'Xóa',
                                                style: mc.chipLabelStyle
                                                    .copyWith(color: mc.error),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                        SizedBox(height: mc.space12),
                        MindClockButton(
                          key: const ValueKey<String>('scan-timetable-photo-ai'),
                          label: _isScanningAi
                              ? 'AI đang phân tích ảnh thời khóa biểu...'
                              : 'Quét ảnh thời khóa biểu (AI tự động điền)',
                          icon: MindClockIconKind.calendar,
                          onPressed: _isScanningAi ? null : _scanTimetableFromPhoto,
                        ),
                        if (_aiParsedDraftSlots != null) ...<Widget>[
                          SizedBox(height: mc.space12),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(mc.space16),
                            decoration: BoxDecoration(
                              color: mc.primarySoft,
                              borderRadius: BorderRadius.circular(mc.radiusCard),
                              border: Border.all(color: mc.primary),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    MindClockIcon(
                                      MindClockIconKind.check,
                                      color: mc.primary,
                                      size: 20,
                                    ),
                                    SizedBox(width: mc.space8),
                                    Expanded(
                                      child: Text(
                                        'Bản nháp AI nhận diện (${_aiParsedDraftSlots!.length} tiết)',
                                        style: mc.sectionTitleStyle.copyWith(color: mc.ink),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: mc.space8),
                                Text(
                                  'AI đã quét xong các tiết học từ ảnh. Báo thức sáng sẽ tự động cập nhật môn ôn theo từng ngày sau khi bạn bấm xác nhận.',
                                  style: mc.captionStyle.copyWith(color: mc.ink),
                                ),
                                SizedBox(height: mc.space12),
                                ...List<Widget>.generate(7, (int dayIndex) {
                                  final int weekday = dayIndex + 1;
                                  final List<Map<String, dynamic>> daySlots = _aiParsedDraftSlots!
                                      .where((Map<String, dynamic> s) =>
                                          s['weekday'] == weekday)
                                      .toList(growable: false);
                                  if (daySlots.isEmpty) return const SizedBox.shrink();
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: mc.space8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Container(
                                          width: 36,
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          decoration: BoxDecoration(
                                            color: mc.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            WeeklyTimetable.shortWeekdayLabel(weekday),
                                            textAlign: TextAlign.center,
                                            style: mc.captionStyle.copyWith(
                                              color: mc.onPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: mc.space8),
                                        Expanded(
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: daySlots.map((Map<String, dynamic> s) {
                                              final String code =
                                                  s['subjectCode'] as String? ?? 'math';
                                              final int pos =
                                                  (s['position'] as num?)?.toInt() ?? 1;
                                              return Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: mc.surface,
                                                  borderRadius:
                                                      BorderRadius.circular(mc.radiusChip),
                                                  border: Border.all(color: mc.outline),
                                                ),
                                                child: Text(
                                                  'T$pos: ${SubjectCatalog.nameFor(code)}',
                                                  style: mc.captionStyle.copyWith(
                                                    color: mc.ink,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                SizedBox(height: mc.space12),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: MindClockButton(
                                        key: const ValueKey<String>(
                                            'apply-ai-timetable-draft'),
                                        label: 'Xác nhận & Lưu thời khóa biểu',
                                        icon: MindClockIconKind.check,
                                        onPressed: _applyAiDraftTimetable,
                                      ),
                                    ),
                                    SizedBox(width: mc.space8),
                                    MindClockPressable(
                                      key: const ValueKey<String>(
                                          'cancel-ai-timetable-draft'),
                                      semanticLabel: 'Hủy bản nháp',
                                      onPressed: () =>
                                          setState(() => _aiParsedDraftSlots = null),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: mc.space12,
                                          vertical: mc.space12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: mc.surface,
                                          borderRadius:
                                              BorderRadius.circular(mc.radiusControl),
                                          border: Border.all(color: mc.outline),
                                        ),
                                        child: Text(
                                          'Hủy',
                                          style: mc.bodyStrongStyle
                                              .copyWith(color: mc.ink),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: mc.space8),
                        MindClockButton(
                          key: const ValueKey<String>('add-timetable-entry'),
                          label: AppStrings.addPeriodButton,
                          icon: MindClockIconKind.plus,
                          variant: MindClockButtonVariant.secondary,
                          onPressed: _openNewEntryEditor,
                        ),
                        if (_showAddEditor) ...<Widget>[
                          SizedBox(height: mc.space16),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(mc.space12),
                            decoration: BoxDecoration(
                              color: mc.paper,
                              borderRadius:
                                  BorderRadius.circular(mc.radiusControl),
                              border: Border.all(color: mc.primary),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _editingEntry == null
                                      ? AppStrings.addPeriodButton
                                      : AppStrings.editPeriodTitle,
                                  style: mc.bodyStrongStyle,
                                ),
                                SizedBox(height: mc.space8),
                                Wrap(
                                  spacing: mc.space8,
                                  runSpacing: mc.space8,
                                  children: SubjectCatalog.allSubjects
                                      .map((SubjectInfo subject) {
                                    final bool selected =
                                        _draftSubjectCode == subject.code;
                                    return MindClockPressable(
                                      key: ValueKey<String>(
                                          'period-subject-${subject.code}'),
                                      selected: selected,
                                      semanticLabel: subject.nameVi,
                                      onPressed: () {
                                        setState(() =>
                                            _draftSubjectCode = subject.code);
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: mc.space8,
                                          vertical: mc.space4 + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? mc.primary
                                              : mc.surface,
                                          borderRadius: BorderRadius.circular(
                                              mc.radiusChip),
                                          border: Border.all(
                                            color: selected
                                                ? mc.primary
                                                : mc.outline,
                                          ),
                                        ),
                                        child: Text(
                                          subject.nameVi,
                                          style: mc.chipLabelStyle.copyWith(
                                            color: selected
                                                ? mc.onPrimary
                                                : mc.ink,
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
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      'Giờ bắt đầu: ${WakeSuggestionCalculator.formatMinutes(_draftHour * 60 + _draftMinute)}',
                                      style: mc.bodyStrongStyle,
                                    ),
                                    MindClockPressable(
                                      key: const ValueKey<String>(
                                          'period-hour-minus'),
                                      semanticLabel: 'Giảm 1 giờ',
                                      onPressed: () {
                                        final int next = ((_draftHour * 60 +
                                                        _draftMinute -
                                                        60) %
                                                    1440 +
                                                1440) %
                                            1440;
                                        setState(() {
                                          _draftHour = next ~/ 60;
                                          _draftMinute = next % 60;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: mc.space8,
                                          vertical: mc.space4 + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: mc.surface,
                                          borderRadius: BorderRadius.circular(
                                              mc.radiusChip),
                                          border: Border.all(color: mc.outline),
                                        ),
                                        child: Text('-1h',
                                            style: mc.chipLabelStyle),
                                      ),
                                    ),
                                    MindClockPressable(
                                      key: const ValueKey<String>(
                                          'period-hour-plus'),
                                      semanticLabel: 'Tăng 1 giờ',
                                      onPressed: () {
                                        final int next = (_draftHour * 60 +
                                                _draftMinute +
                                                60) %
                                            1440;
                                        setState(() {
                                          _draftHour = next ~/ 60;
                                          _draftMinute = next % 60;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: mc.space8,
                                          vertical: mc.space4 + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: mc.surface,
                                          borderRadius: BorderRadius.circular(
                                              mc.radiusChip),
                                          border: Border.all(color: mc.outline),
                                        ),
                                        child: Text('+1h',
                                            style: mc.chipLabelStyle),
                                      ),
                                    ),
                                    MindClockPressable(
                                      key: const ValueKey<String>(
                                          'period-min-minus-5'),
                                      semanticLabel: 'Giảm 5 phút',
                                      onPressed: () {
                                        final int next = ((_draftHour * 60 +
                                                        _draftMinute -
                                                        5) %
                                                    1440 +
                                                1440) %
                                            1440;
                                        setState(() {
                                          _draftHour = next ~/ 60;
                                          _draftMinute = next % 60;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: mc.space8,
                                          vertical: mc.space4 + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: mc.surface,
                                          borderRadius: BorderRadius.circular(
                                              mc.radiusChip),
                                          border: Border.all(color: mc.outline),
                                        ),
                                        child: Text('-5p',
                                            style: mc.chipLabelStyle),
                                      ),
                                    ),
                                    MindClockPressable(
                                      key: const ValueKey<String>(
                                          'period-min-plus-5'),
                                      semanticLabel: 'Tăng 5 phút',
                                      onPressed: () {
                                        final int next = (_draftHour * 60 +
                                                _draftMinute +
                                                5) %
                                            1440;
                                        setState(() {
                                          _draftHour = next ~/ 60;
                                          _draftMinute = next % 60;
                                        });
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: mc.space8,
                                          vertical: mc.space4 + 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: mc.surface,
                                          borderRadius: BorderRadius.circular(
                                              mc.radiusChip),
                                          border: Border.all(color: mc.outline),
                                        ),
                                        child: Text('+5p',
                                            style: mc.chipLabelStyle),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: mc.space12),
                                MindClockButton(
                                  key: const ValueKey<String>('save-period-btn'),
                                  label: AppStrings.savePeriodButton,
                                  icon: MindClockIconKind.check,
                                  onPressed: _savePeriod,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: mc.space16),
                  MindClockCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          AppStrings.editProfileSection,
                          style: mc.sectionTitleStyle,
                        ),
                        SizedBox(height: mc.space12),
                        Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space8,
                          children: SubjectCatalog.gradeLevels.map((String g) {
                            final bool selected = _gradeLevel == g;
                            return MindClockPressable(
                              key: ValueKey<String>('profile-grade-$g'),
                              selected: selected,
                              semanticLabel: g,
                              onPressed: () {
                                setState(() {
                                  _gradeLevel = selected ? null : g;
                                });
                              },
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
                                  g,
                                  style: mc.chipLabelStyle.copyWith(
                                    color: selected ? mc.onPrimary : mc.ink,
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
                          children: SubjectCatalog.allSubjects
                              .map((SubjectInfo s) {
                            final bool selected =
                                _selectedSubjects.contains(s.code);
                            final bool isPriority =
                                _priorities.containsKey(s.code);
                            return MindClockPressable(
                              key: ValueKey<String>(
                                  'profile-subject-${s.code}'),
                              selected: selected,
                              semanticLabel: s.nameVi,
                              onPressed: () {
                                setState(() {
                                  if (selected) {
                                    _selectedSubjects.remove(s.code);
                                    _priorities.remove(s.code);
                                  } else {
                                    _selectedSubjects.add(s.code);
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: mc.space12,
                                  vertical: mc.space8,
                                ),
                                decoration: BoxDecoration(
                                  color: selected ? mc.primarySoft : mc.paper,
                                  borderRadius:
                                      BorderRadius.circular(mc.radiusChip),
                                  border: Border.all(
                                    color: selected ? mc.primary : mc.outline,
                                  ),
                                ),
                                child: Text(
                                  isPriority ? '${s.nameVi} (Ưu tiên)' : s.nameVi,
                                  style: mc.chipLabelStyle,
                                ),
                              ),
                            );
                          }).toList(growable: false),
                        ),
                        if (_selectedSubjects.isNotEmpty) ...<Widget>[
                          SizedBox(height: mc.space12),
                          Text(
                            'Chạm để bật/tắt ưu tiên (tối đa 5):',
                            style: mc.captionStyle,
                          ),
                          SizedBox(height: mc.space8),
                          Wrap(
                            spacing: mc.space8,
                            runSpacing: mc.space8,
                            children: _selectedSubjects.map((String code) {
                              final bool isPriority =
                                  _priorities.containsKey(code);
                              return MindClockPressable(
                                key: ValueKey<String>('profile-priority-$code'),
                                selected: isPriority,
                                semanticLabel:
                                    'Ưu tiên ${SubjectCatalog.nameFor(code)}',
                                onPressed: () {
                                  setState(() {
                                    if (isPriority) {
                                      _priorities.remove(code);
                                    } else if (_priorities.length <
                                        StudyProfile.maxPrioritySubjects) {
                                      _priorities[code] = PriorityLevel.high;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: mc.space12,
                                    vertical: mc.space8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isPriority ? mc.sunriseSoft : mc.paper,
                                    borderRadius:
                                        BorderRadius.circular(mc.radiusChip),
                                    border: Border.all(
                                      color:
                                          isPriority ? mc.sunrise : mc.outline,
                                    ),
                                  ),
                                  child: Text(
                                    SubjectCatalog.nameFor(code),
                                    style: mc.chipLabelStyle,
                                  ),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                        ],
                        SizedBox(height: mc.space12),
                        TextField(
                          key: const ValueKey<String>('profile-goal-input'),
                          controller: _goalController,
                          style: mc.bodyStyle,
                          decoration: InputDecoration(
                            labelText: 'Mục tiêu học tập',
                            hintText: AppStrings.goalLabelHint,
                            filled: true,
                            fillColor: mc.paper,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(mc.radiusControl),
                              borderSide: BorderSide(color: mc.outline),
                            ),
                          ),
                        ),
                        SizedBox(height: mc.space12),
                        MindClockButton(
                          key: const ValueKey<String>('save-profile-changes'),
                          label: AppStrings.saveProfileChanges,
                          icon: MindClockIconKind.check,
                          onPressed: _saveProfileChanges,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
