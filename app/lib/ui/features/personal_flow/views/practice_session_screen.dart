import 'package:flutter/material.dart';

import '../../../../domain/models/personal_flow_models.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../guest_shell/view_models/guest_workspace_view_model.dart';
import '../view_models/personal_flow_view_model.dart';
import 'account_auth_card.dart';

/// Màn hình tab `Luyện tập` nối câu hỏi/phiên/nộp chữ/ảnh xác nhận/nháp 24h/báo chấm sai/tiến độ riêng tư.
class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({
    super.key,
    required this.guestViewModel,
    required this.personalViewModel,
    required this.onOpenProfileSetup,
  });

  final GuestWorkspaceViewModel guestViewModel;
  final PersonalFlowViewModel personalViewModel;
  final VoidCallback onOpenProfileSetup;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _reasoningController = TextEditingController();
  final TextEditingController _feedbackCommentController =
      TextEditingController();

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final StudyProfile profile = widget.guestViewModel.profile;
    final PersonalFlowViewModel pvm = widget.personalViewModel;
    final ChallengeQuestion? question = pvm.currentQuestion;
    final GradingResult? result = pvm.lastResult;
    final OfflineTextDraft? savedDraft = pvm.savedDraft;
    final PhotoAttemptUpload? pendingPhoto = pvm.pendingPhotoPreview;
    final ProgressSummary progress = pvm.progressSummary;

    final String? primarySubject = profile.selectedSubjectCodes.isNotEmpty
        ? profile.selectedSubjectCodes.first
        : null;

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
              Text(AppStrings.navPractice, style: mc.screenTitleStyle),
              if (pvm.isDebugFixture)
                const MindClockStatusPill(
                  label: 'Fixture debug · Không phải dịch vụ thật',
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
          AccountAuthCard(viewModel: pvm),
          SizedBox(height: mc.space16),
          // Tiến độ riêng tư (XP chỉ lấy từ server hợp lệ)
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Tiến độ học tập riêng tư', style: mc.sectionTitleStyle),
                SizedBox(height: mc.space8),
                if (!pvm.authSession.isAuthenticated)
                  Text(
                    'Chưa đồng bộ · Chỉ hiện XP khi đăng nhập và được server xác nhận.',
                    style: mc.bodyStyle,
                  )
                else if (!progress.isServerAuthoritative ||
                    progress.isDebugFixture)
                  Text(
                    '0 XP · Chế độ Fixture debug (không tự cộng XP thật).',
                    key: const ValueKey<String>('progress-fixture-xp'),
                    style: mc.bodyStyle,
                  )
                else ...<Widget>[
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
                SizedBox(height: mc.space8),
                MindClockButton(
                  key: const ValueKey<String>('practice-refresh-progress'),
                  label: 'Tải lại tiến độ từ máy chủ',
                  icon: MindClockIconKind.check,
                  variant: MindClockButtonVariant.subtle,
                  onPressed: pvm.isBusy ? null : pvm.refreshProgressAndHistory,
                ),
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
                    'Bản nháp bài chữ đã lưu trên máy (tối đa 24 giờ)',
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
                    onPressed: pvm.isBusy
                        ? null
                        : pvm.confirmAndUploadSavedDraft,
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
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Phiên câu hỏi có trình bày', style: mc.sectionTitleStyle),
                SizedBox(height: mc.space8),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: <Widget>[
                    MindClockButton(
                      key: const ValueKey<String>('practice-start-normal'),
                      label: 'Bắt đầu câu thường',
                      icon: MindClockIconKind.book,
                      expand: false,
                      onPressed: pvm.isBusy
                          ? null
                          : () => pvm.startSession(
                                subjectCode: primarySubject,
                                challengeMode: false,
                              ),
                    ),
                    MindClockButton(
                      key: const ValueKey<String>('practice-start-challenge'),
                      label: 'Thử phiên báo thức thử thách',
                      icon: MindClockIconKind.bell,
                      variant: MindClockButtonVariant.secondary,
                      expand: false,
                      onPressed: pvm.isBusy
                          ? null
                          : () => pvm.startSession(
                                subjectCode: primarySubject,
                                challengeMode: true,
                              ),
                    ),
                  ],
                ),
                if (question != null) ...<Widget>[
                  SizedBox(height: mc.space16),
                  Text(
                    question.prompt,
                    key: const ValueKey<String>('practice-question-prompt'),
                    style: mc.sectionTitleStyle,
                  ),
                  SizedBox(height: mc.space4),
                  Text(
                    '${SubjectCatalog.nameFor(question.subjectCode)} · '
                    'Revision ${question.questionRevision} · '
                    '${question.reasoningPromptVi}',
                    style: mc.captionStyle,
                  ),
                  SizedBox(height: mc.space12),
                  TextField(
                    key: const ValueKey<String>('practice-answer-field'),
                    controller: _answerController,
                    decoration: const InputDecoration(
                      labelText: 'Đáp án cuối cùng',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: mc.space12),
                  TextField(
                    key: const ValueKey<String>('practice-reasoning-field'),
                    controller: _reasoningController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Cách làm / giải thích ngắn (bắt buộc khi nhập chữ)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: mc.space12),
                  MindClockButton(
                    key: const ValueKey<String>('practice-submit-text'),
                    label: pvm.hasRetryableTextFailure
                        ? 'Thử gửi lại bài làm (giữ Idempotency-Key)'
                        : 'Gửi bài chữ để chấm',
                    icon: MindClockIconKind.check,
                    onPressed: pvm.isBusy
                        ? null
                        : () => pvm.submitTextAnswer(
                              answerValue: _answerController.text,
                              reasoningText: _reasoningController.text,
                            ),
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('practice-save-draft'),
                    label: 'Lưu trên máy để gửi sau (nháp chữ ≤24h)',
                    icon: MindClockIconKind.edit,
                    variant: MindClockButtonVariant.subtle,
                    onPressed: pvm.isBusy
                        ? null
                        : () => pvm.saveOfflineTextDraft(
                              answerValue: _answerController.text,
                              reasoningText: _reasoningController.text,
                            ),
                  ),
                  SizedBox(height: mc.space12),
                  const MindClockNoticeBanner(
                    message:
                        'Ảnh bài làm sẽ được gửi đến dịch vụ AI để nhận phản hồi. Không chụp tên hoặc thông tin riêng. Bạn có thể nhập đáp án thay thế.',
                    isWarm: false,
                  ),
                  SizedBox(height: mc.space8),
                  if (pendingPhoto == null)
                    MindClockButton(
                      key: const ValueKey<String>('practice-capture-photo'),
                      label: 'Chụp bài làm viết tay (tùy chọn)',
                      icon: MindClockIconKind.edit,
                      variant: MindClockButtonVariant.secondary,
                      onPressed: pvm.isBusy ? null : pvm.capturePhotoForReview,
                    )
                  else ...<Widget>[
                    MindClockCard(
                      highlighted: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Xem lại ảnh trước khi gửi (${pendingPhoto.bytes.lengthInBytes} bytes)',
                            key: const ValueKey<String>('photo-review-title'),
                            style: mc.sectionTitleStyle,
                          ),
                          SizedBox(height: mc.space8),
                          Text(
                            'Ảnh chỉ nằm trong bộ nhớ tạm để bạn duyệt trước khi tải lên, không tự lưu thư viện.',
                            style: mc.captionStyle,
                          ),
                          SizedBox(height: mc.space12),
                          MindClockButton(
                            key: const ValueKey<String>('photo-confirm-upload'),
                            label: pvm.hasRetryablePhotoFailure
                                ? 'Thử gửi lại ảnh'
                                : 'Xác nhận gửi ảnh',
                            icon: MindClockIconKind.check,
                            onPressed: pvm.isBusy
                                ? null
                                : () => pvm.confirmAndUploadPhotoAttempt(
                                      answerValue: _answerController.text,
                                    ),
                          ),
                          SizedBox(height: mc.space8),
                          MindClockButton(
                            key: const ValueKey<String>('photo-cancel-upload'),
                            label: 'Hủy bỏ ảnh (xóa khỏi bộ nhớ tạm)',
                            icon: MindClockIconKind.trash,
                            variant: MindClockButtonVariant.subtle,
                            onPressed: pvm.isBusy ? null : pvm.cancelPhotoPreview,
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('practice-complete-ungraded'),
                    label: 'Hoàn thành không chấm',
                    icon: MindClockIconKind.clock,
                    variant: MindClockButtonVariant.subtle,
                    onPressed: pvm.isBusy ? null : pvm.completeSessionUngraded,
                  ),
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
                              ? 'XP server cấp: +${result.authoritativeXpAwarded} XP'
                              : 'XP server cấp: 0 XP',
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
          SizedBox(height: mc.space16),
          MindClockButton(
            key: const ValueKey<String>('practice-open-timetable'),
            label: 'Chỉnh môn học & Thời khóa biểu',
            icon: MindClockIconKind.edit,
            variant: MindClockButtonVariant.secondary,
            onPressed: onOpenProfileSetup,
          ),
        ],
      ),
    );
  }
}
