import 'package:flutter/material.dart';

import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';

/// Màn hình `S03` Thiết lập nhanh lớp, nhiều môn, môn ưu tiên và mục tiêu.
class OnboardingSetupScreen extends StatefulWidget {
  const OnboardingSetupScreen({
    super.key,
    required this.initialProfile,
    required this.onSaveProfile,
    required this.onSkipLater,
    required this.onAlarmOnly,
  });

  final StudyProfile initialProfile;
  final ValueChanged<StudyProfile> onSaveProfile;
  final VoidCallback onSkipLater;
  final VoidCallback onAlarmOnly;

  @override
  State<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends State<OnboardingSetupScreen> {
  String? _selectedGrade;
  late Set<String> _selectedSubjects;
  late Map<String, PriorityLevel> _priorities;
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _selectedGrade = widget.initialProfile.gradeLevel;
    _selectedSubjects =
        Set<String>.from(widget.initialProfile.selectedSubjectCodes);
    _priorities = <String, PriorityLevel>{
      for (final PrioritySubject p in widget.initialProfile.prioritySubjects)
        p.subjectCode: p.level,
    };
    _goalController =
        TextEditingController(text: widget.initialProfile.goalLabel);
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  void _toggleSubject(String code) {
    setState(() {
      if (_selectedSubjects.contains(code)) {
        _selectedSubjects.remove(code);
        _priorities.remove(code);
      } else {
        _selectedSubjects.add(code);
      }
    });
  }

  void _togglePriority(String code) {
    setState(() {
      final PriorityLevel? current = _priorities[code];
      if (current == null) {
        if (_priorities.length < StudyProfile.maxPrioritySubjects) {
          _priorities[code] = PriorityLevel.high;
        }
      } else if (current == PriorityLevel.high) {
        _priorities[code] = PriorityLevel.medium;
      } else {
        _priorities.remove(code);
      }
    });
  }

  void _submit() {
    final List<PrioritySubject> priorityList = _priorities.entries
        .map(
          (MapEntry<String, PriorityLevel> entry) => PrioritySubject(
            subjectCode: entry.key,
            level: entry.value,
          ),
        )
        .toList(growable: false);

    widget.onSaveProfile(
      StudyProfile(
        gradeLevel: _selectedGrade,
        selectedSubjectCodes: _selectedSubjects.toList(growable: false),
        prioritySubjects: priorityList,
        goalLabel: _goalController.text.trim(),
        alarmOnlyMode: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return DecoratedBox(
      decoration: BoxDecoration(color: mc.paper),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mc.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  const MindClockStatusPill(label: AppStrings.guestBadge),
                  MindClockPressable(
                    key: const ValueKey<String>('onboarding-later'),
                    onPressed: widget.onSkipLater,
                    semanticLabel: AppStrings.setupLaterCta,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: mc.space12),
                      child: Text(
                        AppStrings.setupLaterCta,
                        style: mc.bodyStrongStyle.copyWith(color: mc.primary),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: mc.space12),
              Text(AppStrings.onboardingTitle, style: mc.screenTitleStyle),
              SizedBox(height: mc.space4),
              Text(AppStrings.onboardingSubtitle, style: mc.captionStyle),
              SizedBox(height: mc.space16),
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(AppStrings.selectGradeTitle, style: mc.sectionTitleStyle),
                    SizedBox(height: mc.space12),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children: SubjectCatalog.gradeLevels.map((String grade) {
                        final bool selected = _selectedGrade == grade;
                        return MindClockPressable(
                          key: ValueKey<String>('grade-$grade'),
                          selected: selected,
                          semanticLabel: grade,
                          onPressed: () {
                            setState(() {
                              _selectedGrade = selected ? null : grade;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: mc.space12,
                              vertical: mc.space8,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? mc.primary : mc.paper,
                              borderRadius: BorderRadius.circular(mc.radiusChip),
                              border: Border.all(
                                color: selected ? mc.primary : mc.outline,
                              ),
                            ),
                            child: Text(
                              grade,
                              style: mc.chipLabelStyle.copyWith(
                                color: selected ? mc.onPrimary : mc.ink,
                              ),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space16),
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.selectSubjectsTitle,
                      style: mc.sectionTitleStyle,
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      'Môn chưa có câu duyệt vẫn chọn được và đặt báo thức bình thường.',
                      style: mc.captionStyle,
                    ),
                    SizedBox(height: mc.space12),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children:
                          SubjectCatalog.allSubjects.map((SubjectInfo subject) {
                        final bool selected =
                            _selectedSubjects.contains(subject.code);
                        final String label = subject.hasApprovedQuestions
                            ? subject.nameVi
                            : '${subject.nameVi} (chưa có câu duyệt)';
                        return MindClockPressable(
                          key: ValueKey<String>('subject-${subject.code}'),
                          selected: selected,
                          semanticLabel: label,
                          onPressed: () => _toggleSubject(subject.code),
                          child: Container(
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
                            child: Text(
                              label,
                              style: mc.chipLabelStyle.copyWith(
                                color: mc.ink,
                              ),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space16),
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${AppStrings.selectPrioritiesTitle} (${_priorities.length}/${StudyProfile.maxPrioritySubjects})',
                      style: mc.sectionTitleStyle,
                    ),
                    SizedBox(height: mc.space8),
                    if (_selectedSubjects.isEmpty)
                      Text(
                        'Chọn ít nhất một môn ở mục 2 để gắn ưu tiên, hoặc bấm Để sau.',
                        style: mc.captionStyle,
                      )
                    else
                      Wrap(
                        spacing: mc.space8,
                        runSpacing: mc.space8,
                        children: _selectedSubjects.map((String code) {
                          final PriorityLevel? level = _priorities[code];
                          final bool isPriority = level != null;
                          final String name = SubjectCatalog.nameFor(code);
                          final String levelSuffix = level == PriorityLevel.high
                              ? ' · Cao'
                              : level == PriorityLevel.medium
                                  ? ' · Vừa'
                                  : '';
                          return MindClockPressable(
                            key: ValueKey<String>('priority-$code'),
                            selected: isPriority,
                            semanticLabel: 'Ưu tiên $name$levelSuffix',
                            onPressed: () => _togglePriority(code),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: mc.space12,
                                vertical: mc.space8,
                              ),
                              decoration: BoxDecoration(
                                color: isPriority ? mc.sunriseSoft : mc.paper,
                                borderRadius:
                                    BorderRadius.circular(mc.radiusChip),
                                border: Border.all(
                                  color: isPriority ? mc.sunrise : mc.outline,
                                  width: isPriority ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  if (isPriority) ...<Widget>[
                                    MindClockIcon(
                                      MindClockIconKind.check,
                                      color: mc.ink,
                                      size: 16,
                                    ),
                                    SizedBox(width: mc.space4),
                                  ],
                                  Text(
                                    '$name$levelSuffix',
                                    style: mc.chipLabelStyle,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(growable: false),
                      ),
                  ],
                ),
              ),
              SizedBox(height: mc.space16),
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(AppStrings.goalLabelTitle, style: mc.sectionTitleStyle),
                    SizedBox(height: mc.space8),
                    TextField(
                      key: const ValueKey<String>('onboarding-goal-input'),
                      controller: _goalController,
                      style: mc.bodyStyle,
                      decoration: InputDecoration(
                        hintText: AppStrings.goalLabelHint,
                        hintStyle: mc.captionStyle,
                        filled: true,
                        fillColor: mc.paper,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: mc.space12,
                          vertical: mc.space12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(mc.radiusControl),
                          borderSide: BorderSide(color: mc.outline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(mc.radiusControl),
                          borderSide: BorderSide(color: mc.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(mc.radiusControl),
                          borderSide: BorderSide(color: mc.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space20),
              MindClockButton(
                key: const ValueKey<String>('onboarding-save'),
                label: AppStrings.finishSetupAndSave,
                icon: MindClockIconKind.check,
                onPressed: _submit,
              ),
              SizedBox(height: mc.space12),
              MindClockButton(
                key: const ValueKey<String>('onboarding-alarm-only'),
                label: AppStrings.skipToAlarmOnly,
                icon: MindClockIconKind.bell,
                variant: MindClockButtonVariant.secondary,
                onPressed: widget.onAlarmOnly,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
