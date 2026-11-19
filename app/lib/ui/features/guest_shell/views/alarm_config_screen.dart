import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/services/method_channel_media_picker_gateway.dart';
import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/personal_flow_models.dart';
import '../../../../domain/models/study_ai_models.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/models/timetable.dart';
import '../../../../domain/models/wake_suggestion.dart';
import '../../../../domain/services/media_picker_gateway.dart';
import '../../../../domain/services/morning_question_selector.dart';
import '../../../../domain/services/study_ai_gateway.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/math_formula_text.dart';
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
    this.mediaPickerGateway,
    this.studyAiGateway,
    required this.onSaved,
    required this.onCancel,
  });

  final GuestWorkspaceViewModel viewModel;
  final AlarmConfig? editingAlarm;
  final MediaPickerGateway? mediaPickerGateway;
  final StudyAiGateway? studyAiGateway;
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
  String? _customSoundPath;
  String? _customSoundLabel;
  bool _pickingCustomSound = false;
  bool _isPreviewPlaying = false;
  String? _soundStatusVi;
  late bool _vibrateEnabled;
  String? _autoSubjectCode;

  late int _classStartMinutes;
  late TextEditingController _commuteController;
  late TextEditingController _prepController;
  late TextEditingController _bufferController;
  String? _appliedSuggestionBanner;
  PersonalizedPracticeQuestion? _aiPreviewQuestion;
  bool _loadingAiPreview = false;
  String? _aiPreviewStatusVi;
  int _aiPreviewSeq = 0;

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
      _customSoundPath = existing.customSoundPath;
      _customSoundLabel = existing.customSoundLabel;
      _vibrateEnabled = existing.vibrateEnabled;
    } else {
      _hour = 6;
      _minute = 0;
      _repeatWeekdays = <int>{1, 2, 3, 4, 5};
      _enabled = true;
      _soundEnabled = true;
      _soundOption = AlarmSoundOption.gentleDawn;
      _vibrateEnabled = true;
    }
    _autoSubjectCode = _resolveAutoSubjectCode();

    final WakeSuggestionInput prefs = widget.viewModel.wakePreferences;
    _classStartMinutes = prefs.classStartMinutes;
    _commuteController =
        TextEditingController(text: prefs.commuteMinutes.toString());
    _prepController = TextEditingController(text: prefs.prepMinutes.toString());
    _bufferController =
        TextEditingController(text: prefs.bufferMinutes.toString());
    if (widget.studyAiGateway != null) {
      unawaited(_refreshAiChallengePreview());
    }
  }

  @override
  void didUpdateWidget(covariant AlarmConfigScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studyAiGateway != widget.studyAiGateway ||
        oldWidget.editingAlarm?.id != widget.editingAlarm?.id) {
      unawaited(_refreshAiChallengePreview());
    }
  }

  @override
  void dispose() {
    if (_isPreviewPlaying) {
      _mediaPicker.stopAudioPreview();
    }
    _commuteController.dispose();
    _prepController.dispose();
    _bufferController.dispose();
    super.dispose();
  }

  MediaPickerGateway get _mediaPicker =>
      widget.mediaPickerGateway ?? MethodChannelMediaPickerGateway();

  Future<void> _pickCustomAlarmAudio() async {
    if (_pickingCustomSound) return;
    await _mediaPicker.stopAudioPreview();
    setState(() {
      _isPreviewPlaying = false;
      _pickingCustomSound = true;
      _soundStatusVi = null;
    });
    final MediaPickResult res = await _mediaPicker.pickAlarmAudio();
    if (!mounted) return;
    setState(() {
      _pickingCustomSound = false;
      if (res.picked && res.localPath != null) {
        _soundOption = AlarmSoundOption.customLocal;
        _soundEnabled = true;
        _customSoundPath = res.localPath;
        _customSoundLabel = res.displayName ?? 'Nhạc báo thức đã chọn';
        _soundStatusVi = 'Đã lưu nhạc cục bộ: $_customSoundLabel.';
      } else if (!res.cancelled && res.errorMessageVi != null) {
        _soundStatusVi = res.errorMessageVi;
      }
    });
  }

  Future<void> _togglePreviewSound() async {
    if (_isPreviewPlaying) {
      await _mediaPicker.stopAudioPreview();
      if (!mounted) return;
      setState(() => _isPreviewPlaying = false);
      return;
    }
    if (_soundOption == AlarmSoundOption.silentVibrateOnly) return;
    if (_soundOption == AlarmSoundOption.customLocal &&
        (_customSoundPath == null || _customSoundPath!.isEmpty)) {
      setState(() {
        _soundStatusVi = 'Chưa chọn tệp nhạc trên máy — hãy chọn tệp trước khi nghe thử.';
      });
      return;
    }
    final bool started = await _mediaPicker.previewAudio(
      soundOption: _soundOption.id,
      customSoundPath: _customSoundPath,
      loop: false,
    );
    if (!mounted) return;
    setState(() {
      _isPreviewPlaying = started;
      _soundStatusVi = started
          ? 'Đang phát thử âm báo...'
          : 'Thiết bị chưa hỗ trợ phát thử âm báo trực tiếp tại đây.';
    });
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

  String? _resolveAutoSubjectCode() {
    final StudyProfile profile = widget.viewModel.profile;
    if (profile.prioritySubjectCodes.isNotEmpty) {
      return profile.prioritySubjectCodes.first;
    }
    if (profile.selectedSubjectCodes.isNotEmpty) {
      return profile.selectedSubjectCodes.first;
    }
    return null;
  }

  int _resolvePreviewWeekday() {
    if (_repeatWeekdays.isEmpty) {
      return DateTime.now().weekday;
    }
    final int today = DateTime.now().weekday;
    final List<int> sorted = _repeatWeekdays.toList()..sort();
    for (final int day in sorted) {
      if (day >= today) return day;
    }
    return sorted.first;
  }

  MorningQuestionProposal _resolveMorningProposal() {
    final AlarmConfig draftPreview = AlarmConfig(
      id: widget.editingAlarm?.id ?? 'preview',
      hour: _hour,
      minute: _minute,
      repeatWeekdays: _repeatWeekdays.toList()..sort(),
      enabled: _enabled,
      soundEnabled: _soundEnabled,
      vibrateEnabled: _vibrateEnabled,
      mode: AlarmMode.challenge,
      subjectRule: AlarmSubjectRule.todaySchedule,
      subjectCode: _autoSubjectCode,
    );
    return MorningQuestionSelector.resolveForAlarm(
      alarm: draftPreview,
      profile: widget.viewModel.profile,
      timetable: widget.viewModel.timetable,
      weekday: _resolvePreviewWeekday(),
    );
  }

  Future<void> _refreshAiChallengePreview() async {
    final StudyAiGateway? gateway = widget.studyAiGateway;
    final MorningQuestionProposal proposal = _resolveMorningProposal();
    _autoSubjectCode = proposal.subjectCode;
    if (gateway == null) {
      setState(() {
        _loadingAiPreview = false;
        _aiPreviewQuestion = null;
        _aiPreviewStatusVi = 'Đang dùng câu gợi ý cục bộ theo lịch học & ngân hàng chuẩn.';
      });
      return;
    }
    final int seq = ++_aiPreviewSeq;
    setState(() {
      _loadingAiPreview = true;
      _aiPreviewStatusVi = null;
    });
    final String rawGrade = (widget.viewModel.profile.gradeLevel ?? '').trim();
    final String gradeBand = rawGrade.isNotEmpty ? rawGrade : 'Lớp 11';
    try {
      final PersonalizedPracticeQuestion q =
          await gateway.generatePersonalizedQuestion(
        subjectCode: proposal.subjectCode,
        gradeLevel: gradeBand,
        topicHint: proposal.topicNameVi,
        difficulty: proposal.difficultyBand,
        idempotencyKey: 'alarm_preview_${proposal.subjectCode}_$seq',
      );
      if (!mounted || seq != _aiPreviewSeq) return;
      setState(() {
        _loadingAiPreview = false;
        _aiPreviewQuestion = q;
        _aiPreviewStatusVi = q.fallbackUsed
            ? 'AI bận — đang dùng câu dự phòng chuẩn theo TKB & hồ sơ.'
            : 'Đã tạo sẵn theo ${proposal.subjectNameVi} (${proposal.topicNameVi}).';
      });
    } on PersonalApiException catch (error) {
      if (!mounted || seq != _aiPreviewSeq) return;
      setState(() {
        _loadingAiPreview = false;
        _aiPreviewQuestion = null;
        _aiPreviewStatusVi =
            'Dùng câu cục bộ theo TKB (${error.messageVi}).';
      });
    } catch (_) {
      if (!mounted || seq != _aiPreviewSeq) return;
      setState(() {
        _loadingAiPreview = false;
        _aiPreviewQuestion = null;
        _aiPreviewStatusVi = 'Đang dùng câu dự phòng cục bộ theo TKB & hồ sơ.';
      });
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
      subjectCode: _autoSubjectCode,
    );
  }

  Future<void> _save() async {
    if (_isPreviewPlaying) {
      await _mediaPicker.stopAudioPreview();
    }
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
      customSoundPath: _soundOption == AlarmSoundOption.customLocal
          ? _customSoundPath
          : null,
      customSoundLabel: _soundOption == AlarmSoundOption.customLocal
          ? _customSoundLabel
          : null,
      vibrateEnabled: _vibrateEnabled,
      mode: AlarmMode.challenge,
      subjectRule: AlarmSubjectRule.todaySchedule,
      subjectCode: _autoSubjectCode,
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
    final StudyProfile profile = widget.viewModel.profile;
    final String rawGrade = (profile.gradeLevel ?? '').trim();
    final String gradeLabel = rawGrade.isNotEmpty ? rawGrade : 'THPT';
    final String selectedSubjectsLabel = profile.selectedSubjectCodes.isNotEmpty
        ? profile.selectedSubjectCodes
            .map(SubjectCatalog.nameFor)
            .take(4)
            .join(', ')
        : 'Toán (mặc định nếu chưa chọn môn)';

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
                          child: const _OutlineChip(label: '-15p'),
                        ),
                        MindClockPressable(
                          key: const ValueKey<String>('wake-class-plus-15'),
                          onPressed: () => _adjustClassStart(15),
                          semanticLabel: 'Tăng giờ học 15 phút',
                          child: const _OutlineChip(label: '+15p'),
                        ),
                        MindClockPressable(
                          key: const ValueKey<String>('wake-use-timetable'),
                          onPressed: _syncEarliestClassFromTimetable,
                          semanticLabel: 'Lấy tiết sớm nhất trong thời khóa biểu',
                          child: const _OutlineChip(label: 'Lấy từ TKB'),
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
                              if (widget.studyAiGateway != null) {
                                unawaited(_refreshAiChallengePreview());
                              }
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
                    if (_soundOption == AlarmSoundOption.customLocal) ...<Widget>[
                      SizedBox(height: mc.space12),
                      Text(
                        _customSoundLabel != null
                            ? 'Tệp đã chọn: $_customSoundLabel'
                            : 'Chưa chọn tệp nhạc. Nếu thiếu tệp lúc báo thức, máy tự chuyển về chuông mặc định.',
                        style: mc.captionStyle,
                      ),
                      SizedBox(height: mc.space8),
                      MindClockButton(
                        key: const ValueKey<String>('pick-custom-alarm-audio-btn'),
                        label: _pickingCustomSound
                            ? 'Đang mở trình chọn tệp...'
                            : 'Chọn nhạc MP3 / âm thanh từ máy',
                        icon: MindClockIconKind.bell,
                        variant: MindClockButtonVariant.secondary,
                        expand: false,
                        onPressed:
                            _pickingCustomSound ? null : _pickCustomAlarmAudio,
                      ),
                    ],
                    if (_soundOption != AlarmSoundOption.silentVibrateOnly) ...<Widget>[
                      SizedBox(height: mc.space8),
                      MindClockButton(
                        key: const ValueKey<String>('preview-alarm-audio-btn'),
                        label: _isPreviewPlaying ? 'Dừng nghe thử' : 'Nghe thử chuông',
                        icon: _isPreviewPlaying
                            ? MindClockIconKind.stop
                            : MindClockIconKind.volumeOn,
                        variant: MindClockButtonVariant.subtle,
                        expand: false,
                        onPressed: _togglePreviewSound,
                      ),
                    ],
                    if (_soundStatusVi != null) ...<Widget>[
                      SizedBox(height: mc.space8),
                      Text(_soundStatusVi!, style: mc.captionStyle),
                    ],
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
                key: const ValueKey<String>('alarm-auto-challenge-card'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          'Thử thách buổi sáng tự động',
                          style: mc.sectionTitleStyle,
                        ),
                        const MindClockStatusPill(
                          label: 'Mặc định Thử thách',
                        ),
                      ],
                    ),
                    SizedBox(height: mc.space8),
                    Builder(
                      builder: (BuildContext context) {
                        final MorningQuestionProposal proposal =
                            _resolveMorningProposal();
                        final String previewPrompt =
                            (_aiPreviewQuestion?.prompt.trim().isNotEmpty == true)
                                ? _aiPreviewQuestion!.prompt
                                : (proposal.sampleQuestionPrompt ??
                                    'Câu ôn nhanh ${proposal.subjectNameVi} · ${proposal.topicNameVi}.');
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Hồ sơ ($gradeLabel · $selectedSubjectsLabel) — ${proposal.explanationVi}',
                              style: mc.bodyStyle,
                            ),
                            SizedBox(height: mc.space12),
                            Container(
                              key: const ValueKey<String>(
                                  'alarm-ai-challenge-preview'),
                              width: double.infinity,
                              padding: EdgeInsets.all(mc.space12),
                              decoration: BoxDecoration(
                                color: mc.primarySoft,
                                borderRadius:
                                    BorderRadius.circular(mc.radiusControl),
                                border: Border.all(color: mc.primary),
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
                                        'Câu gợi ý sáng · ${proposal.subjectNameVi}',
                                        style: mc.bodyStrongStyle,
                                      ),
                                      MindClockStatusPill(
                                        label: _aiPreviewQuestion != null
                                            ? 'AI cá nhân hóa'
                                            : 'Cục bộ theo TKB',
                                        accentWarm: false,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: mc.space8),
                                  MathFormulaText(previewPrompt, style: mc.bodyStyle),
                                  if (_aiPreviewStatusVi != null) ...<Widget>[
                                    SizedBox(height: mc.space8),
                                    Text(
                                      _aiPreviewStatusVi!,
                                      style: mc.captionStyle,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: mc.space12),
                            MindClockButton(
                              key: const ValueKey<String>(
                                  'alarm-regenerate-challenge'),
                              label: _loadingAiPreview
                                  ? 'Đang tạo câu hỏi theo TKB...'
                                  : 'Tạo lại câu AI theo TKB',
                              icon: MindClockIconKind.sunrise,
                              variant: MindClockButtonVariant.secondary,
                              expand: false,
                              onPressed: _loadingAiPreview
                                  ? null
                                  : _refreshAiChallengePreview,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: mc.space12),
                    const MindClockNoticeBanner(
                      message: AppStrings.challengeModeNotice,
                    ),
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
