import 'package:flutter/material.dart';

import '../../../../data/debug/debug_fixture_community_repository.dart';
import '../../../../data/services/method_channel_media_picker_gateway.dart';
import '../../../../data/services/method_channel_study_speech_gateway.dart';
import '../../../../data/services/method_channel_study_voice_input.dart';
import '../../../../domain/models/community_models.dart';
import '../../../../domain/models/daily_todo_task.dart';
import '../../../../domain/models/study_ai_models.dart';
import '../../../../domain/models/study_focus_models.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../../domain/services/media_picker_gateway.dart';
import '../../../../domain/services/study_speech_gateway.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/math_formula_text.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../guest_shell/view_models/guest_workspace_view_model.dart';
import '../view_models/study_focus_view_model.dart';
import '../view_models/study_speech_view_model.dart';
import '../view_models/study_room_session_view_model.dart';
import 'study_room_session_panel.dart';
import 'study_candle_timer.dart';
import 'study_community_sheet.dart';

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
    this.communityRepository,
    this.mediaPickerGateway,
    this.initialRoom,
    this.onRoomChanged,
    this.speechGateway,
    this.voiceInputGateway,
  });

  final GuestWorkspaceViewModel guestViewModel;
  final StudyFocusViewModel studyViewModel;
  final VoidCallback onClose;
  final CommunityRepository? communityRepository;
  final MediaPickerGateway? mediaPickerGateway;
  final StudyRoomDetail? initialRoom;
  final ValueChanged<StudyRoomDetail?>? onRoomChanged;
  final StudySpeechGateway? speechGateway;
  final StudyVoiceInputGateway? voiceInputGateway;

  @override
  State<StudySpaceScreen> createState() => _StudySpaceScreenState();
}

enum _StudyEntryBranch { solo, withAi, withFriends }

enum _StudyStartScheduleMode { startNow, scheduleLater }

class _StudySpaceScreenState extends State<StudySpaceScreen>
    with WidgetsBindingObserver {
  final TextEditingController _customTaskController = TextEditingController();
  final TextEditingController _doneController = TextEditingController();
  final TextEditingController _stuckController = TextEditingController();
  final TextEditingController _aiInputController = TextEditingController();
  final TextEditingController _aiTriedStepController = TextEditingController();
  final TextEditingController _personalizedTopicController =
      TextEditingController();
  String? _selectedPersonalizedSubject;
  late _StudyEntryBranch _entryBranch;
  _StudyStartScheduleMode _scheduleMode = _StudyStartScheduleMode.startNow;
  int _scheduleStartMinutes = 20 * 60;
  String? _scheduleSavedBannerVi;
  String? _attachedQuestionPhotoName;
  String? _photoInputMessageVi;
  bool _socraticStepLockEnabled = false;
  String? _socraticLockWarningVi;
  bool _microCheckExpanded = false;
  int _microCheckIndex = 0;
  int? _microCheckPickedIndex;
  String? _ambientAudioPath;
  String? _ambientAudioLabel;
  bool _ambientAudioPlaying = false;
  bool _pickingAmbientAudio = false;
  String? _ambientAudioStatusVi;
  late final StudyRoomSessionViewModel _roomVm;
  late final CommunityRepository _roomRepository;
  late final StudySpeechViewModel _speech;
  bool _foreground = true;
  bool _voiceInputPending = false;
  String? _voiceInputMessage;
  StudyRoomDetail? get _activeMeetRoom => _roomVm.room;

  CommunityRepository get _communityRepo => _roomRepository;

  MediaPickerGateway get _mediaPicker =>
      widget.mediaPickerGateway ?? MethodChannelMediaPickerGateway();

  @override
  void initState() {
    super.initState();
    final StudyRoomDetail? validInitialRoom =
        (widget.initialRoom != null && widget.initialRoom!.summary.isOpen)
            ? widget.initialRoom
            : null;
    if (validInitialRoom != null) {
      _entryBranch = _StudyEntryBranch.withFriends;
    } else if (widget.studyViewModel.draftRoomMode == StudyRoomMode.solo) {
      _entryBranch = _StudyEntryBranch.solo;
    } else {
      _entryBranch = _StudyEntryBranch.withAi;
    }
    if (widget.initialRoom != null && validInitialRoom == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onRoomChanged?.call(null);
      });
    }
    _speech = StudySpeechViewModel(
        gateway: widget.speechGateway ??
            MethodChannelStudySpeechGateway.withAudio(
                synthesize: widget.studyViewModel.hasCloudVoice
                    ? widget.studyViewModel.createReplyVoice
                    : null),
        startTimeout: widget.studyViewModel.hasCloudVoice
            ? const Duration(seconds: 65)
            : const Duration(seconds: 15));
    _configureSpeech();
    _speech.addListener(_onSpeechState);
    widget.studyViewModel.addListener(_configureSpeech);
    _roomRepository =
        widget.communityRepository ?? DebugFixtureCommunityRepository();
    _roomVm = StudyRoomSessionViewModel(
        repository: _roomRepository,
        initialRoom: validInitialRoom,
        enablePolling: widget.studyViewModel.enablePeriodicTicker);
    _roomVm.addListener(_onRoomState);
    WidgetsBinding.instance.addObserver(this);
    _customTaskController.text = widget.studyViewModel.draftTaskTitle;
    if (widget.studyViewModel.pendingHelpQuestion != null) {
      _aiInputController.text = widget.studyViewModel.pendingHelpQuestion!;
    }
  }

  void _changeRoom(StudyRoomDetail? room) {
    _speech.stop();
    if (room != null) {
      _entryBranch = _StudyEntryBranch.withFriends;
    }
    _roomVm.attach(room);
  }

  void _onSpeechState() {
    if (mounted) setState(() {});
  }

  void _configureSpeech() {
    final vm = widget.studyViewModel;
    final snapshot = vm.activeSnapshot;
    _speech.configure(
      scope: '${vm.ownerScopeKey}/${snapshot?.sessionId}',
      allowed: _foreground &&
          vm.isAuthenticated &&
          snapshot?.roomMode == StudyRoomMode.withAi &&
          snapshot?.cadence != StudyCadence.deepSilent &&
          snapshot?.status == StudyFocusStatus.running,
    );
  }

  Future<void> _readAiReply(StudyFocusViewModel vm, StudyHelpTurn turn) async {
    if (_speech.isBusy) {
      _speech.stop();
      return;
    }
    final scope = vm.ownerScopeKey;
    final session = vm.activeSnapshot?.sessionId;
    if (vm.hasCloudVoice) {
      final approved = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
                title: const Text('Nghe giọng MindClock AI'),
                content: const Text(
                    'Nội dung câu trả lời này sẽ được gửi tới Google Gemini để tạo giọng nói. Âm thanh được giữ tạm và xóa khi dừng phát. Mic và camera vẫn tắt.'),
                actions: [
                  MindClockButton(
                      key: const ValueKey('study-voice-consent-cancel'),
                      label: 'Để sau',
                      variant: MindClockButtonVariant.subtle,
                      onPressed: () => Navigator.pop(dialogContext, false)),
                  MindClockButton(
                      key: const ValueKey('study-voice-consent-accept'),
                      label: 'Đồng ý nghe',
                      onPressed: () => Navigator.pop(dialogContext, true)),
                ],
              ));
      if (approved != true || !mounted) return;
    }
    // Dialog can outlive account/session. Never speak a previous user's reply.
    if (!mounted ||
        vm.ownerScopeKey != scope ||
        vm.activeSnapshot?.sessionId != session ||
        !vm.isAuthenticated ||
        vm.activeSnapshot?.status != StudyFocusStatus.running ||
        vm.activeSnapshot?.cadence == StudyCadence.deepSilent) {
      return;
    }
    await _speech.readReply([
      turn.contentVi,
      if (turn.nextQuestionVi != null) turn.nextQuestionVi!
    ].join(' '));
  }

  Future<void> _askByVoice(StudyFocusViewModel vm) async {
    if (_voiceInputPending ||
        !vm.isAuthenticated ||
        vm.activeSnapshot?.cadence == StudyCadence.deepSilent) {
      return;
    }
    final scope = vm.ownerScopeKey;
    final session = vm.activeSnapshot?.sessionId;
    final approved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: const Text('Nhập câu hỏi bằng giọng nói'),
              content: const Text(
                  'Bộ nhận giọng nói của thiết bị sẽ dùng mic và có thể xử lý âm thanh trực tuyến. Bạn xem lại bản chữ trước; chỉ khi bấm Gửi câu hỏi thì nội dung mới được gửi cho MindClock.'),
              actions: [
                MindClockButton(
                    key: const ValueKey('study-mic-consent-cancel'),
                    label: 'Để sau',
                    variant: MindClockButtonVariant.subtle,
                    onPressed: () => Navigator.pop(dialogContext, false)),
                MindClockButton(
                    key: const ValueKey('study-mic-consent-accept'),
                    label: 'Mở nhập giọng nói',
                    onPressed: () => Navigator.pop(dialogContext, true)),
              ],
            ));
    if (approved != true ||
        !mounted ||
        vm.ownerScopeKey != scope ||
        vm.activeSnapshot?.sessionId != session) {
      return;
    }
    _speech.stop();
    setState(() {
      _voiceInputPending = true;
      _voiceInputMessage = null;
    });
    try {
      final text = await (widget.voiceInputGateway ??
              const MethodChannelStudyVoiceInput())
          .recognizeQuestion();
      if (!mounted ||
          vm.ownerScopeKey != scope ||
          vm.activeSnapshot?.sessionId != session ||
          !vm.isAuthenticated) {
        return;
      }
      if (text != null && text.isNotEmpty) {
        _aiInputController.text = text;
        _voiceInputMessage =
            'Đã nhập câu hỏi. Kiểm tra lại rồi bấm Gửi câu hỏi.';
      }
    } catch (_) {
      if (mounted) {
        _voiceInputMessage =
            'Chưa nhận được giọng nói trên thiết bị này. Bạn vẫn có thể nhập chữ.';
      }
    } finally {
      if (mounted) {
        setState(() {
          _voiceInputPending = false;
        });
      }
    }
  }

  void _onRoomState() {
    if (!mounted) return;
    setState(() {});
    widget.onRoomChanged?.call(_roomVm.room);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _configureSpeech();
    _roomVm.setForeground(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.studyViewModel.removeListener(_configureSpeech);
    _speech.removeListener(_onSpeechState);
    _speech.dispose();
    _roomVm.removeListener(_onRoomState);
    _roomVm.dispose();
    if (_ambientAudioPlaying) {
      _mediaPicker.stopAudioPreview();
    }
    _customTaskController.dispose();
    _doneController.dispose();
    _stuckController.dispose();
    _aiInputController.dispose();
    _aiTriedStepController.dispose();
    _personalizedTopicController.dispose();
    super.dispose();
  }

  Future<void> _pickAmbientAudio() async {
    if (_pickingAmbientAudio) return;
    setState(() {
      _pickingAmbientAudio = true;
      _ambientAudioStatusVi = null;
    });
    final MediaPickResult res = await _mediaPicker.pickAlarmAudio();
    if (!mounted) return;
    setState(() {
      _pickingAmbientAudio = false;
      if (res.picked && res.localPath != null) {
        _ambientAudioPath = res.localPath;
        _ambientAudioLabel = res.displayName ?? 'Nhạc nền tập trung';
        _ambientAudioStatusVi = 'Đã chọn tệp nhạc: $_ambientAudioLabel.';
      } else if (!res.cancelled && res.errorMessageVi != null) {
        _ambientAudioStatusVi = res.errorMessageVi;
      }
    });
  }

  Future<void> _toggleAmbientAudio() async {
    if (_ambientAudioPlaying) {
      await _mediaPicker.stopAudioPreview();
      if (!mounted) return;
      setState(() {
        _ambientAudioPlaying = false;
        _ambientAudioStatusVi = 'Đã tắt nhạc nền tập trung.';
      });
      return;
    }
    if (_ambientAudioPath == null || _ambientAudioPath!.isEmpty) {
      setState(() {
        _ambientAudioStatusVi = 'Hãy chọn tệp nhạc trên máy trước khi phát.';
      });
      return;
    }
    final bool started = await _mediaPicker.previewAudio(
      soundOption: 'custom_local',
      customSoundPath: _ambientAudioPath,
      loop: true,
    );
    if (!mounted) return;
    setState(() {
      _ambientAudioPlaying = started;
      _ambientAudioStatusVi = started
          ? 'Đang phát lặp nhạc nền từ máy...'
          : 'Không phát được nhạc nền trên môi trường này.';
    });
  }

  Widget _buildAmbientAudioCard(
    MindClockTheme mc, {
    required bool lockedByDeepSilent,
  }) {
    return MindClockCard(
      key: const ValueKey<String>('study-ambient-audio-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Nhạc nền tập trung (từ máy · mặc định tắt)',
              style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          Text(
            lockedByDeepSilent
                ? 'Đang khóa im lặng hoàn toàn theo chế độ Học sâu (im lặng).'
                : (_ambientAudioLabel != null
                    ? 'Tệp đang chọn: $_ambientAudioLabel'
                    : 'Mặc định tắt. Bạn có thể chọn 1 file MP3/âm thanh trên máy để nghe nhẹ khi Học ngắt quãng.'),
            style: mc.captionStyle,
          ),
          if (!lockedByDeepSilent) ...<Widget>[
            SizedBox(height: mc.space12),
            Wrap(
              spacing: mc.space8,
              runSpacing: mc.space8,
              children: <Widget>[
                MindClockButton(
                  key: const ValueKey<String>('study-pick-ambient-audio-btn'),
                  label: _pickingAmbientAudio
                      ? 'Đang mở tệp...'
                      : 'Chọn nhạc nền từ máy',
                  icon: MindClockIconKind.edit,
                  variant: MindClockButtonVariant.secondary,
                  expand: false,
                  onPressed: _pickingAmbientAudio ? null : _pickAmbientAudio,
                ),
                if (_ambientAudioPath != null)
                  MindClockButton(
                    key: const ValueKey<String>(
                        'study-toggle-ambient-audio-btn'),
                    label: _ambientAudioPlaying
                        ? 'Dừng nhạc nền'
                        : 'Phát nhạc nền',
                    icon: _ambientAudioPlaying
                        ? MindClockIconKind.stop
                        : MindClockIconKind.volumeOn,
                    variant: MindClockButtonVariant.subtle,
                    expand: false,
                    onPressed: _toggleAmbientAudio,
                  ),
              ],
            ),
          ],
          if (_ambientAudioStatusVi != null) ...<Widget>[
            SizedBox(height: mc.space8),
            Text(_ambientAudioStatusVi!, style: mc.captionStyle),
          ],
        ],
      ),
    );
  }

  String _headerScopeLabel(StudyFocusViewModel vm) {
    if (_activeMeetRoom != null ||
        (vm.activeSnapshot == null &&
            _entryBranch == _StudyEntryBranch.withFriends)) {
      return 'Học cùng bạn · Mic & camera tắt mặc định';
    }
    final StudyRoomMode activeMode =
        vm.activeSnapshot?.roomMode ?? vm.draftRoomMode;
    if (activeMode == StudyRoomMode.solo) {
      return 'Học một mình · Không có AI';
    }
    if (!vm.hasAiGateway) {
      return 'Học cùng MindClock AI · Chế độ trên máy';
    }
    if (vm.isAuthenticated) {
      return 'Học cùng MindClock AI';
    }
    return 'Học cùng MindClock AI · Đăng nhập để hỏi AI';
  }

  String _formatMinutesOfDay(int minutes) {
    final int clamped = minutes.clamp(0, 1439);
    final int h = clamped ~/ 60;
    final int m = clamped % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmScheduleStudy({
    required StudyFocusViewModel vm,
    required String title,
    required String? subjectCode,
    required int durationMinutes,
  }) async {
    final String cleanTitle = title.trim().isEmpty ? 'Phiên tự học' : title.trim();
    await widget.guestViewModel.addDailyTodoTask(
      title: cleanTitle,
      date: vm.currentTime,
      startMinutes: _scheduleStartMinutes,
      durationMinutes: durationMinutes,
      subjectCode: subjectCode,
      category: DailyTodoCategory.selfStudy,
      remindOnTime: true,
    );
    if (!mounted) return;
    setState(() {
      _scheduleSavedBannerVi =
          'Đã hẹn giờ "$cleanTitle" lúc ${_formatMinutesOfDay(_scheduleStartMinutes)} trong lịch hôm nay.';
    });
  }

  Future<void> _attachQuestionPhotoWithConsent(StudyFocusViewModel vm) async {
    final String scope = vm.ownerScopeKey;
    final String? session = vm.activeSnapshot?.sessionId;
    final bool? approved = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Gửi ảnh đề bài cho câu hỏi này'),
        content: const Text(
          'MindClock chỉ đọc ảnh bạn chủ động chọn cho lượt hỏi hiện tại, không bật camera nền và không lưu ảnh bài làm mặc định trên máy chủ.',
        ),
        actions: <Widget>[
          MindClockButton(
            key: const ValueKey<String>('study-photo-consent-cancel'),
            label: 'Để sau',
            variant: MindClockButtonVariant.subtle,
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          MindClockButton(
            key: const ValueKey<String>('study-photo-consent-accept'),
            label: 'Đồng ý chọn ảnh',
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (approved != true ||
        !mounted ||
        vm.ownerScopeKey != scope ||
        vm.activeSnapshot?.sessionId != session) {
      return;
    }
    final MediaPickResult res = await _mediaPicker.pickAvatarImage();
    if (!mounted ||
        vm.ownerScopeKey != scope ||
        vm.activeSnapshot?.sessionId != session) {
      return;
    }
    setState(() {
      if (res.picked) {
        _attachedQuestionPhotoName = res.displayName ?? 'anh_de_bai.jpg';
        _photoInputMessageVi =
            'Đã chọn ảnh $_attachedQuestionPhotoName. Nhập câu hỏi rồi bấm Gửi câu hỏi.';
      } else if (!res.cancelled && res.errorMessageVi != null) {
        _photoInputMessageVi = res.errorMessageVi;
      }
    });
  }

  static const List<Map<String, dynamic>> _microChecks = <Map<String, dynamic>>[
    <String, dynamic>{
      'subject': 'TOAN',
      'prompt': 'Micro-Check Toán: Hàm số đồng biến trên (a; b) khi đạo hàm:',
      'options': <String>['y\' >= 0 trên (a; b)', 'y\' < 0 trên (a; b)', 'y = 0 mọi điểm'],
      'correctIndex': 0,
    },
    <String, dynamic>{
      'subject': 'TIENG_ANH',
      'prompt': 'Micro-Check Tiếng Anh: Nghĩa sát nhất của "consistent":',
      'options': <String>['Bất ổn định', 'Nhất quán, bền bỉ', 'Ngẫu nhiên'],
      'correctIndex': 1,
    },
    <String, dynamic>{
      'subject': 'NGU_VAN',
      'prompt': 'Micro-Check Ngữ văn: Biện pháp tu từ gắn trực tiếp hai sự vật tương đồng bằng "như", "là":',
      'options': <String>['Hoán dụ', 'Nói giảm', 'So sánh'],
      'correctIndex': 2,
    },
    <String, dynamic>{
      'subject': 'VAT_LY',
      'prompt': 'Micro-Check Vật lý: Đơn vị đo tần số dao động điều hòa:',
      'options': <String>['Hertz (Hz)', 'Joule (J)', 'Newton (N)'],
      'correctIndex': 0,
    },
  ];

  Future<void> _submitAiHelp(StudyFocusViewModel vm) async {
    final String tried = _aiTriedStepController.text.trim();
    if (_socraticStepLockEnabled && tried.isEmpty) {
      setState(() {
        _socraticLockWarningVi =
            'Khóa giải hộ đang bật: hãy ghi ngắn gọn 1 bước bạn đã tự thử trước khi hỏi AI.';
      });
      return;
    }
    setState(() => _socraticLockWarningVi = null);
    final String rawQ = _aiInputController.text.trim();
    final String effectiveRawQ = (rawQ.isEmpty && _attachedQuestionPhotoName != null)
        ? 'Nhờ gợi mở cách tiếp cận đề trong ảnh đã chọn.'
        : rawQ;
    final List<String> prefixes = <String>[
      if (_attachedQuestionPhotoName != null)
        '[Ảnh đề bài đã chọn: $_attachedQuestionPhotoName]',
      if (tried.isNotEmpty) '[Bước đã tự thử: $tried]',
    ];
    final String composed = prefixes.isNotEmpty && effectiveRawQ.isNotEmpty
        ? '${prefixes.join(' ')} $effectiveRawQ'
        : effectiveRawQ;
    final bool ok = await vm.requestAiHelp(
      questionText: composed,
      gradeLevel: widget.guestViewModel.profile.gradeLevel,
      goalLabel: widget.guestViewModel.profile.goalLabel,
      fallbackSubjectCode:
          widget.guestViewModel.profile.selectedSubjectCodes.firstOrNull,
    );
    if (ok && mounted) {
      _aiInputController.clear();
      setState(() {
        _attachedQuestionPhotoName = null;
        _photoInputMessageVi = null;
      });
    }
  }

  Future<void> _retryAiHelp(StudyFocusViewModel vm) async {
    final String textToSend = _aiInputController.text.trim().isNotEmpty
        ? _aiInputController.text
        : (vm.pendingHelpQuestion ?? '');
    final bool ok = await vm.requestAiHelp(
      questionText: textToSend,
      gradeLevel: widget.guestViewModel.profile.gradeLevel,
      goalLabel: widget.guestViewModel.profile.goalLabel,
      fallbackSubjectCode:
          widget.guestViewModel.profile.selectedSubjectCodes.firstOrNull,
    );
    if (ok && mounted) {
      _aiInputController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.studyViewModel,
      builder: (BuildContext context, _) {
        final MindClockTheme mc = context.mc;
        final StudyFocusViewModel vm = widget.studyViewModel;
        final StudyFocusSessionSnapshot? snapshot = vm.activeSnapshot;
        final bool reduceMotion = vm.reduceMotionStaticMode ||
            MediaQuery.disableAnimationsOf(context);

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
                      Text(AppStrings.studySpaceTitle,
                          style: mc.screenTitleStyle),
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
                  if (vm.statusBannerVi != null &&
                      _activeMeetRoom == null) ...<Widget>[
                    SizedBox(height: mc.space12),
                    MindClockNoticeBanner(
                      message: vm.statusBannerVi!,
                      isWarm: false,
                    ),
                  ],
                  SizedBox(height: mc.space16),
                  if (_roomVm.message != null) ...<Widget>[
                    MindClockNoticeBanner(message: _roomVm.message!),
                    SizedBox(height: mc.space8),
                  ],
                  if (_activeMeetRoom != null) ...<Widget>[
                    StudyRoomSessionPanel(
                      viewModel: _roomVm,
                      repository: _communityRepo,
                      animateAi: vm.enablePeriodicTicker,
                    ),
                    if (snapshot != null && !snapshot.status.isTerminal) ...<Widget>[
                      SizedBox(height: mc.space12),
                      MindClockNoticeBanner(
                        key: const ValueKey<String>('study-room-bg-timer-banner'),
                        message:
                            'Đồng hồ cá nhân (${snapshot.taskTitle}) vẫn đếm nền khi bạn học cùng phòng.',
                        isWarm: false,
                      ),
                    ],
                  ] else if (snapshot == null)
                    _buildSetupAndHistory(context, mc, vm, reduceMotion)
                  else if (snapshot.status.isTerminal)
                    _buildSummaryAndSave(context, mc, vm, snapshot)
                  else
                    _buildActiveSession(
                        context, mc, vm, snapshot, reduceMotion),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeSelectorCard(MindClockTheme mc, StudyFocusViewModel vm) {
    final List<
        ({
          _StudyEntryBranch branch,
          String key,
          String title,
          String subtitle,
          String? badge,
        })> options = <({
      _StudyEntryBranch branch,
      String key,
      String title,
      String subtitle,
      String? badge,
    })>[
      (
        branch: _StudyEntryBranch.solo,
        key: 'study-mode-solo',
        title: 'Học một mình',
        subtitle: 'Đồng hồ tập trung, mục tiêu và ghi chú chỗ vướng; không bật AI.',
        badge: null,
      ),
      (
        branch: _StudyEntryBranch.withAi,
        key: 'study-mode-ai',
        title: 'Học cùng MindClock AI',
        subtitle: 'Phiên hỏi đáp gợi mở từng bước theo môn và lớp; không giải hộ.',
        badge: 'MindClock AI',
      ),
      (
        branch: _StudyEntryBranch.withFriends,
        key: 'study-mode-friends',
        title: 'Học cùng bạn',
        subtitle: 'Sảnh phòng học bạn bè, mic và camera tắt mặc định.',
        badge: null,
      ),
    ];

    return MindClockCard(
      key: const ValueKey<String>('study-three-modes-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Chọn cách học', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          ...options.map((item) {
            final bool selected = _entryBranch == item.branch;
            return Padding(
              padding: EdgeInsets.only(bottom: mc.space8),
              child: MindClockPressable(
                key: ValueKey<String>(item.key),
                selected: selected,
                semanticLabel: '${item.title}. ${item.subtitle}',
                borderRadius: BorderRadius.circular(mc.radiusControl),
                onPressed: () {
                  setState(() {
                    _entryBranch = item.branch;
                    _scheduleSavedBannerVi = null;
                  });
                  if (item.branch == _StudyEntryBranch.solo) {
                    vm.setRoomMode(StudyRoomMode.solo);
                  } else if (item.branch == _StudyEntryBranch.withAi) {
                    vm.setRoomMode(StudyRoomMode.withAi);
                  }
                },
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
                          Text(item.title, style: mc.bodyStrongStyle),
                          if (item.badge != null)
                            MindClockStatusPill(label: item.badge!),
                        ],
                      ),
                      SizedBox(height: mc.space4),
                      Text(item.subtitle, style: mc.captionStyle),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStartOrScheduleSection({
    required BuildContext context,
    required MindClockTheme mc,
    required StudyFocusViewModel vm,
    required String scheduleTitle,
    required String? subjectCode,
    required int durationMinutes,
    required Widget startNowButton,
  }) {
    final bool isSchedule =
        _scheduleMode == _StudyStartScheduleMode.scheduleLater;
    return MindClockCard(
      key: const ValueKey<String>('study-start-or-schedule-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Thời điểm bắt đầu', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: <Widget>[
              _SelectableChip(
                key: const ValueKey<String>('study-timing-start-now'),
                label: 'Bắt đầu ngay',
                selected: !isSchedule,
                onTap: () => setState(() {
                  _scheduleMode = _StudyStartScheduleMode.startNow;
                  _scheduleSavedBannerVi = null;
                }),
              ),
              _SelectableChip(
                key: const ValueKey<String>('study-timing-schedule-later'),
                label: 'Hẹn giờ',
                selected: isSchedule,
                onTap: () => setState(() {
                  _scheduleMode = _StudyStartScheduleMode.scheduleLater;
                  _scheduleSavedBannerVi = null;
                }),
              ),
            ],
          ),
          SizedBox(height: mc.space12),
          if (!isSchedule)
            startNowButton
          else ...<Widget>[
            Text(
              'Chọn giờ hẹn trong ngày (chỉ tạo lịch khi bạn bấm xác nhận):',
              style: mc.captionStyle,
            ),
            SizedBox(height: mc.space8),
            Wrap(
              spacing: mc.space8,
              runSpacing: mc.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                MindClockButton(
                  key: const ValueKey<String>('study-schedule-minus-15'),
                  label: '-15 phút',
                  icon: MindClockIconKind.minus,
                  variant: MindClockButtonVariant.subtle,
                  expand: false,
                  onPressed: () => setState(() {
                    _scheduleStartMinutes =
                        (_scheduleStartMinutes - 15 + 1440) % 1440;
                  }),
                ),
                Text(
                  _formatMinutesOfDay(_scheduleStartMinutes),
                  key: const ValueKey<String>('study-schedule-time-display'),
                  style: mc.sectionTitleStyle,
                ),
                MindClockButton(
                  key: const ValueKey<String>('study-schedule-plus-15'),
                  label: '+15 phút',
                  icon: MindClockIconKind.plus,
                  variant: MindClockButtonVariant.subtle,
                  expand: false,
                  onPressed: () => setState(() {
                    _scheduleStartMinutes = (_scheduleStartMinutes + 15) % 1440;
                  }),
                ),
              ],
            ),
            if (_scheduleSavedBannerVi != null) ...<Widget>[
              SizedBox(height: mc.space8),
              MindClockNoticeBanner(
                key: const ValueKey<String>('study-schedule-saved-banner'),
                message: _scheduleSavedBannerVi!,
                isWarm: false,
              ),
            ],
            SizedBox(height: mc.space12),
            MindClockButton(
              key: const ValueKey<String>('study-confirm-schedule-button'),
              label: 'Xác nhận hẹn giờ học',
              icon: MindClockIconKind.calendar,
              onPressed: () => _confirmScheduleStudy(
                vm: vm,
                title: scheduleTitle,
                subjectCode: subjectCode,
                durationMinutes: durationMinutes,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFriendsSetup(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
  ) {
    final List<String> profileSubjects = _availablePersonalSubjects(vm);
    final String firstSubject = profileSubjects.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MindClockCard(
          key: const ValueKey<String>('study-friends-setup-card'),
          highlighted: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Phòng học cùng bạn', style: mc.sectionTitleStyle),
              SizedBox(height: mc.space8),
              Text(
                'Tạo phòng mới, vào bằng mã mời hoặc ghép nhóm theo môn và lớp bạn đang học.',
                style: mc.captionStyle,
              ),
              SizedBox(height: mc.space12),
              const MindClockNoticeBanner(
                key: ValueKey<String>('study-friends-media-notice'),
                message:
                    'Mic và camera tắt mặc định. Phòng hiện đồng bộ thành viên và trạng thái học, chưa truyền cuộc gọi âm thanh/video trực tiếp.',
                isWarm: false,
              ),
            ],
          ),
        ),
        SizedBox(height: mc.space16),
        _buildStartOrScheduleSection(
          context: context,
          mc: mc,
          vm: vm,
          scheduleTitle:
              'Học cùng bạn môn ${SubjectCatalog.nameFor(firstSubject)}',
          subjectCode: firstSubject,
          durationMinutes: 45,
          startNowButton: MindClockButton(
            key: const ValueKey<String>('study-open-community-hub'),
            label: 'Mở sảnh phòng học cùng bạn',
            icon: MindClockIconKind.user,
            onPressed: () async {
              final StudyRoomDetail? joined = await showStudyCommunityHub(
                context: context,
                repository: _communityRepo,
                currentProfile: widget.guestViewModel.profile,
              );
              if (joined != null && mounted) {
                _changeRoom(joined);
              }
            },
          ),
        ),
      ],
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

    if (_entryBranch == _StudyEntryBranch.withFriends) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildModeSelectorCard(mc, vm),
          SizedBox(height: mc.space16),
          _buildFriendsSetup(context, mc, vm),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildModeSelectorCard(mc, vm),
        SizedBox(height: mc.space16),
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
              Text('Môn theo hồ sơ của bạn', style: mc.bodyStrongStyle),
              SizedBox(height: mc.space8),
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: _availablePersonalSubjects(vm).map((String code) {
                  return _SelectableChip(
                    key: ValueKey<String>('study-profile-subject-$code'),
                    label: SubjectCatalog.nameFor(code),
                    selected: vm.draftSubjectCode == code,
                    onTap: () {
                      vm.setDraftSubjectCode(code);
                      if (_customTaskController.text.trim().isEmpty) {
                        final String autoTitle =
                            'Tự học ${SubjectCatalog.nameFor(code)}';
                        _customTaskController.text = autoTitle;
                        vm.setCustomTaskTitle(autoTitle);
                      }
                    },
                  );
                }).toList(growable: false),
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
              Text(
                '2. Thời lượng & Chế độ đếm',
                style: mc.sectionTitleStyle,
              ),
              SizedBox(height: mc.space8),
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: StudyTimingMode.values.map((StudyTimingMode mode) {
                  final String keyName = mode == StudyTimingMode.candleCountup
                      ? 'study-timing-candle'
                      : 'study-timing-countdown';
                  return _SelectableChip(
                    key: ValueKey<String>(keyName),
                    label: mode.labelVi,
                    selected: vm.draftTimingMode == mode,
                    onTap: () => vm.setTimingMode(mode),
                  );
                }).toList(growable: false),
              ),
              SizedBox(height: mc.space8),
              Text(
                vm.draftTimingMode.shortBehaviorVi,
                style: mc.captionStyle,
              ),
              if (!vm.isDraftCandleCountup) ...<Widget>[
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
                      label:
                          'Thời lượng đang chọn ${vm.draftDurationMinutes} phút',
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
              ] else ...<Widget>[
                SizedBox(height: mc.space12),
                const MindClockNoticeBanner(
                  key: ValueKey<String>('study-candle-mode-info'),
                  message:
                      'Đồng hồ đốt nến đếm từ 00:00 không bị giới hạn 120 phút. Sau 120 phút liên tục app chỉ nhắc nhẹ nghỉ mắt; bấm Kết thúc/Hoàn tất bất kỳ lúc nào.',
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
              SizedBox(height: mc.space12),
              Text('Nhịp phiên học', style: mc.bodyStrongStyle),
              SizedBox(height: mc.space8),
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: StudyCadence.values.map((StudyCadence cadence) {
                  final String keyName = cadence == StudyCadence.deepSilent
                      ? 'study-cadence-deep'
                      : 'study-cadence-interval';
                  return _SelectableChip(
                    key: ValueKey<String>(keyName),
                    label: cadence.labelVi,
                    selected: vm.draftCadence == cadence,
                    onTap: () {
                      if (cadence == StudyCadence.deepSilent &&
                          _ambientAudioPlaying) {
                        _mediaPicker.stopAudioPreview();
                        setState(() {
                          _ambientAudioPlaying = false;
                          _ambientAudioStatusVi =
                              'Đã dừng nhạc nền khi chuyển sang Học sâu (im lặng).';
                        });
                      }
                      vm.setCadence(cadence);
                    },
                  );
                }).toList(growable: false),
              ),
              SizedBox(height: mc.space4),
              Text(vm.draftCadence.shortBehaviorVi, style: mc.captionStyle),
              SizedBox(height: mc.space12),
              _ToggleRow(
                key: const ValueKey<String>('study-toggle-sound'),
                label: vm.isDeepSilentDraft
                    ? 'Âm báo hết giờ (tắt cố định khi Học sâu)'
                    : 'Âm báo nhẹ khi hết giờ',
                value: vm.draftEndSoundEnabled,
                onToggle: () => vm.setEndSoundEnabled(!vm.draftEndSoundEnabled),
              ),
              SizedBox(height: mc.space8),
              _ToggleRow(
                key: const ValueKey<String>('study-toggle-outside-notify'),
                label: vm.isDeepSilentDraft
                    ? 'Nhắc ngoài app (tắt cố định khi Học sâu)'
                    : 'Nhắc 1 lần khi rời app quá 30 giây (Tập trung thường)',
                value: vm.draftNotifyOutsideApp,
                onToggle: () =>
                    vm.setNotifyOutsideApp(!vm.draftNotifyOutsideApp),
              ),
              SizedBox(height: mc.space8),
              _ToggleRow(
                key: const ValueKey<String>('study-toggle-reduce-motion'),
                label: 'Chế độ số tĩnh (Giảm chuyển động / Reduce Motion)',
                value: reduceMotion,
                onToggle: () =>
                    vm.setReduceMotionStaticMode(!vm.reduceMotionStaticMode),
              ),
            ],
          ),
        ),
        if (vm.draftRoomMode == StudyRoomMode.withAi) ...<Widget>[
          SizedBox(height: mc.space16),
          _buildPersonalizedPracticeCard(context, mc, vm),
          if (!vm.isDeepSilentDraft) ...<Widget>[
            SizedBox(height: mc.space16),
            _buildGeminiLiveOptInCard(context, mc, vm),
          ],
        ],
        SizedBox(height: mc.space16),
        _buildAmbientAudioCard(mc, lockedByDeepSilent: vm.isDeepSilentDraft),
        SizedBox(height: mc.space16),
        _buildDigitalWellbeingCard(context, mc, vm),
        SizedBox(height: mc.space16),
        MindClockNoticeBanner(
          key: const ValueKey<String>('study-prestart-review'),
          message:
              'Xem lại: ${vm.draftRoomMode.labelVi} · ${vm.draftDurationMinutes} phút · ${vm.draftCadence.labelVi} · Cam & mic tắt mặc định.',
          isWarm: false,
        ),
        SizedBox(height: mc.space8),
        MindClockNoticeBanner(
          message: vm.draftRoomMode == StudyRoomMode.solo
              ? 'Chế độ Học một mình: màn học chỉ hiện đồng hồ, mục tiêu và ghi chú; không khởi tạo AI.'
              : 'Camera và micro luôn tắt ở màn này. Khi đăng nhập và bấm gửi, MindClock AI gợi mở từng bước theo môn/lớp đã chọn.',
          isWarm: false,
        ),
        SizedBox(height: mc.space16),
        _buildStartOrScheduleSection(
          context: context,
          mc: mc,
          vm: vm,
          scheduleTitle: _customTaskController.text.trim().isNotEmpty
              ? _customTaskController.text.trim()
              : (vm.draftTaskTitle.trim().isNotEmpty
                  ? vm.draftTaskTitle.trim()
                  : 'Học tự do'),
          subjectCode: vm.draftSubjectCode ?? _availablePersonalSubjects(vm).first,
          durationMinutes: vm.draftDurationMinutes,
          startNowButton: MindClockButton(
            key: const ValueKey<String>('study-start-button'),
            label: AppStrings.studyStartCta,
            icon: MindClockIconKind.play,
            onPressed: () {
              vm.startSession(overrideTaskTitle: _customTaskController.text);
            },
          ),
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
    final bool isCandle = snapshot.isCandleCountup;
    final int displaySec = snapshot.displayClockSecondsAt(now);
    final int wallSec = snapshot.elapsedWallSecondsAt(now);
    final int inAppSec = snapshot.inAppFocusSecondsAt(now);
    final bool showRestHint = snapshot.isLongSessionRestHintAt(now);

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
            color: mc.surface,
            borderRadius: BorderRadius.circular(mc.radiusCard),
            border: Border.all(color: mc.outline),
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
                  MindClockStatusPill(
                    label: snapshot.roomMode.labelVi,
                    accentWarm: false,
                  ),
                  if (snapshot.cadence == StudyCadence.deepSilent)
                    const MindClockStatusPill(
                      key: ValueKey<String>('study-deep-silent-pill'),
                      label: 'Học sâu im lặng',
                      accentWarm: false,
                    ),
                  if (subjectName != null)
                    MindClockStatusPill(label: subjectName),
                  MindClockStatusPill(
                    label: isCandle ? 'Đốt nến tự do' : 'Đếm ngược',
                    accentWarm: isCandle,
                  ),
                  MindClockStatusPill(
                    key: const ValueKey<String>('study-remote-session-pill'),
                    label: snapshot.remoteSessionSynced
                        ? 'Đã lưu tiến độ'
                        : 'Tự học trên máy',
                    accentWarm: !snapshot.remoteSessionSynced,
                  ),
                ],
              ),
              SizedBox(height: mc.space12),
              Text(
                'Bạn đang học: ${snapshot.taskTitle}',
                key: const ValueKey<String>('study-active-task-title'),
                style: mc.sectionTitleStyle.copyWith(color: mc.ink),
              ),
              SizedBox(height: mc.space16),
              Center(
                child: Column(
                  children: <Widget>[
                    if (isCandle)
                      Padding(
                        padding: EdgeInsets.only(bottom: mc.space12),
                        child: StudyCandleTimer(
                          elapsedSeconds: displaySec,
                          isRunning:
                              snapshot.status == StudyFocusStatus.running &&
                                  !snapshot.commitmentAwaitingResume,
                          reduceMotion: reduceMotion,
                          animate: vm.enablePeriodicTicker,
                        ),
                      )
                    else if (!reduceMotion)
                      Padding(
                        padding: EdgeInsets.only(bottom: mc.space12),
                        child: CustomPaint(
                          key: const ValueKey<String>('study-progress-ring'),
                          size: const Size.square(112),
                          painter: _ThinProgressRingPainter(
                            progress: vm.progressFraction,
                            trackColor: mc.primarySoft,
                            fillColor: mc.primary,
                          ),
                        ),
                      ),
                    Semantics(
                      label: isCandle
                          ? 'Thời gian đã học ${formatDurationClock(displaySec)}'
                          : 'Thời gian còn lại ${formatDurationClock(displaySec)}',
                      child: Text(
                        formatDurationClock(displaySec),
                        key: const ValueKey<String>('study-timer-clock'),
                        style: mc.alarmHeroStyle.copyWith(color: mc.ink),
                      ),
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      reduceMotion
                          ? 'Chế độ số tĩnh đang bật (Reduce Motion).'
                          : isCandle
                              ? 'Đếm giờ tự do theo mốc thiết bị (không giới hạn 120p).'
                              : 'Đếm ngược theo mốc thời gian thiết bị.',
                      style: mc.captionStyle.copyWith(color: mc.inkMuted),
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
                    style: mc.captionStyle.copyWith(
                      color: mc.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Trong app: ${formatDurationClock(inAppSec)}',
                    key: const ValueKey<String>('study-inapp-seconds'),
                    style: mc.captionStyle.copyWith(color: mc.inkMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showRestHint) ...<Widget>[
          SizedBox(height: mc.space12),
          const MindClockNoticeBanner(
            key: ValueKey<String>('study-long-session-rest-banner'),
            message:
                'Bạn đã học vượt 120 phút liên tục. Đừng quên đứng dậy uống nước và thư giãn mắt 5 phút nhé.',
          ),
        ],
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
          label: isCandle
              ? 'Hoàn tất đốt nến & kết thúc'
              : AppStrings.studyFinishCta,
          icon: MindClockIconKind.stop,
          variant: MindClockButtonVariant.subtle,
          onPressed: () {
            final bool early = !isCandle && vm.remainingSeconds > 0;
            vm.finishSession(early: early);
          },
        ),
        if (snapshot.roomMode == StudyRoomMode.solo) ...<Widget>[
          SizedBox(height: mc.space16),
          MindClockCard(
            key: const ValueKey<String>('study-solo-stuck-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Ghi chú chỗ vướng mắc', style: mc.sectionTitleStyle),
                SizedBox(height: mc.space8),
                TextField(
                  key: const ValueKey<String>('study-solo-stuck-note-input'),
                  controller: _stuckController,
                  onChanged: (String text) =>
                      vm.updateReflectionNotes(stuck: text),
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Ý cần tra cứu hoặc xem lại sau phiên',
                    hintText: 'Ví dụ: Xem lại điều kiện xác định của hàm logarit...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(mc.radiusControl),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (snapshot.roomMode == StudyRoomMode.withAi) ...<Widget>[
          SizedBox(height: mc.space16),
          _buildAiHelpCard(context, mc, vm, snapshot),
          SizedBox(height: mc.space16),
          _buildMicroCheckCard(context, mc, vm),
        ],
        SizedBox(height: mc.space16),
        _buildAmbientAudioCard(
          mc,
          lockedByDeepSilent: snapshot.cadence == StudyCadence.deepSilent,
        ),
        SizedBox(height: mc.space16),
        _buildDigitalWellbeingCard(context, mc, vm),
      ],
    );
  }

  Widget _buildMicroCheckCard(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
  ) {
    final Map<String, dynamic> check =
        _microChecks[_microCheckIndex % _microChecks.length];
    final List<String> opts =
        (check['options'] as List<dynamic>).cast<String>();
    final int correctIdx = check['correctIndex'] as int;

    return MindClockCard(
      key: const ValueKey<String>('study-microcheck-card'),
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
                'Micro-Check 60 giây · Tỉnh táo khi học',
                style: mc.sectionTitleStyle,
              ),
              MindClockButton(
                key: const ValueKey<String>('study-microcheck-toggle'),
                label: _microCheckExpanded ? 'Thu gọn' : 'Kiểm tra nhanh',
                icon: MindClockIconKind.sunrise,
                variant: MindClockButtonVariant.secondary,
                expand: false,
                onPressed: () =>
                    setState(() => _microCheckExpanded = !_microCheckExpanded),
              ),
            ],
          ),
          SizedBox(height: mc.space4),
          Text(
            '1 câu 1 chạm giữ đầu óc tỉnh táo (không phạt EXP hay mất chuỗi khi chọn nhầm).',
            style: mc.captionStyle,
          ),
          if (_microCheckExpanded) ...<Widget>[
            SizedBox(height: mc.space12),
            Text(
              check['prompt'] as String,
              key: const ValueKey<String>('study-microcheck-prompt'),
              style: mc.bodyStrongStyle,
            ),
            SizedBox(height: mc.space8),
            for (int i = 0; i < opts.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: mc.space4),
                child: MindClockButton(
                  key: ValueKey<String>('study-microcheck-opt-$i'),
                  label: '${<String>['A', 'B', 'C'][i]}. ${opts[i]}',
                  variant: _microCheckPickedIndex == i
                      ? MindClockButtonVariant.primary
                      : MindClockButtonVariant.subtle,
                  onPressed: () => setState(() => _microCheckPickedIndex = i),
                ),
              ),
            if (_microCheckPickedIndex != null) ...<Widget>[
              SizedBox(height: mc.space8),
              MindClockNoticeBanner(
                key: const ValueKey<String>('study-microcheck-feedback'),
                message: _microCheckPickedIndex == correctIdx
                    ? 'Chuẩn xác — giữ nhịp tập trung rất tốt!'
                    : 'Chưa đúng rồi — đáp án chuẩn là "${opts[correctIdx]}". Hít sâu 5 giây rồi tiếp tục nhé!',
                isWarm: _microCheckPickedIndex != correctIdx,
              ),
            ],
            SizedBox(height: mc.space8),
            MindClockButton(
              key: const ValueKey<String>('study-microcheck-next'),
              label: 'Đổi câu Micro-Check khác',
              icon: MindClockIconKind.book,
              variant: MindClockButtonVariant.subtle,
              expand: false,
              onPressed: () => setState(() {
                _microCheckIndex = (_microCheckIndex + 1) % _microChecks.length;
                _microCheckPickedIndex = null;
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiHelpCard(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
    StudyFocusSessionSnapshot snapshot,
  ) {
    final bool isLoading = vm.aiStatus == StudyAiRequestStatus.loading;
    final bool hasRetryableError =
        vm.aiStatus == StudyAiRequestStatus.timeout ||
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
              Text(
                snapshot.cadence == StudyCadence.deepSilent
                    ? 'MindClock AI (chỉ trả chữ khi hỏi)'
                    : 'MindClock AI đồng hành',
                key: const ValueKey<String>('study-ai-companion-label'),
                style: mc.sectionTitleStyle,
              ),
              MindClockStatusPill(
                key: const ValueKey<String>('study-ai-status-pill'),
                label: !vm.hasAiGateway
                    ? 'Chưa khả dụng'
                    : (vm.isAuthenticated ? 'Sẵn sàng' : 'Cần đăng nhập'),
                accentWarm: !vm.hasAiGateway || !vm.isAuthenticated,
              ),
            ],
          ),
          SizedBox(height: mc.space8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(mc.space12),
            decoration: BoxDecoration(
              color: mc.paper,
              image: const DecorationImage(
                  image: AssetImage('assets/companions/study-corner.webp'),
                  fit: BoxFit.cover),
              borderRadius: BorderRadius.circular(mc.radiusControl),
            ),
            child: Column(
              children: <Widget>[
                MindClockAiAnimatedAvatar(
                  size: 160,
                  animate: vm.enablePeriodicTicker &&
                      !vm.isDeepSilentDraft &&
                      vm.activeSnapshot?.cadence != StudyCadence.deepSilent,
                  isThinking:
                      (isLoading || _speech.isBusy) && !_speech.isSpeaking,
                  isSpeaking: _speech.isSpeaking,
                  onLightBackground: true,
                  mood: vm.aiTurns.isEmpty
                      ? AiCompanionMood.neutral
                      : AiCompanionMood.encouraging,
                  statusLabelVi: _speech.isSpeaking
                      ? 'Đang đọc câu trả lời'
                      : isLoading
                          ? 'Đang gợi mở...'
                          : _speech.isBusy
                              ? 'Đang tạo giọng AI...'
                              : 'Sẵn sàng nhận câu hỏi của bạn',
                ),
                SizedBox(height: mc.space8),
                Text(
                  'MindClock AI gợi mở từng bước theo môn và lớp bạn chọn · Không giải hộ và không quan sát người học.',
                  textAlign: TextAlign.center,
                  style: mc.captionStyle.copyWith(color: mc.ink),
                ),
              ],
            ),
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
                      if (isAssistant &&
                          !turn.isOfflineFallback &&
                          turn.safetyStatus == 'safe' &&
                          snapshot.cadence != StudyCadence.deepSilent &&
                          snapshot.status == StudyFocusStatus.running &&
                          vm.isAuthenticated) ...<Widget>[
                        SizedBox(height: mc.space8),
                        MindClockButton(
                          key: ValueKey<String>('study-ai-read-${e.key}'),
                          label: _speech.isBusy
                              ? 'Dừng giọng đọc'
                              : (vm.hasCloudVoice
                                  ? 'Nghe giọng AI'
                                  : 'Nghe câu trả lời'),
                          icon: _speech.isBusy
                              ? MindClockIconKind.stop
                              : MindClockIconKind.volumeOn,
                          variant: MindClockButtonVariant.secondary,
                          onPressed: () => _readAiReply(vm, turn),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
          if (_speech.errorVi != null) ...<Widget>[
            SizedBox(height: mc.space8),
            MindClockNoticeBanner(
                key: const ValueKey<String>('study-ai-speech-error'),
                message: _speech.errorVi!,
                isWarm: true),
          ],
          if (isLoading) ...<Widget>[
            SizedBox(height: mc.space8),
            const MindClockNoticeBanner(
              key: ValueKey<String>('study-ai-loading-banner'),
              message: 'MindClock AI đang phân tích và chuẩn bị gợi ý...',
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
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space4,
            children: <Widget>[
              FilterChip(
                key: const ValueKey<String>('study-ai-socratic-lock-toggle'),
                label: Text(
                  _socraticStepLockEnabled
                      ? 'Khóa giải hộ Socratic: Đang bật'
                      : 'Khóa giải hộ Socratic: Tắt',
                ),
                selected: _socraticStepLockEnabled,
                selectedColor: mc.primarySoft,
                onSelected: (bool next) => setState(() {
                  _socraticStepLockEnabled = next;
                  _socraticLockWarningVi = null;
                }),
              ),
              ActionChip(
                key: const ValueKey<String>('study-ai-tried-chip'),
                label: const Text('Điền nhanh: Đã thử viết công thức'),
                onPressed: () => setState(() {
                  _aiTriedStepController.text =
                      'Mình đã tóm tắt giả thiết và viết công thức gốc.';
                  _socraticLockWarningVi = null;
                }),
              ),
            ],
          ),
          SizedBox(height: mc.space8),
          TextField(
            key: const ValueKey<String>('study-ai-tried-step-input'),
            controller: _aiTriedStepController,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Bước bạn đã tự thử (khóa giải hộ)',
              hintText: 'Ví dụ: Mình đã đặt x = ... hoặc tách được nhân tử...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(mc.radiusControl),
              ),
            ),
          ),
          if (_socraticLockWarningVi != null) ...<Widget>[
            SizedBox(height: mc.space8),
            MindClockNoticeBanner(
              key: const ValueKey<String>('study-ai-socratic-warning'),
              message: _socraticLockWarningVi!,
              isWarm: true,
            ),
          ],
          SizedBox(height: mc.space8),
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
          if (snapshot.status == StudyFocusStatus.running) ...<Widget>[
            SizedBox(height: mc.space8),
            Wrap(
              spacing: mc.space8,
              runSpacing: mc.space8,
              children: <Widget>[
                MindClockButton(
                  key: const ValueKey<String>('study-ai-photo-consent-btn'),
                  label: _attachedQuestionPhotoName != null
                      ? 'Đổi ảnh ($_attachedQuestionPhotoName)'
                      : 'Gửi ảnh đề bài',
                  icon: MindClockIconKind.book,
                  variant: MindClockButtonVariant.secondary,
                  expand: false,
                  onPressed: isLoading
                      ? null
                      : () => _attachQuestionPhotoWithConsent(vm),
                ),
                if (_attachedQuestionPhotoName != null)
                  MindClockButton(
                    key: const ValueKey<String>('study-ai-photo-clear-btn'),
                    label: 'Bỏ ảnh',
                    variant: MindClockButtonVariant.subtle,
                    expand: false,
                    onPressed: () => setState(() {
                      _attachedQuestionPhotoName = null;
                      _photoInputMessageVi = null;
                    }),
                  ),
                if (snapshot.cadence != StudyCadence.deepSilent &&
                    vm.isAuthenticated)
                  MindClockButton(
                    key: const ValueKey<String>('study-ai-voice-input'),
                    label: _voiceInputPending
                        ? 'Đang nhập bằng giọng nói...'
                        : 'Nói câu hỏi',
                    icon: MindClockIconKind.microphone,
                    variant: MindClockButtonVariant.secondary,
                    expand: false,
                    onPressed: _voiceInputPending || isLoading
                        ? null
                        : () => _askByVoice(vm),
                  ),
              ],
            ),
            if (_photoInputMessageVi != null) ...<Widget>[
              SizedBox(height: mc.space4),
              Text(
                _photoInputMessageVi!,
                key: const ValueKey<String>('study-ai-photo-status'),
                style: mc.captionStyle,
              ),
            ],
            if (_voiceInputMessage != null) ...<Widget>[
              SizedBox(height: mc.space4),
              Text(_voiceInputMessage!, style: mc.captionStyle),
            ],
          ],
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

    final int estimatedXp = (finishedGoal && inAppSec >= 300)
        ? ((inAppSec ~/ 300) > 12 ? 12 : (inAppSec ~/ 300))
        : 0;
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
          Text('Việc đã chọn: ${snapshot.taskTitle}',
              style: mc.bodyStrongStyle),
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
            estimatedXp > 0
                ? 'EXP dự kiến (study-time-v0.1): $estimatedXp XP · sẽ xác nhận từ máy chủ sau khi lưu và đồng bộ (tối đa 12 XP/phiên, 30 XP/ngày).'
                : 'EXP học tập: 0 XP (chỉ tính phiên hoàn thành từ 5 phút tập trung trở lên).',
            key: const ValueKey<String>('study-summary-xp'),
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

  List<String> _availablePersonalSubjects(StudyFocusViewModel vm) {
    final List<String> profileSubjects =
        widget.guestViewModel.profile.selectedSubjectCodes;
    if (profileSubjects.isNotEmpty) return profileSubjects;
    if (vm.draftSubjectCode != null && vm.draftSubjectCode!.isNotEmpty) {
      return <String>[vm.draftSubjectCode!];
    }
    return const <String>['math', 'literature', 'english'];
  }

  Widget _buildPersonalizedPracticeCard(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
  ) {
    final List<String> subjects = _availablePersonalSubjects(vm);
    final String effectiveSubject = (_selectedPersonalizedSubject != null &&
            subjects.contains(_selectedPersonalizedSubject))
        ? _selectedPersonalizedSubject!
        : subjects.first;
    final String gradeLabel =
        widget.guestViewModel.profile.gradeLevel ?? 'Lớp 11';
    final bool isLoading =
        vm.personalizedStatus == StudyAiRequestStatus.loading;
    final PersonalizedPracticeQuestion? question = vm.personalizedQuestion;

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
              Text(
                'Tạo câu luyện (tùy chọn)',
                style: mc.sectionTitleStyle,
              ),
              MindClockStatusPill(
                label: gradeLabel,
                accentWarm: false,
              ),
            ],
          ),
          SizedBox(height: mc.space8),
          Text(
            'Tạo một câu luyện vừa sức theo $gradeLabel và môn trong hồ sơ khi bạn muốn khởi động trước phiên học.',
            style: mc.captionStyle,
          ),
          SizedBox(height: mc.space12),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: subjects.map((String code) {
              return _SelectableChip(
                key: ValueKey<String>('study-personalized-subject-$code'),
                label: SubjectCatalog.nameFor(code),
                selected: code == effectiveSubject,
                onTap: () =>
                    setState(() => _selectedPersonalizedSubject = code),
              );
            }).toList(growable: false),
          ),
          SizedBox(height: mc.space12),
          TextField(
            key: const ValueKey<String>('study-personalized-topic-input'),
            controller: _personalizedTopicController,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Chủ đề muốn ôn (tùy chọn)',
              hintText:
                  'Ví dụ: Phương trình bậc nhất, Thì hiện tại hoàn thành...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(mc.radiusControl),
              ),
            ),
          ),
          if (vm.personalizedErrorVi != null) ...<Widget>[
            SizedBox(height: mc.space8),
            MindClockNoticeBanner(
              key: const ValueKey<String>('study-personalized-error-banner'),
              message: vm.personalizedErrorVi!,
              isWarm: true,
            ),
          ],
          if (question != null) ...<Widget>[
            SizedBox(height: mc.space12),
            Container(
              key: const ValueKey<String>('study-personalized-result-card'),
              width: double.infinity,
              padding: EdgeInsets.all(mc.space12),
              decoration: BoxDecoration(
                color: mc.primarySoft,
                borderRadius: BorderRadius.circular(mc.radiusChip),
                border: Border.all(color: mc.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${SubjectCatalog.nameFor(effectiveSubject)} · ${question.gradeBand}',
                    style: mc.chipLabelStyle,
                  ),
                  SizedBox(height: mc.space4),
                  MathFormulaText(question.prompt, style: mc.bodyStrongStyle),
                  if (question.reasoningPromptVi.isNotEmpty) ...<Widget>[
                    SizedBox(height: mc.space4),
                    Text(question.reasoningPromptVi, style: mc.captionStyle),
                  ],
                  if (question.hintVi != null &&
                      question.hintVi!.isNotEmpty) ...<Widget>[
                    SizedBox(height: mc.space4),
                    Text('Gợi ý: ${question.hintVi!}', style: mc.captionStyle),
                  ],
                  SizedBox(height: mc.space4),
                  Text(
                    'Câu luyện tự do trong phiên học',
                    style: mc.captionStyle,
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('study-personalized-generate-button'),
            label: isLoading ? 'Đang tạo câu luyện...' : 'Tạo câu luyện',
            icon: MindClockIconKind.book,
            variant: MindClockButtonVariant.secondary,
            onPressed: isLoading
                ? null
                : () => vm.generatePersonalizedQuestion(
                      subjectCode: effectiveSubject,
                      gradeLevel: gradeLabel,
                      topicHint: _personalizedTopicController.text,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeminiLiveOptInCard(
    BuildContext context,
    MindClockTheme mc,
    StudyFocusViewModel vm,
  ) {
    final List<String> subjects = _availablePersonalSubjects(vm);
    final String activeSubject =
        vm.draftSubjectCode ?? _selectedPersonalizedSubject ?? subjects.first;
    final String gradeLabel =
        widget.guestViewModel.profile.gradeLevel ?? 'Lớp 11';
    final bool isLoading = vm.liveTokenStatus == StudyAiRequestStatus.loading;
    final GeminiLiveSessionToken? token = vm.liveToken;

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
              Text(
                'Gemini Live thoại (tùy chọn)',
                style: mc.sectionTitleStyle,
              ),
              MindClockStatusPill(
                label: vm.liveConsentGranted ? 'Đã đồng ý' : 'Đang tắt',
                accentWarm: !vm.liveConsentGranted,
              ),
            ],
          ),
          SizedBox(height: mc.space8),
          Text(
            'Chỉ mở phiên thoại khi bạn chủ động đồng ý. Không lưu âm thanh nền khi dừng phiên.',
            style: mc.captionStyle,
          ),
          SizedBox(height: mc.space12),
          _ToggleRow(
            key: const ValueKey<String>('study-live-consent-toggle'),
            label: 'Đồng ý bật trợ lý giọng nói Gemini Live cho phiên này',
            value: vm.liveConsentGranted,
            onToggle: () => vm.setLiveConsentGranted(!vm.liveConsentGranted),
          ),
          if (vm.liveTokenErrorVi != null) ...<Widget>[
            SizedBox(height: mc.space8),
            MindClockNoticeBanner(
              key: const ValueKey<String>('study-live-error-banner'),
              message: vm.liveTokenErrorVi!,
              isWarm: true,
            ),
          ],
          if (token != null) ...<Widget>[
            SizedBox(height: mc.space12),
            Container(
              key: const ValueKey<String>('study-live-token-card'),
              width: double.infinity,
              padding: EdgeInsets.all(mc.space12),
              decoration: BoxDecoration(
                color: mc.primarySoft,
                borderRadius: BorderRadius.circular(mc.radiusChip),
                border: Border.all(color: mc.outline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    token.isMock
                        ? 'Đã mở phiên thoại thử nghiệm'
                        : 'Đã mở phiên thoại trực tiếp',
                    style: mc.bodyStrongStyle,
                  ),
                  SizedBox(height: mc.space4),
                  Text(
                    'Ngữ cảnh: ${token.contextSummary} · Hiệu lực ${token.expiresInSeconds} giây',
                    style: mc.captionStyle,
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('study-live-token-button'),
            label: isLoading
                ? 'Đang cấp token Gemini Live...'
                : 'Xin phiên Gemini Live',
            icon: MindClockIconKind.play,
            variant: MindClockButtonVariant.secondary,
            onPressed: (!vm.liveConsentGranted || isLoading)
                ? null
                : () => vm.requestGeminiLiveToken(
                      subjectCode: activeSubject,
                      gradeLevel: gradeLabel,
                      taskTitle: _customTaskController.text,
                    ),
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
                      '${item.roomMode.labelVi} · ${item.level.labelVi} · Thực tế ${formatDurationClock(item.elapsedWallSeconds)} · '
                      'Trong app ${formatDurationClock(item.inAppFocusSeconds)} · '
                      '${item.remoteFinishSynced ? 'EXP xác nhận: ${item.confirmedXpAwarded ?? 0} XP' : 'EXP dự kiến: ${item.estimatedStudyXp} XP'}',
                      style: mc.captionStyle,
                    ),
                    SizedBox(height: mc.space4),
                    Text(
                      item.remoteFinishSynced
                          ? 'Đã lưu an toàn lên tài khoản'
                          : (item.remoteSyncErrorVi ??
                              'Đã lưu trên máy (sẽ tự động đồng bộ khi có mạng)'),
                      key: ValueKey<String>(
                          'study-history-sync-${item.sessionId}'),
                      style: mc.captionStyle.copyWith(
                        color:
                            item.remoteFinishSynced ? mc.primary : mc.inkMuted,
                      ),
                    ),
                    if (!item.remoteFinishSynced &&
                        vm.isAuthenticated &&
                        vm.hasAiGateway) ...<Widget>[
                      SizedBox(height: mc.space8),
                      MindClockButton(
                        key: ValueKey<String>(
                            'study-history-retry-${item.sessionId}'),
                        label: 'Đồng bộ lại',
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
