import 'package:flutter/material.dart';

import '../../../../domain/models/study_ai_models.dart';
import '../../../../domain/models/study_focus_models.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/services/study_focus_bridge.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../guest_shell/view_models/guest_workspace_view_model.dart';
import '../view_models/study_focus_view_model.dart';

/// Màn hình Không gian học local & AI qua backend (`docs/45 §§1–6`).
///
/// Tuân thủ:
/// - Chọn việc (hoặc `Học tự do`), thời lượng `5–120` phút, mức `Linh hoạt`/`Tập trung thường`/`Cam kết`.
/// - Không khóa app khác, không suy ra xao nhãng, không cấp XP/coin cho thời gian hay camera.
/// - Camera/mic luôn tắt; trợ lý AI chỉ đi qua backend `POST /v1/study/help` khi người dùng bấm gửi.
class StudySpaceScreen extends StatefulWidget {
  const StudySpaceScreen({
    super.key,
    required this.guestViewModel,
    required this.studyViewModel,
    required this.onClose,
  });

  final GuestWorkspaceViewModel guestViewModel;
  final StudyFocusViewModel studyViewModel;
  final VoidCallback onClose;

  @override
  State<StudySpaceScreen> createState() => _StudySpaceScreenState();
}

class _StudySpaceScreenState extends State<StudySpaceScreen> {
  final TextEditingController _customTaskController = TextEditingController();
  final TextEditingController _doneController = TextEditingController();
  final TextEditingController _stuckController = TextEditingController();
  final TextEditingController _aiInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customTaskController.text = widget.studyViewModel.draftTaskTitle;
    if (widget.studyViewModel.pendingHelpQuestion != null) {
      _aiInputController.text = widget.studyViewModel.pendingHelpQuestion!;
    }
  }

  @override
  void dispose() {
    _customTaskController.dispose();
    _doneController.dispose();
    _stuckController.dispose();
    _aiInputController.dispose();
    super.dispose();
  }

  String _headerScopeLabel(StudyFocusViewModel vm) {
    if (!vm.hasAiGateway) {
      return 'Lưu cục bộ · Camera & AI đang tắt';
    }
    if (vm.isAiDebugFixture) {
      return 'Lưu cục bộ · Camera tắt · AI mẫu (debug)';
    }
    if (vm.isAuthenticated) {
      return 'Lưu cục bộ · Camera tắt · AI qua backend';
    }
    return 'Lưu cục bộ · Camera tắt · Đăng nhập để hỏi AI';
  }

  Future<void> _submitAiHelp(StudyFocusViewModel vm) async {
    final bool ok = await vm.requestAiHelp(
      questionText: _aiInputController.text,
      gradeLevel: widget.guestViewModel.profile.gradeLevel,
    );
    if (ok && mounted) {
      _aiInputController.clear();
    }
  }

  Future<void> _retryAiHelp(StudyFocusViewModel vm) async {
    final String textToSend = _aiInputController.text.trim().isNotEmpty
        ? _aiInputController.text
        : (vm.pendingHelpQuestion ?? '');
    final bool ok = await vm.requestAiHelp(
      questionText: textToSend,
      gradeLevel: widget.guestViewModel.profile.gradeLevel,
    );
    if (ok && mounted) {
      _aiInputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final StudyFocusViewModel vm = widget.studyViewModel;
    final StudyFocusSessionSnapshot? snapshot = vm.activeSnapshot;
    final bool reduceMotion =
        vm.reduceMotionStaticMode || MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: mc.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(mc.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(AppStrings.studySpaceTitle, style: mc.screenTitleStyle),
                  MindClockButton(
                    key: const ValueKey<String>('study-space-back'),
                    label: 'Về Hôm nay',
                    variant: MindClockButtonVariant.subtle,
                    expand: false,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              SizedBox(height: mc.space8),
              MindClockStatusPill(
                key: const ValueKey<String>('study-scope-pill'),
                label: _headerScopeLabel(vm),
              ),
              if (vm.statusBannerVi != null) ...<Widget>[
                SizedBox(height: mc.space12),
                MindClockNoticeBanner(
                  message: vm.statusBannerVi!,
                  isWarm: false,
                ),
              ],
              SizedBox(height: mc.space16),
              if (snapshot == null)
                _buildSetupAndHistory(context, mc, vm, reduceMotion)
              else if (snapshot.status.isTerminal)
                _buildSummaryAndSave(context, mc, vm, snapshot)
              else
                _buildActiveSession(context, mc, vm, snapshot, reduceMotion),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSetupAndHistory(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
    bool reduceMotion,
  ) {
    final List<StudyTaskChoice> suggestions = StudyTaskChoice.buildSuggestions(
      profile: widget.guestViewModel.profile,
      timetable: widget.guestViewModel.timetable,
      now: vm.currentTime,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MindClockCard(
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('1. Chọn việc học cụ thể', style: mc.sectionTitleStyle),
              SizedBox(height: mc.space8),
              Text(
                'Chọn nhanh từ lịch đã xác nhận hoặc tự nhập. Nếu để trống hệ thống dùng Học tự do.',
                style: mc.captionStyle,
              ),
              SizedBox(height: mc.space12),
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: suggestions.map((StudyTaskChoice choice) {
                  final bool selected =
                      vm.draftTaskTitle.trim() == choice.title;
                  return _SelectableChip(
                    key: ValueKey<String>(
                      'study-task-${choice.subjectCode ?? "free"}-${choice.title}',
                    ),
                    label: choice.title,
                    selected: selected,
                    onTap: () {
                      vm.applyTaskSuggestion(choice);
                      _customTaskController.text = choice.title;
                    },
                  );
                }).toList(growable: false),
              ),
              SizedBox(height: mc.space12),
              TextField(
                key: const ValueKey<String>('study-custom-task-input'),
                controller: _customTaskController,
                onChanged: vm.setCustomTaskTitle,
                decoration: InputDecoration(
                  labelText: 'Tự nhập việc đang làm',
                  hintText: 'Ví dụ: Làm 3 câu hàm số',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(mc.radiusControl),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: mc.space16),
        MindClockCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('2. Chọn thời lượng (5–120 phút)', style: mc.sectionTitleStyle),
              SizedBox(height: mc.space12),
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: StudyFocusSessionSnapshot.presetMinutes
                    .map((int minutes) {
                  return _SelectableChip(
                    key: ValueKey<String>('study-duration-$minutes'),
                    label: '$minutes phút',
                    selected: vm.draftDurationMinutes == minutes,
                    onTap: () => vm.setDurationMinutes(minutes),
                  );
                }).toList(growable: false),
              ),
              SizedBox(height: mc.space12),
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  MindClockButton(
                    key: const ValueKey<String>('study-duration-minus'),
                    label: '-5 phút',
                    icon: MindClockIconKind.minus,
                    variant: MindClockButtonVariant.subtle,
                    expand: false,
                    onPressed: vm.draftDurationMinutes >
                            StudyFocusSessionSnapshot.minDurationMinutes
                        ? () => vm.setDurationMinutes(
                              vm.draftDurationMinutes - 5,
                            )
                        : null,
                  ),
                  Semantics(
                    label: 'Thời lượng đang chọn ${vm.draftDurationMinutes} phút',
                    child: Text(
                      '${vm.draftDurationMinutes} phút',
                      key: const ValueKey<String>('study-duration-display'),
                      style: mc.sectionTitleStyle,
                    ),
                  ),
                  MindClockButton(
                    key: const ValueKey<String>('study-duration-plus'),
                    label: '+5 phút',
                    icon: MindClockIconKind.plus,
                    variant: MindClockButtonVariant.subtle,
                    expand: false,
                    onPressed: vm.draftDurationMinutes <
                            StudyFocusSessionSnapshot.maxDurationMinutes
                        ? () => vm.setDurationMinutes(
                              vm.draftDurationMinutes + 5,
                            )
                        : null,
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
              Text('3. Chọn mức tập trung', style: mc.sectionTitleStyle),
              SizedBox(height: mc.space8),
              ...StudyFocusLevel.values.map((StudyFocusLevel level) {
                final bool selected = vm.draftLevel == level;
                return Padding(
                  padding: EdgeInsets.only(bottom: mc.space8),
                  child: MindClockPressable(
                    key: ValueKey<String>('study-level-${level.wireValue}'),
                    selected: selected,
                    semanticLabel: '${level.labelVi}. ${level.shortBehaviorVi}',
                    borderRadius: BorderRadius.circular(mc.radiusControl),
                    onPressed: () => vm.setFocusLevel(level),
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
                          Wrap(
                            spacing: mc.space8,
                            runSpacing: mc.space4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: <Widget>[
                              Text(level.labelVi, style: mc.bodyStrongStyle),
                              if (level == StudyFocusLevel.standard)
                                const MindClockStatusPill(label: 'Mặc định'),
                            ],
                          ),
                          SizedBox(height: mc.space4),
                          Text(level.shortBehaviorVi, style: mc.captionStyle),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: mc.space8),
              _ToggleRow(
                key: const ValueKey<String>('study-toggle-sound'),
                label: 'Âm báo nhẹ khi hết giờ',
                value: vm.draftEndSoundEnabled,
                onToggle: () => vm.setEndSoundEnabled(!vm.draftEndSoundEnabled),
              ),
              SizedBox(height: mc.space8),
              _ToggleRow(
                key: const ValueKey<String>('study-toggle-outside-notify'),
                label: 'Nhắc 1 lần khi rời app quá 30 giây (Tập trung thường)',
                value: vm.draftNotifyOutsideApp,
                onToggle: () =>
                    vm.setNotifyOutsideApp(!vm.draftNotifyOutsideApp),
              ),
              SizedBox(height: mc.space8),
              _ToggleRow(
                key: const ValueKey<String>('study-toggle-reduce-motion'),
                label: 'Chế độ số tĩnh (Giảm chuyển động / Reduce Motion)',
                value: reduceMotion,
                onToggle: () => vm.setReduceMotionStaticMode(!vm.reduceMotionStaticMode),
              ),
            ],
          ),
        ),
        SizedBox(height: mc.space16),
        _buildDigitalWellbeingCard(context, mc, vm),
        SizedBox(height: mc.space16),
        MindClockNoticeBanner(
          message: vm.hasAiGateway
              ? 'Camera và micro luôn tắt ở màn này. Khi đăng nhập và bấm gửi, phần Hỏi MindClock đi qua máy chủ backend (tối đa 3 lượt gần nhất); bộ đếm vẫn chạy local.'
              : AppStrings.studyNoCameraAiScopeNotice,
          isWarm: false,
        ),
        SizedBox(height: mc.space12),
        MindClockButton(
          key: const ValueKey<String>('study-start-button'),
          label: AppStrings.studyStartCta,
          icon: MindClockIconKind.play,
          onPressed: () {
            vm.startSession(overrideTaskTitle: _customTaskController.text);
          },
        ),
        if (vm.history.isNotEmpty) ...<Widget>[
          SizedBox(height: mc.space20),
          _buildHistoryCard(context, mc, vm, vm.history),
        ],
      ],
    );
  }

  Widget _buildActiveSession(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
    StudyFocusSessionSnapshot snapshot,
    bool reduceMotion,
  ) {
    final DateTime now = vm.currentTime;
    final int remainingSec = snapshot.remainingSecondsAt(now);
    final int wallSec = snapshot.elapsedWallSecondsAt(now);
    final int inAppSec = snapshot.inAppFocusSecondsAt(now);

    final String statusText;
    if (snapshot.status == StudyFocusStatus.interrupted) {
      statusText = AppStrings.studyInterruptedLabel;
    } else if (snapshot.commitmentAwaitingResume) {
      statusText = 'Chờ xác nhận quay lại (Cam kết)';
    } else if (snapshot.status == StudyFocusStatus.paused) {
      statusText = AppStrings.studyPausedLabel;
    } else {
      statusText = 'Đang học · ${snapshot.level.labelVi}';
    }

    final String? subjectName = snapshot.subjectCode != null
        ? SubjectCatalog.nameFor(snapshot.subjectCode!)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (snapshot.lastReturnNoticeVi != null) ...<Widget>[
          MindClockNoticeBanner(
            key: const ValueKey<String>('study-return-notice'),
            message: snapshot.lastReturnNoticeVi!,
            isWarm: snapshot.status == StudyFocusStatus.interrupted ||
                snapshot.commitmentAwaitingResume ||
                snapshot.level == StudyFocusLevel.standard,
          ),
          SizedBox(height: mc.space12),
        ],
        if (vm.remoteSessionErrorVi != null) ...<Widget>[
          MindClockNoticeBanner(
            key: const ValueKey<String>('study-remote-session-error'),
            message: vm.remoteSessionErrorVi!,
            isWarm: true,
          ),
          SizedBox(height: mc.space8),
          MindClockButton(
            key: const ValueKey<String>('study-retry-remote-session'),
            label: 'Thử tạo phiên server lại',
            icon: MindClockIconKind.info,
            variant: MindClockButtonVariant.secondary,
            onPressed: vm.retryCreateRemoteSession,
          ),
          SizedBox(height: mc.space12),
        ],
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(mc.space20),
          decoration: BoxDecoration(
            color: mc.night,
            borderRadius: BorderRadius.circular(mc.radiusCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: <Widget>[
                  MindClockStatusPill(
                    label: statusText,
                    accentWarm: snapshot.status != StudyFocusStatus.running ||
                        snapshot.commitmentAwaitingResume,
                  ),
                  if (subjectName != null)
                    MindClockStatusPill(label: subjectName),
                  MindClockStatusPill(
                    key: const ValueKey<String>('study-remote-session-pill'),
                    label: snapshot.remoteSessionSynced
                        ? (vm.isAiDebugFixture
                            ? 'Phiên mẫu (debug)'
                            : 'Server: Đã tạo phiên')
                        : 'Phiên local',
                    accentWarm: !snapshot.remoteSessionSynced,
                  ),
                ],
              ),
              SizedBox(height: mc.space12),
              Text(
                'Bạn đang học: ${snapshot.taskTitle}',
                key: const ValueKey<String>('study-active-task-title'),
                style: mc.sectionTitleStyle.copyWith(color: mc.nightText),
              ),
              SizedBox(height: mc.space16),
              Center(
                child: Column(
                  children: <Widget>[
                    if (!reduceMotion)
                      Padding(
                        padding: EdgeInsets.only(bottom: mc.space12),
                        child: CustomPaint(
                          key: const ValueKey<String>('study-progress-ring'),
                          size: const Size.square(112),
                          painter: _ThinProgressRingPainter(
                            progress: vm.progressFraction,
                            trackColor: mc.nightSurface,
                            fillColor: mc.sunrise,
                          ),
                        ),
                      ),
                    Semantics(
                      label:
                          'Thời gian còn lại ${formatDurationClock(remainingSec)}',
                      child: Text(
                        formatDurationClock(remainingSec),
                        key: const ValueKey<String>('study-timer-clock'),
                        style: mc.alarmHeroStyle,
                      ),
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      reduceMotion
                          ? 'Chế độ số tĩnh đang bật (Reduce Motion).'
                          : 'Đếm ngược theo mốc thời gian thiết bị.',
                      style: mc.captionStyle.copyWith(color: mc.nightText),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space16),
              Wrap(
                spacing: mc.space12,
                runSpacing: mc.space8,
                children: <Widget>[
                  Text(
                    'Thời gian thực tế: ${formatDurationClock(wallSec)}',
                    key: const ValueKey<String>('study-wall-seconds'),
                    style: mc.captionStyle.copyWith(color: mc.sunrise),
                  ),
                  Text(
                    'Trong app: ${formatDurationClock(inAppSec)}',
                    key: const ValueKey<String>('study-inapp-seconds'),
                    style: mc.captionStyle.copyWith(color: mc.nightText),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: mc.space16),
        if (snapshot.status == StudyFocusStatus.interrupted ||
            snapshot.commitmentAwaitingResume ||
            snapshot.status == StudyFocusStatus.paused)
          MindClockButton(
            key: const ValueKey<String>('study-resume-button'),
            label: AppStrings.studyResumeCta,
            icon: MindClockIconKind.play,
            onPressed: vm.resumeSession,
          )
        else
          MindClockButton(
            key: const ValueKey<String>('study-pause-button'),
            label: AppStrings.studyPauseCta,
            icon: MindClockIconKind.pause,
            variant: MindClockButtonVariant.secondary,
            onPressed: vm.pauseSession,
          ),
        SizedBox(height: mc.space12),
        MindClockButton(
          key: const ValueKey<String>('study-finish-button'),
          label: AppStrings.studyFinishCta,
          icon: MindClockIconKind.stop,
          variant: MindClockButtonVariant.subtle,
          onPressed: () {
            final bool early = remainingSec > 0;
            vm.finishSession(early: early);
          },
        ),
        SizedBox(height: mc.space16),
        _buildAiHelpCard(context, mc, vm, snapshot),
        SizedBox(height: mc.space16),
        _buildDigitalWellbeingCard(context, mc, vm),
      ],
    );
  }

  Widget _buildAiHelpCard(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
    StudyFocusSessionSnapshot snapshot,
  ) {
    final bool isLoading = vm.aiStatus == StudyAiRequestStatus.loading;
    final bool hasRetryableError = vm.aiStatus == StudyAiRequestStatus.timeout ||
        vm.aiStatus == StudyAiRequestStatus.rateLimited ||
        vm.aiStatus == StudyAiRequestStatus.offline ||
        vm.aiStatus == StudyAiRequestStatus.authExpired ||
        vm.aiStatus == StudyAiRequestStatus.error;

    return MindClockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text('Hỏi MindClock (AI qua backend)', style: mc.sectionTitleStyle),
              MindClockStatusPill(
                key: const ValueKey<String>('study-ai-status-pill'),
                label: !vm.hasAiGateway
                    ? 'Chưa nối backend'
                    : vm.isAiDebugFixture
                        ? 'Mẫu debug'
                        : (vm.isAuthenticated ? 'Sẵn sàng' : 'Cần đăng nhập'),
                accentWarm: !vm.hasAiGateway || !vm.isAuthenticated,
              ),
            ],
          ),
          SizedBox(height: mc.space8),
          Text(
            vm.isAiDebugFixture
                ? 'Đang dùng dữ liệu mẫu debug. Ở bản nối thật, câu hỏi đi qua POST /v1/study/help (tối đa 3 lượt gần nhất), không gửi key ở máy.'
                : 'Hỏi qua máy chủ backend MindClock (tối đa 3 lượt gần nhất). Câu hỏi bạn đang gõ được giữ nguyên nếu lỗi mạng/timeout/hết lượt.',
            style: mc.captionStyle,
          ),
          if (vm.aiTurns.isNotEmpty) ...<Widget>[
            SizedBox(height: mc.space12),
            ...vm.aiTurns.asMap().entries.map((MapEntry<int, StudyHelpTurn> e) {
              final StudyHelpTurn turn = e.value;
              final bool isAssistant = turn.role == 'assistant';
              return Padding(
                padding: EdgeInsets.only(bottom: mc.space8),
                child: Container(
                  key: ValueKey<String>('study-ai-turn-${e.key}'),
                  width: double.infinity,
                  padding: EdgeInsets.all(mc.space12),
                  decoration: BoxDecoration(
                    color: isAssistant ? mc.primarySoft : mc.paper,
                    borderRadius: BorderRadius.circular(mc.radiusChip),
                    border: Border.all(color: mc.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isAssistant ? 'MindClock AI' : 'Bạn',
                        style: mc.chipLabelStyle,
                      ),
                      SizedBox(height: mc.space4),
                      Text(turn.contentVi, style: mc.bodyStyle),
                      if (turn.nextQuestionVi != null &&
                          turn.nextQuestionVi!.isNotEmpty) ...<Widget>[
                        SizedBox(height: mc.space4),
                        Text(
                          'Gợi ý tiếp: ${turn.nextQuestionVi!}',
                          style: mc.captionStyle,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
          if (isLoading) ...<Widget>[
            SizedBox(height: mc.space8),
            const MindClockNoticeBanner(
              key: ValueKey<String>('study-ai-loading-banner'),
              message: 'Đang gửi câu hỏi tới MindClock qua backend (/v1/study/help)...',
              isWarm: false,
            ),
          ] else if (hasRetryableError && vm.aiErrorVi != null) ...<Widget>[
            SizedBox(height: mc.space8),
            MindClockNoticeBanner(
              key: const ValueKey<String>('study-ai-error-banner'),
              message: vm.aiErrorVi!,
              isWarm: true,
            ),
          ],
          SizedBox(height: mc.space12),
          TextField(
            key: const ValueKey<String>('study-ai-question-input'),
            controller: _aiInputController,
            enabled: !isLoading,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Đang vướng ở bước nào?',
              hintText: 'Ví dụ: Mình chưa rõ cách đặt ẩn cho bài này...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(mc.radiusControl),
              ),
            ),
          ),
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('study-ai-send-button'),
            label: isLoading ? 'Đang chờ AI...' : 'Gửi câu hỏi',
            icon: MindClockIconKind.info,
            onPressed: isLoading ? null : () => _submitAiHelp(vm),
          ),
          if (hasRetryableError &&
              (_aiInputController.text.trim().isNotEmpty ||
                  (vm.pendingHelpQuestion != null &&
                      vm.pendingHelpQuestion!.isNotEmpty))) ...<Widget>[
            SizedBox(height: mc.space8),
            MindClockButton(
              key: const ValueKey<String>('study-ai-retry-button'),
              label: 'Thử lại câu hỏi',
              icon: MindClockIconKind.play,
              variant: MindClockButtonVariant.secondary,
              onPressed: isLoading ? null : () => _retryAiHelp(vm),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryAndSave(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
    StudyFocusSessionSnapshot snapshot,
  ) {
    final DateTime endAt = DateTime.fromMillisecondsSinceEpoch(
      snapshot.endedAtEpochMs ?? vm.currentTime.millisecondsSinceEpoch,
    );
    final int wallSec = snapshot.elapsedWallSecondsAt(endAt);
    final int inAppSec = snapshot.inAppFocusSecondsAt(endAt);
    final bool finishedGoal = snapshot.status == StudyFocusStatus.completed;

    return MindClockCard(
      highlighted: finishedGoal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            finishedGoal
                ? 'Đã hết thời gian phiên học'
                : 'Kết thúc sớm phiên học',
            style: mc.sectionTitleStyle,
          ),
          SizedBox(height: mc.space8),
          Text('Việc đã chọn: ${snapshot.taskTitle}', style: mc.bodyStrongStyle),
          SizedBox(height: mc.space8),
          Text(
            'Thời gian thực tế: ${formatDurationClock(wallSec)}',
            key: const ValueKey<String>('study-summary-wall'),
            style: mc.bodyStyle,
          ),
          SizedBox(height: mc.space4),
          Text(
            'Thời gian tập trung trong app: ${formatDurationClock(inAppSec)}',
            key: const ValueKey<String>('study-summary-inapp'),
            style: mc.bodyStyle,
          ),
          SizedBox(height: mc.space4),
          Text(
            'Điểm XP từ đồng hồ/camera: 0 XP (chỉ ghi nhận lịch sử học cục bộ).',
            style: mc.captionStyle,
          ),
          SizedBox(height: mc.space16),
          if (finishedGoal &&
              snapshot.durationMinutes <
                  StudyFocusSessionSnapshot.maxDurationMinutes) ...<Widget>[
            MindClockButton(
              key: const ValueKey<String>('study-add-extra-5m'),
              label: 'Cần thêm 5 phút',
              icon: MindClockIconKind.plus,
              variant: MindClockButtonVariant.secondary,
              onPressed: () => vm.addExtraMinutes(5),
            ),
            SizedBox(height: mc.space12),
          ],
          TextField(
            key: const ValueKey<String>('study-notes-done-input'),
            controller: _doneController,
            onChanged: (String text) => vm.updateReflectionNotes(done: text),
            decoration: InputDecoration(
              labelText: 'Bạn đã làm được gì? (tùy chọn)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(mc.radiusControl),
              ),
            ),
          ),
          SizedBox(height: mc.space12),
          TextField(
            key: const ValueKey<String>('study-notes-stuck-input'),
            controller: _stuckController,
            onChanged: (String text) => vm.updateReflectionNotes(stuck: text),
            decoration: InputDecoration(
              labelText: 'Còn vướng chỗ nào? (tùy chọn)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(mc.radiusControl),
              ),
            ),
          ),
          SizedBox(height: mc.space16),
          MindClockButton(
            key: const ValueKey<String>('study-save-session-button'),
            label: AppStrings.studySaveCta,
            icon: MindClockIconKind.check,
            onPressed: () async {
              await vm.saveFinishedSession(
                notesDone: _doneController.text,
                notesStuck: _stuckController.text,
              );
              _doneController.clear();
              _stuckController.clear();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalWellbeingCard(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
  ) {
    return MindClockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Tập trung với công cụ hệ thống', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          Text(AppStrings.studyNoAppLockExplain, style: mc.captionStyle),
          if (vm.wellbeingFeedbackVi != null) ...<Widget>[
            SizedBox(height: mc.space8),
            MindClockNoticeBanner(
              key: const ValueKey<String>('study-wellbeing-feedback'),
              message: vm.wellbeingFeedbackVi!,
            ),
          ],
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('study-open-digital-wellbeing'),
            label: 'Mở Digital Wellbeing Focus mode',
            icon: MindClockIconKind.info,
            variant: MindClockButtonVariant.secondary,
            onPressed: vm.openDigitalWellbeingFocusSettings,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
    List<StudyFocusRecord> history,
  ) {
    return MindClockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Phiên học đã lưu trên máy (${history.length})',
            key: const ValueKey<String>('study-history-title'),
            style: mc.sectionTitleStyle,
          ),
          SizedBox(height: mc.space8),
          ...history.take(5).map((StudyFocusRecord item) {
            return Padding(
              padding: EdgeInsets.only(bottom: mc.space8),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(mc.space12),
                decoration: BoxDecoration(
                  color: mc.paper,
                  borderRadius: BorderRadius.circular(mc.radiusChip),
                  border: Border.all(color: mc.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(item.taskTitle, style: mc.bodyStrongStyle),
                    SizedBox(height: mc.space4),
                    Text(
                      '${item.level.labelVi} · Thực tế ${formatDurationClock(item.elapsedWallSeconds)} · '
                      'Trong app ${formatDurationClock(item.inAppFocusSeconds)} · ${item.xpAwardedByTimer} XP',
                      style: mc.captionStyle,
                    ),
                    SizedBox(height: mc.space4),
                    Text(
                      item.remoteFinishSynced
                          ? (vm.isAiDebugFixture
                              ? 'Đồng bộ mẫu (debug)'
                              : 'Đã đồng bộ kết thúc lên server')
                          : (item.remoteSyncErrorVi ??
                              'Chưa đồng bộ kết thúc lên server (lưu an toàn trên máy)'),
                      key: ValueKey<String>(
                          'study-history-sync-${item.sessionId}'),
                      style: mc.captionStyle.copyWith(
                        color: item.remoteFinishSynced ? mc.primary : mc.inkMuted,
                      ),
                    ),
                    if (!item.remoteFinishSynced &&
                        vm.isAuthenticated &&
                        vm.hasAiGateway) ...<Widget>[
                      SizedBox(height: mc.space8),
                      MindClockButton(
                        key: ValueKey<String>(
                            'study-history-retry-${item.sessionId}'),
                        label: 'Đồng bộ lại kết thúc phiên',
                        icon: MindClockIconKind.info,
                        variant: MindClockButtonVariant.secondary,
                        expand: false,
                        onPressed: () =>
                            vm.retryFinishRecordSync(item.sessionId),
                      ),
                    ],
                    if (item.notesDone.isNotEmpty) ...<Widget>[
                      SizedBox(height: mc.space4),
                      Text('Đã làm: ${item.notesDone}', style: mc.captionStyle),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  const _SelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return MindClockPressable(
      selected: selected,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(mc.radiusChip),
      onPressed: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: mc.minTouchTarget),
        padding: EdgeInsets.symmetric(
          horizontal: mc.space12,
          vertical: mc.space8,
        ),
        decoration: BoxDecoration(
          color: selected ? mc.primary : mc.paper,
          borderRadius: BorderRadius.circular(mc.radiusChip),
          border: Border.all(color: selected ? mc.primary : mc.outline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                softWrap: true,
                style: mc.chipLabelStyle.copyWith(
                  color: selected ? mc.onPrimary : mc.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    super.key,
    required this.label,
    required this.value,
    required this.onToggle,
  });

  final String label;
  final bool value;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return MindClockPressable(
      selected: value,
      semanticLabel: label,
      borderRadius: BorderRadius.circular(mc.radiusControl),
      onPressed: onToggle,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: mc.minTouchTarget),
        padding: EdgeInsets.symmetric(
          horizontal: mc.space12,
          vertical: mc.space8,
        ),
        decoration: BoxDecoration(
          color: value ? mc.primarySoft : mc.paper,
          borderRadius: BorderRadius.circular(mc.radiusControl),
          border: Border.all(color: value ? mc.primary : mc.outline),
        ),
        child: Wrap(
          spacing: mc.space8,
          runSpacing: mc.space4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(label, style: mc.bodyStyle),
            MindClockStatusPill(label: value ? 'Đang bật' : 'Đang tắt'),
          ],
        ),
      ),
    );
  }
}

class _ThinProgressRingPainter extends CustomPainter {
  const _ThinProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
  });

  final double progress;
  final Color trackColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - 8) / 2;
    final Paint track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    final Paint fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;

    canvas.drawCircle(center, radius, track);
    final double sweep = 2 * 3.1415926535 * progress.clamp(0.0, 1.0);
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.1415926535 / 2,
        sweep,
        false,
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ThinProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.fillColor != fillColor;
}
