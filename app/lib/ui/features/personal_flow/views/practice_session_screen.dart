import 'package:flutter/material.dart';

import '../../../../domain/models/personal_flow_models.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/math_formula_text.dart';
import '../../../core/widgets/math_input_keypad.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../guest_shell/view_models/guest_workspace_view_model.dart';
import '../view_models/personal_flow_view_model.dart';

/// Màn hình tab `Luyện tập`: ưu tiên câu hỏi đang mở ngay đầu màn, không lặp thẻ Đăng xuất hay Không gian học.
class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({
    super.key,
    required this.guestViewModel,
    required this.personalViewModel,
    required this.onOpenProfileSetup,
    this.onOpenStudySpace,
    this.onCompletedReturnToDashboard,
  });

  final GuestWorkspaceViewModel guestViewModel;
  final PersonalFlowViewModel personalViewModel;
  final VoidCallback onOpenProfileSetup;
  final VoidCallback? onOpenStudySpace;
  final ValueChanged<String>? onCompletedReturnToDashboard;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen>
    with WidgetsBindingObserver {
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _reasoningController = TextEditingController();
  final TextEditingController _feedbackCommentController =
      TextEditingController();
  String _selectedDifficulty = 'basic';
  final Map<int, int> _miniQuizSelections = <int, int>{};
  bool _reRingWarningActive = false;
  bool _showMathKeypad = false;
  bool _showReasoningField = false;
  String? _celebratedSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.personalViewModel.addListener(_onPvmChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final PersonalFlowViewModel pvm = widget.personalViewModel;
    final bool activeChallenge = pvm.isChallengeModeSession &&
        pvm.activeSession != null &&
        pvm.activeSession!.state == 'active' &&
        pvm.lastResult?.verdict != GradingVerdict.correct;
    if (activeChallenge &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive)) {
      if (mounted) {
        setState(() => _reRingWarningActive = true);
      }
    }
  }

  @override
  void didUpdateWidget(covariant PracticeSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.personalViewModel != widget.personalViewModel) {
      oldWidget.personalViewModel.removeListener(_onPvmChanged);
      widget.personalViewModel.addListener(_onPvmChanged);
    }
  }

  void _onPvmChanged() {
    if (!mounted) return;
    setState(() {});
    _maybeCelebrateCompletion();
  }

  void _maybeCelebrateCompletion() {
    final PersonalFlowViewModel pvm = widget.personalViewModel;
    final GradingResult? result = pvm.lastResult;
    final String? sid = pvm.activeSession?.sessionId;
    if (result?.verdict != GradingVerdict.correct ||
        sid == null ||
        _celebratedSessionId == sid) {
      return;
    }
    _celebratedSessionId = sid;
    final int xp = result!.authoritativeXpAwarded;
    final int streak = pvm.progressSummary.streak;
    final String celebrationMsg = <String>[
      xp > 0
          ? 'Chúc mừng! Bạn nhận được +$xp EXP.'
          : 'Chúc mừng! Bạn đã trả lời chính xác.',
      if (streak > 0)
        'Chúc mừng bạn đã đốt ngọn lửa chuỗi ($streak ngày) cho bản thân và nhóm cam kết!'
      else
        'Bạn đã đốt ngọn lửa khởi đầu chuỗi học tập hôm nay!',
    ].join('\n\n');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) => AlertDialog(
          key: const ValueKey<String>('practice-completion-dialog'),
          title: const Text('Hoàn thành xuất sắc!'),
          content: Text(celebrationMsg),
          actions: <Widget>[
            MindClockButton(
              key: const ValueKey<String>('practice-celebration-go-today'),
              label: 'Về trang Hôm nay',
              icon: MindClockIconKind.check,
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _answerController.clear();
                _reasoningController.clear();
                pvm.clearFinishedSession();
                widget.onCompletedReturnToDashboard?.call(
                  xp > 0
                      ? 'Chúc mừng +$xp EXP! Ngọn lửa chuỗi đã được thắp sáng.'
                      : 'Hoàn thành câu hỏi! Ngọn lửa chuỗi đã được giữ vững.',
                );
              },
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.personalViewModel.removeListener(_onPvmChanged);
    _answerController.dispose();
    _reasoningController.dispose();
    _feedbackCommentController.dispose();
    super.dispose();
  }

  String _verdictTitle(GradingVerdict verdict) {
    switch (verdict) {
      case GradingVerdict.correct:
        return 'Kết quả: Đúng';
      case GradingVerdict.incorrect:
        return 'Kết quả: Chưa đúng';
      case GradingVerdict.uncertain:
        return 'Kết quả: Chưa đủ rõ để chấm';
    }
  }

  String _inputGuideFor(ChallengeQuestion question) {
    if (question.questionFormat == 'mcq' && question.options.isNotEmpty) {
      return 'Cách trả lời: Chọn 1 đáp án đúng bên dưới.';
    }
    if (question.questionFormat == 'mini_quiz' &&
        question.subQuestions.isNotEmpty) {
      return 'Cách trả lời: Chọn đáp án cho từng câu rồi bấm Nộp đề ngắn.';
    }
    return 'Cách trả lời: Nhập đáp án của bạn bên dưới.';
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final StudyProfile profile = widget.guestViewModel.profile;
    final PersonalFlowViewModel pvm = widget.personalViewModel;
    final ChallengeQuestion? question = pvm.currentQuestion;
    final GradingResult? result = pvm.lastResult;
    final OfflineTextDraft? savedDraft = pvm.savedDraft;
    final ProgressSummary progress = pvm.progressSummary;

    final String? primarySubject = profile.selectedSubjectCodes.isNotEmpty
        ? profile.selectedSubjectCodes.first
        : null;
    final bool inOpenAlarmSession = pvm.activeAlarmId != null &&
        question != null &&
        pvm.activeSession?.state != 'completed' &&
        pvm.activeSession?.state != 'abandoned' &&
        result?.verdict != GradingVerdict.correct;
    final bool hasActiveUnfinishedQuestion = question != null &&
        pvm.activeSession?.state != 'completed' &&
        pvm.activeSession?.state != 'abandoned' &&
        result?.verdict != GradingVerdict.correct;

    return SingleChildScrollView(
      padding: EdgeInsets.all(mc.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                inOpenAlarmSession ? 'Câu hỏi buổi sáng' : AppStrings.navPractice,
                style: mc.screenTitleStyle,
              ),
              if (pvm.isDebugFixture)
                const MindClockStatusPill(
                  label: AppStrings.debugFixtureLabel,
                  accentWarm: true,
                ),
            ],
          ),
          if (pvm.bannerMessageVi != null) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockNoticeBanner(message: pvm.bannerMessageVi!, isWarm: false),
          ],
          if (pvm.errorMessageVi != null) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockNoticeBanner(message: pvm.errorMessageVi!),
          ],
          SizedBox(height: mc.space16),

          // 1. Khung câu hỏi chính đặt ngay đầu màn hình
          MindClockCard(
            key: const ValueKey<String>('practice-primary-question-card'),
            highlighted: question != null && result?.verdict != GradingVerdict.correct,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (!hasActiveUnfinishedQuestion) ...<Widget>[
                  Text('Ôn bài nhanh', style: mc.sectionTitleStyle),
                  SizedBox(height: mc.space8),
                  Wrap(
                    spacing: mc.space8,
                    runSpacing: mc.space8,
                    children: <Widget>[
                      ChoiceChip(
                        key: const ValueKey<String>('practice-diff-basic'),
                        label: const Text('Nhẹ (1 câu)'),
                        selected: _selectedDifficulty == 'basic',
                        onSelected: pvm.isBusy
                            ? null
                            : (_) =>
                                setState(() => _selectedDifficulty = 'basic'),
                      ),
                      ChoiceChip(
                        key: const ValueKey<String>('practice-diff-advanced'),
                        label: const Text('Nâng cao (Đề ngắn)'),
                        selected: _selectedDifficulty == 'advanced',
                        onSelected: pvm.isBusy
                            ? null
                            : (_) => setState(
                                () => _selectedDifficulty = 'advanced'),
                      ),
                    ],
                  ),
                  SizedBox(height: mc.space8),
                  Wrap(
                    spacing: mc.space8,
                    runSpacing: mc.space8,
                    children: <Widget>[
                      MindClockButton(
                        key: const ValueKey<String>('practice-start-challenge'),
                        label: 'Mở câu thử thách buổi sáng',
                        icon: MindClockIconKind.bell,
                        expand: false,
                        onPressed: pvm.isBusy
                            ? null
                            : () {
                                _miniQuizSelections.clear();
                                pvm.startSession(
                                  subjectCode: 'auto',
                                  gradeLevel: profile.gradeLevel,
                                  challengeMode: true,
                                  difficulty: _selectedDifficulty,
                                );
                              },
                      ),
                      MindClockButton(
                        key: const ValueKey<String>('practice-start-normal'),
                        label: 'Câu tự luyện',
                        icon: MindClockIconKind.book,
                        variant: MindClockButtonVariant.secondary,
                        expand: false,
                        onPressed: pvm.isBusy
                            ? null
                            : () {
                                _miniQuizSelections.clear();
                                pvm.startSession(
                                  subjectCode: primarySubject,
                                  gradeLevel: profile.gradeLevel,
                                  challengeMode: false,
                                );
                              },
                      ),
                      if (pvm.authSession.isAuthenticated)
                        MindClockButton(
                          key: const ValueKey<String>('practice-start-ai-regen'),
                          label: 'Đổi câu mới',
                          icon: MindClockIconKind.sunrise,
                          variant: MindClockButtonVariant.secondary,
                          expand: false,
                          onPressed: pvm.isBusy
                              ? null
                              : () {
                                  _miniQuizSelections.clear();
                                  pvm.startSession(
                                    subjectCode: primarySubject,
                                    gradeLevel: profile.gradeLevel,
                                    challengeMode: false,
                                    preferAiRegen: true,
                                  );
                                },
                        ),
                    ],
                  ),
                ],
                if (question != null) ...<Widget>[
                  if (!inOpenAlarmSession) SizedBox(height: mc.space16),
                  if (_reRingWarningActive) ...<Widget>[
                    const MindClockNoticeBanner(
                      key: ValueKey<String>('practice-rering-warning'),
                      message:
                          'Bạn vừa rời màn hình khi câu sáng chưa hoàn thành. Hãy trả lời hoặc bấm Dừng khẩn cấp.',
                      isWarm: true,
                    ),
                    SizedBox(height: mc.space12),
                  ],
                  if (question.morningCard != null &&
                      pvm.isMorningHookVisible) ...<Widget>[
                    MindClockCard(
                      key: const ValueKey<String>('morning-hook-card'),
                      highlighted: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Tình huống mở đầu (${question.morningCard!.durationTargetSeconds} giây)',
                            style: mc.sectionTitleStyle,
                          ),
                          SizedBox(height: mc.space4),
                          Text(
                            MediaQuery.disableAnimationsOf(context)
                                ? question.morningCard!.staticFallbackVi
                                : '${question.morningCard!.setupVi}\n${question.morningCard!.cliffVi}',
                            key: const ValueKey<String>('morning-hook-text'),
                            style: mc.bodyStyle,
                          ),
                          SizedBox(height: mc.space8),
                          MindClockButton(
                            key: const ValueKey<String>('morning-hook-skip'),
                            label: 'Bỏ qua mở màn · Vào câu hỏi',
                            icon: MindClockIconKind.book,
                            variant: MindClockButtonVariant.secondary,
                            onPressed: pvm.skipOrFinishMorningHook,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: mc.space12),
                  ],
                  Wrap(
                    spacing: mc.space8,
                    runSpacing: mc.space4,
                    children: <Widget>[
                      MindClockStatusPill(
                        label: SubjectCatalog.nameFor(question.subjectCode),
                        accentWarm: true,
                      ),
                      if (question.sourceScheduleReasonVi != null)
                        MindClockStatusPill(
                          key: const ValueKey<String>('practice-schedule-reason'),
                          label: question.sourceScheduleReasonVi!,
                          accentWarm: false,
                        ),
                      if (question.schoolWeek != null)
                        MindClockStatusPill(
                          label: 'Tuần ${question.schoolWeek}',
                        ),
                    ],
                  ),
                  SizedBox(height: mc.space8),
                  MathFormulaText(
                    question.prompt,
                    key: const ValueKey<String>('practice-question-prompt'),
                    style: mc.sectionTitleStyle,
                  ),
                  SizedBox(height: mc.space4),
                  Text(
                    _inputGuideFor(question),
                    key: const ValueKey<String>('practice-input-guide'),
                    style: mc.captionStyle.copyWith(color: mc.ink),
                  ),
                  SizedBox(height: mc.space12),
                  if (question.questionFormat == 'mcq' &&
                      question.options.isNotEmpty) ...<Widget>[
                    for (int i = 0; i < question.options.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: mc.space8),
                        child: MindClockButton(
                          key: ValueKey<String>('practice-mcq-option-$i'),
                          label:
                              '${<String>['A', 'B', 'C', 'D', 'E'][i % 5]}. ${question.options[i]}',
                          variant: MindClockButtonVariant.secondary,
                          onPressed: pvm.isBusy
                              ? null
                              : () => pvm.submitMcqAnswer(i),
                        ),
                      ),
                  ] else if (question.questionFormat == 'mini_quiz' &&
                      question.subQuestions.isNotEmpty) ...<Widget>[
                    for (final ChallengeSubQuestion sq in question.subQuestions)
                      Padding(
                        padding: EdgeInsets.only(bottom: mc.space12),
                        child: MindClockCard(
                          padding: EdgeInsets.all(mc.space12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Câu ${sq.index + 1}: ${sq.prompt}',
                                style: mc.bodyStrongStyle,
                              ),
                              SizedBox(height: mc.space8),
                              for (int i = 0; i < sq.options.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(bottom: mc.space4),
                                  child: MindClockButton(
                                    key: ValueKey<String>(
                                        'mini-quiz-${sq.index}-opt-$i'),
                                    label:
                                        '${<String>['A', 'B', 'C', 'D'][i % 4]}. ${sq.options[i]}',
                                    variant: _miniQuizSelections[sq.index] == i
                                        ? MindClockButtonVariant.primary
                                        : MindClockButtonVariant.subtle,
                                    onPressed: pvm.isBusy
                                        ? null
                                        : () => setState(() =>
                                            _miniQuizSelections[sq.index] = i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    MindClockButton(
                      key: const ValueKey<String>('practice-submit-mini-quiz'),
                      label:
                          'Nộp đề ngắn (${_miniQuizSelections.length}/${question.subQuestions.length} câu)',
                      icon: MindClockIconKind.check,
                      onPressed: pvm.isBusy ||
                              _miniQuizSelections.length <
                                  question.subQuestions.length
                          ? null
                          : () {
                              final List<int> ordered = List<int>.generate(
                                question.subQuestions.length,
                                (int i) => _miniQuizSelections[i] ?? 0,
                              );
                              pvm.submitMiniQuizAnswers(ordered);
                            },
                    ),
                  ] else ...<Widget>[
                    TextField(
                      key: const ValueKey<String>('practice-answer-field'),
                      controller: _answerController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!pvm.isBusy) {
                          pvm.submitTextAnswer(
                            answerValue: _answerController.text,
                            reasoningText: _reasoningController.text,
                          );
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Đáp án của bạn',
                        hintText: 'Nhập đáp án (VD: x = 3, 12, A...)',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(mc.radiusControl),
                        ),
                      ),
                    ),
                    SizedBox(height: mc.space8),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space4,
                      children: <Widget>[
                        FilterChip(
                          key: const ValueKey<String>('practice-toggle-keypad'),
                          label: const Text('Ký hiệu toán'),
                          selected: _showMathKeypad,
                          onSelected: (bool next) =>
                              setState(() => _showMathKeypad = next),
                        ),
                        FilterChip(
                          key: const ValueKey<String>(
                            'practice-toggle-reasoning',
                          ),
                          label: const Text('+ Giải thích (tùy chọn)'),
                          selected: _showReasoningField,
                          onSelected: (bool next) =>
                              setState(() => _showReasoningField = next),
                        ),
                      ],
                    ),
                    if (_showMathKeypad) ...<Widget>[
                      SizedBox(height: mc.space8),
                      MathInputKeypad(
                        controller: _answerController,
                        compact: true,
                      ),
                    ],
                    if (_showReasoningField) ...<Widget>[
                      SizedBox(height: mc.space8),
                      TextField(
                        key: const ValueKey<String>('practice-reasoning-field'),
                        controller: _reasoningController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: question.reasoningPromptVi.isNotEmpty
                              ? question.reasoningPromptVi
                              : 'Cách làm ngắn gọn (tùy chọn)',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(mc.radiusControl),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: mc.space12),
                    MindClockButton(
                      key: const ValueKey<String>('practice-submit-text'),
                      label: pvm.hasRetryableTextFailure
                          ? 'Thử gửi lại bài làm'
                          : 'Gửi đáp án',
                      icon: MindClockIconKind.check,
                      onPressed: pvm.isBusy
                          ? null
                          : () => pvm.submitTextAnswer(
                                answerValue: _answerController.text,
                                reasoningText: _reasoningController.text,
                              ),
                    ),
                    if ((pvm.activeSession?.isOfflineLocal ?? false) &&
                        pvm.hasOfflineAnswerKey) ...<Widget>[
                      SizedBox(height: mc.space8),
                      MindClockButton(
                        key: const ValueKey<String>(
                            'practice-check-offline-bank'),
                        label: 'Kiểm tra đáp án',
                        icon: MindClockIconKind.book,
                        variant: MindClockButtonVariant.secondary,
                        onPressed: pvm.isBusy
                            ? null
                            : () => pvm.checkOfflineBankAnswer(
                                  answerValue: _answerController.text,
                                  reasoningText: _reasoningController.text,
                                ),
                      ),
                    ],
                  ],
                  if (pvm.activeSession?.state != 'completed' &&
                      pvm.activeSession?.state != 'abandoned') ...<Widget>[
                    SizedBox(height: mc.space8),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space4,
                      children: <Widget>[
                        MindClockButton(
                          key: const ValueKey<String>('practice-quit-challenge'),
                          label: 'Bỏ cuộc',
                          icon: MindClockIconKind.clock,
                          variant: MindClockButtonVariant.subtle,
                          expand: false,
                          onPressed: pvm.isBusy
                              ? null
                              : () => pvm.abandonActiveSession(immediate: true),
                        ),
                        MindClockButton(
                          key: const ValueKey<String>(
                            'practice-complete-ungraded',
                          ),
                          label: 'Xong không chấm',
                          icon: MindClockIconKind.check,
                          variant: MindClockButtonVariant.subtle,
                          expand: false,
                          onPressed:
                              pvm.isBusy ? null : pvm.completeSessionUngraded,
                        ),
                      ],
                    ),
                  ],
                ],
                if (result != null) ...<Widget>[
                  SizedBox(height: mc.space16),
                  MindClockCard(
                    highlighted: result.verdict == GradingVerdict.correct,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _verdictTitle(result.verdict),
                          key: const ValueKey<String>('grading-verdict-title'),
                          style: mc.sectionTitleStyle,
                        ),
                        SizedBox(height: mc.space4),
                        Text(result.feedbackVi, style: mc.bodyStyle),
                        SizedBox(height: mc.space4),
                        Text(
                          result.authoritativeXpAwarded > 0
                              ? 'Điểm thưởng: +${result.authoritativeXpAwarded} XP'
                              : 'Điểm thưởng: 0 XP',
                          key: const ValueKey<String>('grading-xp-awarded'),
                          style: mc.captionStyle,
                        ),
                        if (pvm.canRevealMethodHint) ...<Widget>[
                          SizedBox(height: mc.space8),
                          MindClockNoticeBanner(
                            key: const ValueKey<String>('grading-method-hint'),
                            message: 'Gợi ý phương pháp: ${result.hintVi}',
                          ),
                        ],
                        if (pvm.canAbandonCurrentSession &&
                            pvm.activeSession?.state != 'abandoned' &&
                            pvm.activeSession?.state != 'completed') ...<Widget>[
                          SizedBox(height: mc.space8),
                          MindClockButton(
                            key: const ValueKey<String>(
                              'practice-abandon-session',
                            ),
                            label: 'Bỏ lượt (0 EXP · xem lời giải chuẩn)',
                            icon: MindClockIconKind.clock,
                            variant: MindClockButtonVariant.secondary,
                            onPressed: pvm.isBusy
                                ? null
                                : pvm.abandonActiveSession,
                          ),
                        ],
                        if (pvm.postAttemptRevealVi != null &&
                            pvm.postAttemptRevealVi!.isNotEmpty) ...<Widget>[
                          SizedBox(height: mc.space8),
                          MindClockNoticeBanner(
                            key: const ValueKey<String>(
                              'practice-post-attempt-reveal',
                            ),
                            message: 'Giải thích chuẩn: ${pvm.postAttemptRevealVi}',
                            isWarm: false,
                          ),
                        ],
                        if (result.verdict != GradingVerdict.correct &&
                            pvm.activeSession?.isOfflineLocal != true &&
                            pvm.lastFeedbackReport == null) ...<Widget>[
                          SizedBox(height: mc.space12),
                          TextField(
                            key: const ValueKey<String>(
                              'feedback-comment-field',
                            ),
                            controller: _feedbackCommentController,
                            decoration: const InputDecoration(
                              labelText: 'Ghi chú báo chấm sai (tùy chọn)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: mc.space8),
                          MindClockButton(
                            key: const ValueKey<String>(
                              'practice-report-feedback',
                            ),
                            label: 'Báo chấm sai',
                            icon: MindClockIconKind.warning,
                            variant: MindClockButtonVariant.secondary,
                            onPressed: pvm.isBusy
                                ? null
                                : () => pvm.reportGradingWrong(
                                      comment: _feedbackCommentController.text,
                                    ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (savedDraft != null) ...<Widget>[
            SizedBox(height: mc.space16),
            MindClockCard(
              highlighted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Bản nháp đã lưu trên máy (tối đa 24 giờ)',
                    style: mc.sectionTitleStyle,
                  ),
                  SizedBox(height: mc.space8),
                  Text(
                    'Câu hỏi: ${savedDraft.promptSnapshot}',
                    style: mc.captionStyle,
                  ),
                  SizedBox(height: mc.space4),
                  Text(
                    'Đáp án nháp: ${savedDraft.answerValue} · Cách làm: ${savedDraft.reasoningText}',
                    style: mc.bodyStyle,
                  ),
                  SizedBox(height: mc.space8),
                  const MindClockNoticeBanner(
                    message: 'Gửi bài này để nhận nhận xét?',
                  ),
                  SizedBox(height: mc.space12),
                  MindClockButton(
                    key: const ValueKey<String>('draft-confirm-upload'),
                    label: 'Xác nhận gửi bản nháp',
                    icon: MindClockIconKind.check,
                    onPressed:
                        pvm.isBusy ? null : pvm.confirmAndUploadSavedDraft,
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('draft-discard'),
                    label: 'Xóa bản nháp',
                    icon: MindClockIconKind.trash,
                    variant: MindClockButtonVariant.subtle,
                    onPressed: pvm.isBusy ? null : pvm.discardSavedDraft,
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: mc.space16),
          // 2. Tiến độ học tập riêng tư đặt dưới câu hỏi
          MindClockCard(
            key: const ValueKey<String>('practice-progress-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Tiến độ học tập', style: mc.sectionTitleStyle),
                SizedBox(height: mc.space8),
                if (!pvm.authSession.isAuthenticated)
                  Text(
                    'Mở mục Tôi để đăng nhập và đồng bộ điểm, chuỗi ngày.',
                    style: mc.bodyStyle,
                  )
                else if (!progress.isServerAuthoritative ||
                    progress.isDebugFixture)
                  Text(
                    '0 XP · Chưa kết nối mạng.',
                    key: const ValueKey<String>('progress-fixture-xp'),
                    style: mc.bodyStyle,
                  )
                else ...<Widget>[
                  if (progress.level != null)
                    Text(
                      'Cấp ${progress.level} · Còn ${progress.xpToNextLevel ?? 0} EXP để lên cấp',
                      key: const ValueKey<String>('progress-server-level'),
                      style: mc.bodyStrongStyle,
                    ),
                  Text(
                    'XP tích lũy: ${progress.xp} XP · Chuỗi: ${progress.streak} ngày · Số buổi: ${progress.completedSessions}',
                    key: const ValueKey<String>('progress-server-xp'),
                    style: mc.bodyStrongStyle,
                  ),
                  if (progress.topicsToReview.isNotEmpty) ...<Widget>[
                    SizedBox(height: mc.space4),
                    Text(
                      'Chủ đề cần ôn: ${progress.topicsToReview.join(", ")}',
                      style: mc.captionStyle,
                    ),
                  ],
                ],
                if (pvm.authSession.isAuthenticated) ...<Widget>[
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('practice-refresh-progress'),
                    label: 'Làm mới tiến độ',
                    icon: MindClockIconKind.check,
                    variant: MindClockButtonVariant.subtle,
                    onPressed:
                        pvm.isBusy ? null : pvm.refreshProgressAndHistory,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: mc.space16),
          MindClockButton(
            key: const ValueKey<String>('practice-open-timetable'),
            label: 'Chỉnh môn học & Thời khóa biểu',
            icon: MindClockIconKind.edit,
            variant: MindClockButtonVariant.secondary,
            onPressed: widget.onOpenProfileSetup,
          ),
        ],
      ),
    );
  }
}
