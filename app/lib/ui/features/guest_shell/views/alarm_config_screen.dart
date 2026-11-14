import 'package:flutter/material.dart';

import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/models/timetable.dart';
import '../../../../domain/models/wake_suggestion.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../view_models/guest_workspace_view_model.dart';

/// Màn hình `S06` Cấu hình báo thức local & Gợi ý giờ dậy có xác nhận.
class AlarmConfigScreen extends StatefulWidget {
  const AlarmConfigScreen({
    super.key,
    required this.viewModel,
    this.editingAlarm,
    required this.onSaved,
    required this.onCancel,
  });

  final GuestWorkspaceViewModel viewModel;
  final AlarmConfig? editingAlarm;
  final ValueChanged<String> onSaved;
  final VoidCallback onCancel;

  @override
  State<AlarmConfigScreen> createState() => _AlarmConfigScreenState();
}

class _AlarmConfigScreenState extends State<AlarmConfigScreen> {
  late int _hour;
  late int _minute;
  late Set<int> _repeatWeekdays;
  late bool _enabled;
  late bool _soundEnabled;
  late AlarmSoundOption _soundOption;
  late bool _vibrateEnabled;
  late AlarmMode _mode;
  String? _subjectCode;

  late int _classStartMinutes;
  late TextEditingController _commuteController;
  late TextEditingController _prepController;
  late TextEditingController _bufferController;
  String? _appliedSuggestionBanner;

  @override
  void initState() {
    super.initState();
    final AlarmConfig? existing = widget.editingAlarm;
    if (existing != null) {
      _hour = existing.hour;
      _minute = existing.minute;
      _repeatWeekdays = Set<int>.from(existing.repeatWeekdays);
      _enabled = existing.enabled;
      _soundEnabled = existing.soundEnabled;
      _soundOption = existing.soundOption;
      _vibrateEnabled = existing.vibrateEnabled;
      _mode = existing.mode;
      _subjectCode = existing.subjectCode;
    } else {
      _hour = 6;
      _minute = 0;
      _repeatWeekdays = <int>{1, 2, 3, 4, 5};
      _enabled = true;
      _soundEnabled = true;
      _soundOption = AlarmSoundOption.gentleDawn;
      _vibrateEnabled = true;
      _mode = AlarmMode.normal;
      final List<String> userSubjects =
          widget.viewModel.profile.selectedSubjectCodes;
      _subjectCode = userSubjects.isNotEmpty ? userSubjects.first : null;
    }

    final WakeSuggestionInput prefs = widget.viewModel.wakePreferences;
    _classStartMinutes = prefs.classStartMinutes;
    _commuteController =
        TextEditingController(text: prefs.commuteMinutes.toString());
    _prepController = TextEditingController(text: prefs.prepMinutes.toString());
    _bufferController =
        TextEditingController(text: prefs.bufferMinutes.toString());
  }

  @override
  void dispose() {
    _commuteController.dispose();
    _prepController.dispose();
    _bufferController.dispose();
    super.dispose();
  }

  void _adjustTime({int deltaHours = 0, int deltaMinutes = 0}) {
    final int currentTotal = _hour * 60 + _minute;
    final int nextTotal =
        ((currentTotal + deltaHours * 60 + deltaMinutes) % 1440 + 1440) % 1440;
    setState(() {
      _hour = nextTotal ~/ 60;
      _minute = nextTotal % 60;
      _appliedSuggestionBanner = null;
    });
  }

  void _adjustClassStart(int deltaMinutes) {
    setState(() {
      _classStartMinutes =
          ((_classStartMinutes + deltaMinutes) % 1440 + 1440) % 1440;
    });
  }

  void _syncEarliestClassFromTimetable() {
    for (int weekday = 1; weekday <= 7; weekday++) {
      final TimetableEntry? first =
          widget.viewModel.timetable.earliestEntryFor(weekday);
      if (first != null) {
        setState(() {
          _classStartMinutes = first.startMinutes;
        });
        return;
      }
    }
  }

  WakeSuggestionInput _currentWakeInput() {
    final int commute = int.tryParse(_commuteController.text.trim()) ?? -1;
    final int prep = int.tryParse(_prepController.text.trim()) ?? -1;
    final int buffer = int.tryParse(_bufferController.text.trim()) ?? -1;
    return WakeSuggestionInput(
      classStartMinutes: _classStartMinutes,
      commuteMinutes: commute,
      prepMinutes: prep,
      bufferMinutes: buffer,
      subjectCode: _subjectCode,
    );
  }

  Future<void> _save() async {
    final List<int> sortedWeekdays = _repeatWeekdays.toList()..sort();
    final String alarmId = widget.editingAlarm?.id ??
        'alarm_${DateTime.now().microsecondsSinceEpoch}';
    final AlarmConfig draft = AlarmConfig(
      id: alarmId,
      hour: _hour,
      minute: _minute,
      repeatWeekdays: sortedWeekdays,
      enabled: _enabled,
      soundEnabled: _soundEnabled && _soundOption != AlarmSoundOption.silentVibrateOnly,
      soundOption: _soundOption,
      vibrateEnabled: _vibrateEnabled,
      mode: _mode,
      subjectCode: _subjectCode,
    );

    final WakeSuggestionInput wakeInput = _currentWakeInput();
    final WakeSuggestionInput? validWakeInput =
        WakeSuggestionCalculator.calculate(wakeInput).isValidInput
            ? wakeInput
            : null;

    final result = await widget.viewModel.saveAlarm(
      draft,
      usedWakePreferences: validWakeInput,
    );
    if (!mounted) return;
    widget.onSaved(result.messageVi);
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final WakeSuggestionInput wakeInput = _currentWakeInput();
    final WakeSuggestionResult suggestion =
        widget.viewModel.previewWakeSuggestion(wakeInput);
    final String formattedSelected =
        '${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}';

    final bool hasUnapprovedSelectedSubject =
        _subjectCode != null && !SubjectCatalog.isApproved(_subjectCode!);

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
                      AppStrings.alarmConfigTitle,
                      style: mc.screenTitleStyle,
                    ),
                  ),
                  MindClockPressable(
                    key: const ValueKey<String>('alarm-config-close'),
                    onPressed: widget.onCancel,
                    semanticLabel: 'Đóng cấu hình báo thức',
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: mc.space12),
                      child: Text(
                        'Đóng',
                        style: mc.bodyStrongStyle.copyWith(color: mc.primary),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: mc.space12),
              if (!widget.viewModel.isOsBridgeConnected) ...<Widget>[
                const MindClockNoticeBanner(
                  message: AppStrings.alarmOsUnboundExplain,
                  isWarm: false,
                ),
                SizedBox(height: mc.space16),
              ] else if (widget.viewModel.needsOsPermissions) ...<Widget>[
                const MindClockNoticeBanner(
                  message: AppStrings.alarmPermissionMissingExplain,
                ),
                SizedBox(height: mc.space8),
                ...widget.viewModel.missingPermissionActions.map(
                  (action) => Padding(
                    padding: EdgeInsets.only(bottom: mc.space8),
                    child: MindClockButton(
                      key: ValueKey<String>(
                        'config-perm-${action.wireAction}',
                      ),
                      label: widget.viewModel.labelForPermissionAction(action),
                      icon: MindClockIconKind.warning,
                      variant: MindClockButtonVariant.secondary,
                      onPressed: () =>
                          widget.viewModel.openPermissionSettings(action),
                    ),
                  ),
                ),
                SizedBox(height: mc.space8),
              ],
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
                    Text(
                      AppStrings.alarmTimeTitle,
                      style: mc.captionStyle.copyWith(color: mc.sunrise),
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      formattedSelected,
                      key: const ValueKey<String>('alarm-selected-time-text'),
                      style: mc.alarmHeroStyle,
                    ),
                    SizedBox(height: mc.space12),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children: <Widget>[
                        _TimeStepChip(
                          key: const ValueKey<String>('alarm-hour-minus'),
                          label: '-1 giờ',
                          onPressed: () => _adjustTime(deltaHours: -1),
                        ),
                        _TimeStepChip(
                          key: const ValueKey<String>('alarm-hour-plus'),
                          label: '+1 giờ',
                          onPressed: () => _adjustTime(deltaHours: 1),
                        ),
                        _TimeStepChip(
                          key: const ValueKey<String>('alarm-min-minus-5'),
                          label: '-5 phút',
                          onPressed: () => _adjustTime(deltaMinutes: -5),
                        ),
                        _TimeStepChip(
                          key: const ValueKey<String>('alarm-min-plus-5'),
                          label: '+5 phút',
                          onPressed: () => _adjustTime(deltaMinutes: 5),
                        ),
                        _TimeStepChip(
                          key: const ValueKey<String>('alarm-min-minus-1'),
                          label: '-1 phút',
                          onPressed: () => _adjustTime(deltaMinutes: -1),
                        ),
                        _TimeStepChip(
                          key: const ValueKey<String>('alarm-min-plus-1'),
                          label: '+1 phút',
                          onPressed: () => _adjustTime(deltaMinutes: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_appliedSuggestionBanner != null) ...<Widget>[
                SizedBox(height: mc.space12),
                MindClockNoticeBanner(
                  message: _appliedSuggestionBanner!,
                  isWarm: false,
                ),
              ],
              SizedBox(height: mc.space16),
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.wakeSuggestionTitle,
                      style: mc.sectionTitleStyle,
                    ),
                    SizedBox(height: mc.space8),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          'Giờ vào học: ${WakeSuggestionCalculator.formatMinutes(_classStartMinutes)}',
                          style: mc.bodyStrongStyle,
                        ),
                        MindClockPressable(
                          key: const ValueKey<String>('wake-class-minus-15'),
                          onPressed: () => _adjustClassStart(-15),
                          semanticLabel: 'Giảm giờ học 15 phút',
                          child: _OutlineChip(label: '-15p'),
                        ),
                        MindClockPressable(
                          key: const ValueKey<String>('wake-class-plus-15'),
                          onPressed: () => _adjustClassStart(15),
                          semanticLabel: 'Tăng giờ học 15 phút',
                          child: _OutlineChip(label: '+15p'),
                        ),
                        MindClockPressable(
                          key: const ValueKey<String>('wake-use-timetable'),
                          onPressed: _syncEarliestClassFromTimetable,
                          semanticLabel: 'Lấy tiết sớm nhất trong thời khóa biểu',
                          child: _OutlineChip(label: 'Lấy từ TKB'),
                        ),
                      ],
                    ),
                    SizedBox(height: mc.space12),
                    Wrap(
                      spacing: mc.space12,
                      runSpacing: mc.space12,
                      children: <Widget>[
                        _MinuteField(
                          fieldKey: const ValueKey<String>('wake-commute-input'),
                          label: 'Đi đường (phút)',
                          controller: _commuteController,
                          onChanged: (_) => setState(() {}),
                        ),
                        _MinuteField(
                          fieldKey: const ValueKey<String>('wake-prep-input'),
                          label: 'Chuẩn bị (phút)',
                          controller: _prepController,
                          onChanged: (_) => setState(() {}),
                        ),
                        _MinuteField(
                          fieldKey: const ValueKey<String>('wake-buffer-input'),
                          label: 'Đệm (phút)',
                          controller: _bufferController,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                    SizedBox(height: mc.space12),
                    if (!suggestion.isValidInput)
                      MindClockNoticeBanner(
                        message: suggestion.validationErrorVi ??
                            'Thông số thời gian chưa hợp lệ.',
                      )
                    else ...<Widget>[
                      Text(
                        AppStrings.wakeFormulaLabel,
                        style: mc.captionStyle,
                      ),
                      SizedBox(height: mc.space4),
                      Text(
                        suggestion.formulaTextVi,
                        key: const ValueKey<String>('wake-formula-text'),
                        style: mc.bodyStrongStyle.copyWith(color: mc.primary),
                      ),
                      SizedBox(height: mc.space4),
                      Text(suggestion.explanationVi, style: mc.captionStyle),
                      SizedBox(height: mc.space12),
                      MindClockButton(
                        key: const ValueKey<String>('apply-wake-suggestion'),
                        label:
                            '${AppStrings.useWakeSuggestionButton} (${suggestion.formattedWakeTime})',
                        variant: MindClockButtonVariant.secondary,
                        icon: MindClockIconKind.check,
                        onPressed: () {
                          setState(() {
                            _hour = suggestion.hour;
                            _minute = suggestion.minute;
                            _appliedSuggestionBanner =
                                'Đã chọn ${suggestion.formattedWakeTime} vào đồng hồ ở trên. Bấm Lưu cấu hình báo thức để lưu.';
                          });
                        },
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
                    Text(AppStrings.alarmRepeatTitle, style: mc.sectionTitleStyle),
                    SizedBox(height: mc.space12),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children: List<Widget>.generate(7, (int idx) {
                        final int day = idx + 1;
                        final bool selected = _repeatWeekdays.contains(day);
                        return MindClockPressable(
                          key: ValueKey<String>('repeat-day-$day'),
                          selected: selected,
                          semanticLabel: WeeklyTimetable.weekdayLabel(day),
                          onPressed: () {
                            setState(() {
                              if (selected) {
                                _repeatWeekdays.remove(day);
                              } else {
                                _repeatWeekdays.add(day);
                              }
                            });
                          },
                          child: Container(
                            width: mc.minTouchTarget,
                            height: mc.minTouchTarget,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? mc.primary : mc.paper,
                              borderRadius:
                                  BorderRadius.circular(mc.radiusChip),
                              border: Border.all(
                                color: selected ? mc.primary : mc.outline,
                              ),
                            ),
                            child: Text(
                              WeeklyTimetable.shortWeekdayLabel(day),
                              style: mc.chipLabelStyle.copyWith(
                                color: selected ? mc.onPrimary : mc.ink,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space16),
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(AppStrings.alarmSoundTitle, style: mc.sectionTitleStyle),
                    SizedBox(height: mc.space12),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children: AlarmSoundOption.values.map((AlarmSoundOption opt) {
                        final bool selected = _soundOption == opt;
                        return MindClockPressable(
                          key: ValueKey<String>('sound-${opt.id}'),
                          selected: selected,
                          semanticLabel: opt.labelVi,
                          onPressed: () {
                            setState(() {
                              _soundOption = opt;
                              _soundEnabled =
                                  opt != AlarmSoundOption.silentVibrateOnly;
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
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(opt.labelVi, style: mc.chipLabelStyle),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                    SizedBox(height: mc.space12),
                    _ToggleRow(
                      toggleKey: const ValueKey<String>('alarm-vibrate-toggle'),
                      label: AppStrings.alarmVibrateLabel,
                      value: _vibrateEnabled,
                      onChanged: (bool next) =>
                          setState(() => _vibrateEnabled = next),
                    ),
                    SizedBox(height: mc.space8),
                    _ToggleRow(
                      toggleKey: const ValueKey<String>('alarm-enabled-toggle'),
                      label: AppStrings.alarmEnabledLabel,
                      value: _enabled,
                      onChanged: (bool next) => setState(() => _enabled = next),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space16),
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(AppStrings.alarmSubjectTitle, style: mc.sectionTitleStyle),
                    SizedBox(height: mc.space12),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children: <Widget>[
                        MindClockPressable(
                          key: const ValueKey<String>('alarm-subject-none'),
                          selected: _subjectCode == null,
                          semanticLabel: 'Chỉ báo thức',
                          onPressed: () => setState(() => _subjectCode = null),
                          child: _ChoiceTag(
                            label: 'Chỉ báo thức',
                            selected: _subjectCode == null,
                          ),
                        ),
                        ...SubjectCatalog.allSubjects.map((SubjectInfo subject) {
                          final bool selected = _subjectCode == subject.code;
                          return MindClockPressable(
                            key: ValueKey<String>(
                                'alarm-subject-${subject.code}'),
                            selected: selected,
                            semanticLabel: subject.nameVi,
                            onPressed: () =>
                                setState(() => _subjectCode = subject.code),
                            child: _ChoiceTag(
                              label: subject.nameVi,
                              selected: selected,
                            ),
                          );
                        }),
                      ],
                    ),
                    if (hasUnapprovedSelectedSubject) ...<Widget>[
                      SizedBox(height: mc.space12),
                      MindClockNoticeBanner(
                        message:
                            'Môn ${SubjectCatalog.nameFor(_subjectCode!)} chưa có câu ôn được duyệt. '
                            'Bạn vẫn đặt được chuông bình thường; khi reo app sẽ chạy chế độ thường / Chỉ báo thức để không làm kẹt chuông.',
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
                    Text(AppStrings.alarmModeTitle, style: mc.sectionTitleStyle),
                    SizedBox(height: mc.space12),
                    _ModeOptionCard(
                      cardKey: const ValueKey<String>('alarm-mode-normal'),
                      title: AppStrings.normalModeTitle,
                      description: AppStrings.normalModeDesc,
                      selected: _mode == AlarmMode.normal,
                      onPressed: () => setState(() => _mode = AlarmMode.normal),
                    ),
                    SizedBox(height: mc.space8),
                    _ModeOptionCard(
                      cardKey: const ValueKey<String>('alarm-mode-challenge'),
                      title: AppStrings.challengeModeTitle,
                      description: AppStrings.challengeModeNotice,
                      selected: _mode == AlarmMode.challenge,
                      onPressed: () =>
                          setState(() => _mode = AlarmMode.challenge),
                    ),
                    if (_mode == AlarmMode.challenge) ...<Widget>[
                      SizedBox(height: mc.space12),
                      const MindClockNoticeBanner(
                        message: AppStrings.challengeModeNotice,
                      ),
                      if (_subjectCode == null) ...<Widget>[
                        SizedBox(height: mc.space8),
                        const MindClockNoticeBanner(
                          message:
                              'Bạn đang chọn Chỉ báo thức cùng chế độ thử thách: '
                              'hệ thống sẽ lấy một câu ôn dự phòng nếu môn đã chọn có câu duyệt, '
                              'hoặc dừng khẩn cấp 1 chạm bất kỳ lúc nào.',
                          isWarm: false,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              SizedBox(height: mc.space20),
              MindClockButton(
                key: const ValueKey<String>('save-alarm-config'),
                label: AppStrings.saveAlarmButton,
                icon: MindClockIconKind.check,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeStepChip extends StatelessWidget {
  const _TimeStepChip({
    super.key,
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

class _OutlineChip extends StatelessWidget {
  const _OutlineChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: mc.space12,
        vertical: mc.space8,
      ),
      decoration: BoxDecoration(
        color: mc.paper,
        borderRadius: BorderRadius.circular(mc.radiusChip),
        border: Border.all(color: mc.primary),
      ),
      child: Text(
        label,
        style: mc.chipLabelStyle.copyWith(color: mc.primary),
      ),
    );
  }
}

class _ChoiceTag extends StatelessWidget {
  const _ChoiceTag({
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

class _MinuteField extends StatelessWidget {
  const _MinuteField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: mc.captionStyle),
          SizedBox(height: mc.space4),
          TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            style: mc.bodyStrongStyle,
            decoration: InputDecoration(
              filled: true,
              fillColor: mc.paper,
              contentPadding: EdgeInsets.symmetric(
                horizontal: mc.space12,
                vertical: mc.space8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(mc.radiusChip),
                borderSide: BorderSide(color: mc.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(mc.radiusChip),
                borderSide: BorderSide(color: mc.outline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.toggleKey,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final Key toggleKey;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Row(
      children: <Widget>[
        Expanded(child: Text(label, style: mc.bodyStyle)),
        MindClockPressable(
          key: toggleKey,
          selected: value,
          semanticLabel: label,
          onPressed: () => onChanged(!value),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: mc.space12,
              vertical: mc.space8,
            ),
            decoration: BoxDecoration(
              color: value ? mc.primary : mc.paper,
              borderRadius: BorderRadius.circular(mc.radiusChip),
              border: Border.all(color: value ? mc.primary : mc.outline),
            ),
            child: Text(
              value ? 'Đang bật' : 'Đang tắt',
              style: mc.chipLabelStyle.copyWith(
                color: value ? mc.onPrimary : mc.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  const _ModeOptionCard({
    required this.cardKey,
    required this.title,
    required this.description,
    required this.selected,
    required this.onPressed,
  });

  final Key cardKey;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return MindClockPressable(
      key: cardKey,
      selected: selected,
      semanticLabel: title,
      onPressed: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(mc.space12),
        decoration: BoxDecoration(
          color: selected ? mc.primarySoft : mc.paper,
          borderRadius: BorderRadius.circular(mc.radiusControl),
          border: Border.all(
            color: selected ? mc.primary : mc.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: mc.bodyStrongStyle),
            SizedBox(height: mc.space4),
            Text(description, style: mc.captionStyle),
          ],
        ),
      ),
    );
  }
}
