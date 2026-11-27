import 'package:flutter/material.dart';

import '../../../../data/services/method_channel_media_picker_gateway.dart';
import '../../../../domain/models/daily_study_plan.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../../domain/services/media_picker_gateway.dart';
import '../../../../domain/services/rule_based_plan_generator.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_avatar_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../view_models/guest_workspace_view_model.dart';

/// Màn hình `S03` Thiết lập hồ sơ THPT Lớp 10–12, nhiều môn, avatar và xác nhận kế hoạch (`docs/07`).
class OnboardingSetupScreen extends StatefulWidget {
  const OnboardingSetupScreen({
    super.key,
    required this.initialProfile,
    required this.onSaveProfile,
    required this.onSkipLater,
    required this.onAlarmOnly,
    this.mediaPickerGateway,
    this.workspaceViewModel,
  });

  final StudyProfile initialProfile;
  final ValueChanged<StudyProfile> onSaveProfile;
  final VoidCallback onSkipLater;
  final VoidCallback onAlarmOnly;
  final MediaPickerGateway? mediaPickerGateway;
  final GuestWorkspaceViewModel? workspaceViewModel;

  @override
  State<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends State<OnboardingSetupScreen> {
  late TextEditingController _aliasController;
  late String _avatarId;
  String? _customAvatarPath;
  String? _avatarStatusVi;
  bool _pickingAvatar = false;
  String? _selectedGrade;
  late Set<String> _selectedSubjects;
  late Map<String, PriorityLevel> _priorities;
  late Map<String, SubjectSelfAssessment> _selfAssessments;
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController(text: widget.initialProfile.alias);
    _avatarId = widget.initialProfile.avatarId.isNotEmpty
        ? widget.initialProfile.avatarId
        : 'sunrise';
    _customAvatarPath = widget.initialProfile.customAvatarPath;
    _selectedGrade = widget.initialProfile.gradeLevel;
    _selectedSubjects = Set<String>.from(widget.initialProfile.selectedSubjectCodes);
    _priorities = <String, PriorityLevel>{
      for (final PrioritySubject p in widget.initialProfile.prioritySubjects)
        p.subjectCode: p.level,
    };
    _selfAssessments = <String, SubjectSelfAssessment>{
      for (final String code in _selectedSubjects)
        code: widget.initialProfile.selfAssessments[code] ??
            (_priorities[code] == PriorityLevel.high
                ? SubjectSelfAssessment.examPrep
                : SubjectSelfAssessment.basic),
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
        _selfAssessments.remove(code);
      } else {
        _selectedSubjects.add(code);
        _selfAssessments[code] = SubjectSelfAssessment.basic;
      }
    });
  }

  void _cycleSelfAssessment(String code) {
    setState(() {
      final SubjectSelfAssessment current =
          _selfAssessments[code] ?? SubjectSelfAssessment.basic;
      final SubjectSelfAssessment next = current.next;
      _selfAssessments[code] = next;
      if (next == SubjectSelfAssessment.examPrep) {
        if (_priorities.length < StudyProfile.maxPrioritySubjects ||
            _priorities.containsKey(code)) {
          _priorities[code] = PriorityLevel.high;
        }
      } else if (next == SubjectSelfAssessment.beginner) {
        if (_priorities.length < StudyProfile.maxPrioritySubjects ||
            _priorities.containsKey(code)) {
          _priorities[code] = PriorityLevel.medium;
        }
      } else {
        _priorities.remove(code);
      }
    });
  }

  DailyStudyPlan _buildDraftPlan() {
    final List<PrioritySubject> priorityList = _priorities.entries
        .map(
          (MapEntry<String, PriorityLevel> entry) => PrioritySubject(
            subjectCode: entry.key,
            level: entry.value,
          ),
        )
        .toList(growable: false);
    return RuleBasedPlanGenerator.generateDraft(
      gradeLevel: _selectedGrade,
      selectedSubjectCodes: _selectedSubjects.toList(growable: false),
      selfAssessments: _selfAssessments,
      prioritySubjects: priorityList,
      goalLabel: _goalController.text.trim(),
    );
  }

  Future<void> _pickCustomAvatar() async {
    if (_pickingAvatar) return;
    setState(() {
      _pickingAvatar = true;
      _avatarStatusVi = null;
    });
    final MediaPickerGateway gateway =
        widget.mediaPickerGateway ?? MethodChannelMediaPickerGateway();
    final MediaPickResult res = await gateway.pickAvatarImage();
    if (!mounted) return;
    setState(() {
      _pickingAvatar = false;
      if (res.picked && res.localPath != null) {
        _customAvatarPath = res.localPath;
        _avatarStatusVi =
            'Đã chọn ảnh từ máy${res.displayName != null ? ': ${res.displayName}' : ''}.';
      } else if (!res.cancelled && res.errorMessageVi != null) {
        _avatarStatusVi = res.errorMessageVi;
      }
    });
  }

  void _submit({required bool confirmPlan}) {
    final List<PrioritySubject> priorityList = _priorities.entries
        .map(
          (MapEntry<String, PriorityLevel> entry) => PrioritySubject(
            subjectCode: entry.key,
            level: entry.value,
          ),
        )
        .toList(growable: false);
    final DailyStudyPlan? confirmed =
        confirmPlan ? _buildDraftPlan().markConfirmed(DateTime.now()) : null;

    widget.onSaveProfile(
      StudyProfile(
        alias: _aliasController.text.trim(),
        avatarId: _avatarId,
        customAvatarPath: _customAvatarPath,
        gradeLevel: _selectedGrade,
        selectedSubjectCodes: _selectedSubjects.toList(growable: false),
        prioritySubjects: priorityList,
        selfAssessments: Map<String, SubjectSelfAssessment>.from(
          _selfAssessments,
        ),
        confirmedPlan: confirmed,
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
                children: const <Widget>[
                  MindClockStatusPill(label: 'Khởi tạo kế hoạch học'),
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
                    Row(
                      children: <Widget>[
                        MindClockAvatarView(
                          avatarId: _avatarId,
                          customAvatarPath: _customAvatarPath,
                          size: 52,
                          selected: true,
                        ),
                        SizedBox(width: mc.space12),
                        Expanded(
                          child: Text(
                            _customAvatarPath != null
                                ? 'Đang dùng ảnh đại diện từ máy (lưu riêng trên thiết bị).'
                                : 'Chọn ảnh minh họa có sẵn hoặc tải ảnh từ máy:',
                            style: mc.captionStyle,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: mc.space12),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children: MindClockAvatarCatalog.presets.map((Map<String, dynamic> av) {
                        final String id = av['id'] as String;
                        final String label = av['label'] as String;
                        final bool selected =
                            _customAvatarPath == null && _avatarId == id;

                        return MindClockPressable(
                          key: ValueKey<String>('avatar-$id'),
                          selected: selected,
                          semanticLabel: label,
                          onPressed: () => setState(() {
                            _avatarId = id;
                            _customAvatarPath = null;
                            _avatarStatusVi = null;
                          }),
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
                                MindClockAvatarView(
                                  avatarId: id,
                                  size: 26,
                                  selected: selected,
                                ),
                                SizedBox(width: mc.space8),
                                Flexible(
                                  child: Text(
                                    label,
                                    style: mc.chipLabelStyle.copyWith(
                                      color: selected ? mc.primary : mc.ink,
                                    ),
                                  ),
                                ),
                              ],
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
                          key: const ValueKey<String>('pick-custom-avatar-btn'),
                          label: _pickingAvatar
                              ? 'Đang mở thư viện...'
                              : 'Chọn ảnh từ máy',
                          icon: MindClockIconKind.edit,
                          variant: MindClockButtonVariant.secondary,
                          expand: false,
                          onPressed: _pickingAvatar ? null : _pickCustomAvatar,
                        ),
                        if (_customAvatarPath != null)
                          MindClockButton(
                            key: const ValueKey<String>('clear-custom-avatar-btn'),
                            label: 'Dùng ảnh minh họa',
                            icon: MindClockIconKind.trash,
                            variant: MindClockButtonVariant.subtle,
                            expand: false,
                            onPressed: () => setState(() {
                              _customAvatarPath = null;
                              _avatarStatusVi = 'Đã chuyển về avatar minh họa MindClock.';
                            }),
                          ),
                      ],
                    ),
                    if (_avatarStatusVi != null) ...<Widget>[
                      SizedBox(height: mc.space8),
                      Text(_avatarStatusVi!, style: mc.captionStyle),
                    ],
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

              // 4. Mức tự đánh giá từng môn (điểm khởi đầu, không phải đánh giá năng lực)
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '4. Mức tự đánh giá từng môn (chạm để đổi)',
                      style: mc.sectionTitleStyle,
                    ),
                    SizedBox(height: mc.space4),
                    Text(
                      'Mới bắt đầu / Cơ bản / Đang ôn thi / Muốn thử thách — chỉ dùng để gợi ý nhịp ôn đầu tiên.',
                      style: mc.captionStyle,
                    ),
                    SizedBox(height: mc.space8),
                    if (_selectedSubjects.isEmpty)
                      Text(
                        'Hãy chọn ít nhất 1 môn ở mục 3 để đặt mức tự đánh giá.',
                        style: mc.captionStyle,
                      )
                    else
                      Wrap(
                        spacing: mc.space8,
                        runSpacing: mc.space8,
                        children: _selectedSubjects.map((String code) {
                          final SubjectSelfAssessment assessment =
                              _selfAssessments[code] ??
                                  SubjectSelfAssessment.basic;
                          final String name = SubjectCatalog.nameFor(code);
                          final bool highlighted =
                              assessment == SubjectSelfAssessment.examPrep ||
                                  assessment == SubjectSelfAssessment.beginner;
                          return MindClockPressable(
                            key: ValueKey<String>('priority-$code'),
                            onPressed: () => _cycleSelfAssessment(code),
                            semanticLabel: '$name: ${assessment.labelVi}',
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: mc.space12,
                                vertical: mc.space8,
                              ),
                              decoration: BoxDecoration(
                                color: assessment ==
                                        SubjectSelfAssessment.examPrep
                                    ? mc.sunriseSoft
                                    : (highlighted ? mc.primarySoft : mc.paper),
                                borderRadius:
                                    BorderRadius.circular(mc.radiusChip),
                                border: Border.all(
                                  color: assessment ==
                                          SubjectSelfAssessment.examPrep
                                      ? mc.sunrise
                                      : (highlighted
                                          ? mc.primary
                                          : mc.outline),
                                ),
                              ),
                              child: Text(
                                '$name: ${assessment.labelVi}',
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

              // 6. Bản kế hoạch nháp rule-based cần người học xác nhận (ON-05)
              Builder(
                builder: (BuildContext context) {
                  final DailyStudyPlan draftPlan = _buildDraftPlan();
                  return Container(
                    key: const ValueKey<String>('onboarding-plan-draft-card'),
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
                        Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: <Widget>[
                            Text(
                              '6. Bản kế hoạch nháp hôm nay',
                              style: mc.sectionTitleStyle.copyWith(
                                color: mc.primary,
                              ),
                            ),
                            MindClockStatusPill(label: draftPlan.sourceLabelVi),
                          ],
                        ),
                        SizedBox(height: mc.space8),
                        ...draftPlan.items.map(
                          (DailyPlanItem item) => Padding(
                            padding: EdgeInsets.only(bottom: mc.space8),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(mc.space12),
                              decoration: BoxDecoration(
                                color: mc.surface,
                                borderRadius:
                                    BorderRadius.circular(mc.radiusControl),
                                border: Border.all(color: mc.outline),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    item.titleVi,
                                    style: mc.bodyStrongStyle,
                                  ),
                                  SizedBox(height: mc.space4),
                                  Text(
                                    item.reasonVi,
                                    style: mc.captionStyle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Không tự bật báo thức hay thông báo — bạn chủ động đặt chuông sau nếu muốn. (Catalog ${draftPlan.catalogVersion} · ${draftPlan.plannerRuleVersion})',
                          style: mc.captionStyle.copyWith(color: mc.ink),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: mc.space16),
              if (widget.workspaceViewModel != null &&
                  widget.workspaceViewModel!.isOsBridgeConnected) ...<Widget>[
                ListenableBuilder(
                  listenable: widget.workspaceViewModel!,
                  builder: (BuildContext context, _) {
                    final GuestWorkspaceViewModel vm =
                        widget.workspaceViewModel!;
                    return MindClockCard(
                      key: const ValueKey<String>('onboarding-permissions-card'),
                      highlighted: vm.needsOsPermissions,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '5. Cấp quyền báo thức & thông báo',
                            style: mc.sectionTitleStyle,
                          ),
                          SizedBox(height: mc.space4),
                          Text(
                            vm.needsOsPermissions
                                ? 'Cấp quyền ngay để chuông báo thức và nhắc học hoạt động đúng giờ trên điện thoại.'
                                : 'Đã cấp đủ quyền báo thức và thông báo.',
                            style: mc.captionStyle,
                          ),
                          if (vm.needsOsPermissions) ...<Widget>[
                            SizedBox(height: mc.space12),
                            ...vm.missingPermissionActions.map(
                              (AlarmPermissionAction action) => Padding(
                                padding: EdgeInsets.only(bottom: mc.space8),
                                child: MindClockButton(
                                  key: ValueKey<String>(
                                    'onboarding-perm-${action.wireAction}',
                                  ),
                                  label: vm.labelForPermissionAction(action),
                                  icon: MindClockIconKind.bell,
                                  variant: MindClockButtonVariant.secondary,
                                  onPressed: () =>
                                      vm.openPermissionSettings(action),
                                ),
                              ),
                            ),
                            MindClockButton(
                              key: const ValueKey<String>(
                                'onboarding-perm-refresh',
                              ),
                              label: 'Kiểm tra lại quyền',
                              icon: MindClockIconKind.check,
                              variant: MindClockButtonVariant.subtle,
                              onPressed: vm.refreshOsStatus,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: mc.space16),
              ],
              MindClockButton(
                key: const ValueKey<String>('onboarding-save'),
                label: 'Xác nhận kế hoạch & Vào Hôm nay',
                icon: MindClockIconKind.check,
                onPressed: () => _submit(confirmPlan: true),
              ),
              SizedBox(height: mc.space8),
              MindClockButton(
                key: const ValueKey<String>('onboarding-skip-plan'),
                label: 'Bỏ qua kế hoạch · Vào Hôm nay',
                variant: MindClockButtonVariant.secondary,
                onPressed: () => _submit(confirmPlan: false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
