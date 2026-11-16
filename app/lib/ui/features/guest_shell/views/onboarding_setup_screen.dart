import 'package:flutter/material.dart';

import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';

/// Màn hình `S03` Thiết lập hồ sơ THPT Lớp 10–12, nhiều môn, avatar và xác nhận kế hoạch (`docs/07`).
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
  late TextEditingController _aliasController;
  late String _avatarId;
  String? _selectedGrade;
  late Set<String> _selectedSubjects;
  late Map<String, PriorityLevel> _priorities;
  late TextEditingController _goalController;

  static const List<Map<String, dynamic>> _availableAvatars = <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'sunrise',
      'label': 'Bình minh',
      'icon': MindClockIconKind.sunrise,
    },
    <String, dynamic>{
      'id': 'book',
      'label': 'Trang sách',
      'icon': MindClockIconKind.book,
    },
    <String, dynamic>{
      'id': 'clock',
      'label': 'Kỷ luật',
      'icon': MindClockIconKind.clock,
    },
    <String, dynamic>{
      'id': 'user',
      'label': 'Học sinh',
      'icon': MindClockIconKind.user,
    },
  ];

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(text: widget.initialProfile.alias);
    _avatarId = widget.initialProfile.avatarId.isNotEmpty
        ? widget.initialProfile.avatarId
        : 'sunrise';
    _selectedGrade = widget.initialProfile.gradeLevel;
    _selectedSubjects = Set<String>.from(widget.initialProfile.selectedSubjectCodes);
    _priorities = <String, PriorityLevel>{
      for (final PrioritySubject p in widget.initialProfile.prioritySubjects)
        p.subjectCode: p.level,
    };
    _goalController = TextEditingController(
      text: widget.initialProfile.goalLabel.isNotEmpty
          ? widget.initialProfile.goalLabel
          : 'Dậy đúng giờ và vững kiến thức THPT',
    );
  }

  @override
  void dispose() {
    _aliasController.dispose();
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
        alias: _aliasController.text.trim(),
        avatarId: _avatarId,
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
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: <Widget>[
                  const MindClockStatusPill(label: 'Khởi tạo kế hoạch THPT'),
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
              Text('Thiết lập lộ trình học tập', style: mc.screenTitleStyle),
              SizedBox(height: mc.space4),
              Text(
                'Chọn lớp THPT, các môn học thực tế và mục tiêu để MindClock gợi ý câu hỏi buổi sáng.',
                style: mc.captionStyle,
              ),
              SizedBox(height: mc.space16),

              // 1. Biệt danh & Avatar
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('1. Biệt danh & Avatar đại diện',
                        style: mc.sectionTitleStyle),
                    SizedBox(height: mc.space12),
                    TextField(
                      key: const ValueKey<String>('onboarding-alias-input'),
                      controller: _aliasController,
                      style: mc.bodyStyle,
                      decoration: InputDecoration(
                        labelText: 'Biệt danh của bạn',
                        hintText: 'Ví dụ: Minh Khang, Mai Anh...',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: mc.space12,
                          vertical: mc.space12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(mc.radiusControl),
                        ),
                      ),
                    ),
                    SizedBox(height: mc.space12),
                    Text('Chọn biểu tượng đại diện:', style: mc.captionStyle),
                    SizedBox(height: mc.space8),
                    Wrap(
                      spacing: mc.space12,
                      children: _availableAvatars.map((Map<String, dynamic> av) {
                        final String id = av['id'] as String;
                        final String label = av['label'] as String;
                        final MindClockIconKind iconKind =
                            av['icon'] as MindClockIconKind;
                        final bool selected = _avatarId == id;

                        return MindClockPressable(
                          key: ValueKey<String>('avatar-$id'),
                          selected: selected,
                          semanticLabel: label,
                          onPressed: () => setState(() => _avatarId = id),
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
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                MindClockIcon(
                                  iconKind,
                                  color: selected ? mc.primary : mc.ink,
                                  size: 18,
                                ),
                                SizedBox(width: mc.space8),
                                Text(
                                  label,
                                  style: mc.chipLabelStyle.copyWith(
                                    color: selected ? mc.primary : mc.ink,
                                  ),
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

              // 2. Chọn Khối Lớp THPT
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('2. Chọn khối lớp (THPT)', style: mc.sectionTitleStyle),
                    SizedBox(height: mc.space8),
                    Text(
                      'Chương trình chuẩn THPT theo Bộ GD&ĐT (Lớp 10, 11, 12).',
                      style: mc.captionStyle,
                    ),
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
                              _selectedGrade = grade;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: mc.space16,
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

              // 3. Chọn Môn học
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '3. Chọn môn học theo tổ hợp thực tế',
                      style: mc.sectionTitleStyle,
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      'Chọn các môn bạn đang học để hệ thống xếp lịch và đưa câu hỏi phù hợp.',
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
                            : '${subject.nameVi} (tự học)';
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
                                color: selected ? mc.primary : mc.ink,
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

              // 4. Môn ưu tiên
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '4. Chọn môn ưu tiên cải thiện (${_priorities.length}/${StudyProfile.maxPrioritySubjects})',
                      style: mc.sectionTitleStyle,
                    ),
                    SizedBox(height: mc.space8),
                    if (_selectedSubjects.isEmpty)
                      Text(
                        'Hãy chọn ít nhất 1 môn ở mục 3 để thiết lập ưu tiên.',
                        style: mc.captionStyle,
                      )
                    else
                      Wrap(
                        spacing: mc.space8,
                        runSpacing: mc.space8,
                        children: _selectedSubjects.map((String code) {
                          final PriorityLevel? level = _priorities[code];
                          final String name = SubjectCatalog.nameFor(code);
                          final String levelLabel = level == null
                              ? 'Chưa chọn'
                              : (level == PriorityLevel.high
                                  ? 'Ưu tiên cao'
                                  : 'Vừa phải');
                          return MindClockPressable(
                            key: ValueKey<String>('priority-$code'),
                            onPressed: () => _togglePriority(code),
                            semanticLabel: '$name: $levelLabel',
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: mc.space12,
                                vertical: mc.space8,
                              ),
                              decoration: BoxDecoration(
                                color: level == PriorityLevel.high
                                    ? mc.sunriseSoft
                                    : (level == PriorityLevel.medium
                                        ? mc.primarySoft
                                        : mc.paper),
                                borderRadius:
                                    BorderRadius.circular(mc.radiusChip),
                                border: Border.all(
                                  color: level != null
                                      ? (level == PriorityLevel.high
                                          ? mc.sunrise
                                          : mc.primary)
                                      : mc.outline,
                                ),
                              ),
                              child: Text(
                                '$name: $levelLabel',
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

              // 5. Mục tiêu học tập
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('5. Mục tiêu ngắn hạn', style: mc.sectionTitleStyle),
                    SizedBox(height: mc.space8),
                    TextField(
                      key: const ValueKey<String>('onboarding-goal-input'),
                      controller: _goalController,
                      style: mc.bodyStyle,
                      decoration: InputDecoration(
                        hintText: 'Ví dụ: Ôn thi học kỳ, vững Toán - Lý...',
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
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space16),

              // 6. Thẻ xác nhận kế hoạch
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
                            'Kế hoạch đề xuất của bạn',
                            style: mc.sectionTitleStyle.copyWith(color: mc.primary),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      '• Học sinh: ${_aliasController.text.isNotEmpty ? _aliasController.text : 'Học sinh'} (${_selectedGrade ?? 'Lớp 10'})\n'
                      '• Môn đang theo dõi: ${_selectedSubjects.length} môn (${_selectedSubjects.map(SubjectCatalog.nameFor).take(3).join(', ')}${_selectedSubjects.length > 3 ? '...' : ''})\n'
                      '• Báo thức tự động: 06:00 mỗi sáng có câu ôn tập gắn liền thời khóa biểu.',
                      style: mc.bodyStyle.copyWith(color: mc.ink),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space20),
              MindClockButton(
                key: const ValueKey<String>('onboarding-save'),
                label: 'Xác nhận kế hoạch & Vào Hôm nay',
                icon: MindClockIconKind.check,
                onPressed: _submit,
              ),
              SizedBox(height: mc.space12),
              MindClockButton(
                key: const ValueKey<String>('onboarding-alarm-only'),
                label: 'Để sau · Chỉ đặt báo thức',
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
