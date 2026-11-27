import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/data/debug/debug_fixture_study_ai_gateway.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/models/study_ai_models.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/media_picker_gateway.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/today_screen.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/mindclock_ai_avatar.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

class _TrackingStudyAiGateway extends DebugFixtureStudyAiGateway {
  int personalizedCalls = 0;
  int helpCalls = 0;
  String? lastTaskTitle;
  String? lastSubjectCode;
  String? lastGradeLevel;
  String? lastQuestionText;

  @override
  bool get isDebugFixture => false;

  @override
  Future<StudyHelpResponse> requestHelp({
    required String sessionId,
    required String taskTitle,
    String? subjectCode,
    String? gradeLevel,
    required String questionText,
    required List<StudyHelpTurn> recentTurns,
    required String idempotencyKey,
  }) async {
    helpCalls += 1;
    lastTaskTitle = taskTitle;
    lastSubjectCode = subjectCode;
    lastGradeLevel = gradeLevel;
    lastQuestionText = questionText;
    return const StudyHelpResponse(
      messageVi: 'Hãy viết điều kiện xác định của biểu thức dưới dấu căn trước.',
      nextQuestionVi: 'Biểu thức trong căn cần lớn hơn hoặc bằng mấy?',
      helpLevel: 'socratic',
      safetyStatus: 'safe',
    );
  }

  @override
  Future<PersonalizedPracticeQuestion> generatePersonalizedQuestion({
    required String subjectCode,
    String? gradeLevel,
    String? topicHint,
    int difficulty = 1,
    required String idempotencyKey,
  }) {
    personalizedCalls += 1;
    return super.generatePersonalizedQuestion(
      subjectCode: subjectCode,
      gradeLevel: gradeLevel,
      topicHint: topicHint,
      difficulty: difficulty,
      idempotencyKey: idempotencyKey,
    );
  }
}

class _FakePhotoMediaPicker extends UnboundMediaPickerGateway {
  int pickPhotoCalls = 0;

  @override
  Future<MediaPickResult> pickAvatarImage() async {
    pickPhotoCalls += 1;
    return const MediaPickResult(
      picked: true,
      localPath: '/data/user/0/mindclock/de_toan_12.jpg',
      displayName: 'de_toan_12.jpg',
    );
  }
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final Finder finder = find.byKey(ValueKey<String>(key));
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.35);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'T093 TC-01 & TC-02: 3 lựa chọn rõ ràng, Hẹn giờ chỉ tạo lịch khi bấm xác nhận, Học một mình có ghi chú vướng mắc và không có AI',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();
      addTearDown(guestVm.dispose);

      final _TrackingStudyAiGateway aiGateway = _TrackingStudyAiGateway();
      final StudyFocusViewModel studyVm = StudyFocusViewModel(
        repository: LocalStudyFocusRepository(store: store),
        bridge: const UnboundStudyFocusBridge(),
        aiGateway: aiGateway,
        enablePeriodicTicker: false,
      );
      await studyVm.initialize(ownerScopeKey: 'user:t093');
      addTearDown(studyVm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: StudySpaceScreen(
            guestViewModel: guestVm,
            studyViewModel: studyVm,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // AC-01: Có đúng 3 lựa chọn rõ ràng và không tự tạo câu luyện khi mới mở
      expect(find.byKey(const ValueKey<String>('study-mode-solo')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('study-mode-ai')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('study-mode-friends')), findsOneWidget);
      expect(aiGateway.personalizedCalls, 0);

      // Chuyển sang Học một mình + kiểm tra Hẹn giờ tường minh (không tạo lịch ngầm)
      await _tapKey(tester, 'study-mode-solo');
      expect(guestVm.dailyTasks, isEmpty);
      await _tapKey(tester, 'study-timing-schedule-later');
      // Chỉ mới chọn chip Hẹn giờ -> tuyệt đối chưa tự tạo lịch ngầm
      expect(guestVm.dailyTasks, isEmpty);
      await _tapKey(tester, 'study-confirm-schedule-button');
      expect(guestVm.dailyTasks.length, 1);

      // Chuyển lại Bắt đầu ngay -> Vào phiên Học một mình
      await _tapKey(tester, 'study-timing-start-now');
      await _tapKey(tester, 'study-start-button');

      // AC-02: Màn phiên Học một mình chỉ có đồng hồ, mục tiêu, ghi chú vướng mắc, tạm dừng, kết thúc; không có AI
      expect(find.byKey(const ValueKey<String>('study-timer-clock')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('study-active-task-title')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('study-solo-stuck-note-input')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('study-pause-button')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('study-finish-button')), findsOneWidget);
      expect(find.byType(MindClockAiAnimatedAvatar), findsNothing);
      expect(find.byKey(const ValueKey<String>('study-ai-question-input')), findsNothing);
      expect(find.byKey(const ValueKey<String>('study-personalized-generate-button')), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey<String>('study-solo-stuck-note-input')),
        'Quên công thức tích phân từng phần',
      );
      await tester.pump();
      expect(
        studyVm.activeSnapshot?.notesStuck,
        'Quên công thức tích phân từng phần',
      );
    },
  );

  testWidgets(
    'T093 TC-03: Học cùng MindClock AI chỉ lọc môn trong hồ sơ, Tạo câu luyện chỉ có ở 1 nơi, phiên AI nhận môn/lớp/mục tiêu và hỏi bằng ảnh có consent',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();
      await guestVm.saveStudyProfile(
        const StudyProfile(
          gradeLevel: 'Lớp 12',
          selectedSubjectCodes: <String>['math', 'english'],
          goalLabel: 'Đạt 8.5+ THPT',
        ),
      );
      addTearDown(guestVm.dispose);

      final _TrackingStudyAiGateway aiGateway = _TrackingStudyAiGateway();
      final _FakePhotoMediaPicker photoPicker = _FakePhotoMediaPicker();
      final StudyFocusViewModel studyVm = StudyFocusViewModel(
        repository: LocalStudyFocusRepository(store: store),
        bridge: const UnboundStudyFocusBridge(),
        aiGateway: aiGateway,
        enablePeriodicTicker: false,
      );
      await studyVm.initialize(ownerScopeKey: 'user:t093_ai');
      await studyVm.setAccountAuthenticated(true, gradeLevel: 'Lớp 12');
      studyVm.setDraftSubjectCode('math');
      addTearDown(studyVm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: StudySpaceScreen(
            guestViewModel: guestVm,
            studyViewModel: studyVm,
            mediaPickerGateway: photoPicker,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Lọc đúng môn trong hồ sơ (Toán, Tiếng Anh), không hiện môn ngoài hồ sơ (Hóa học, Tin học)
      expect(find.byKey(const ValueKey<String>('study-personalized-subject-math')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('study-personalized-subject-english')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('study-personalized-subject-chemistry')), findsNothing);
      expect(find.byKey(const ValueKey<String>('study-personalized-subject-informatics')), findsNothing);
      expect(find.byKey(const ValueKey<String>('study-personalized-generate-button')), findsOneWidget);
      expect(aiGateway.personalizedCalls, 0);

      // Vào phiên Học cùng MindClock AI -> Tạo câu luyện không lặp lại trong phiên đang chạy
      await _tapKey(tester, 'study-start-button');
      expect(find.byKey(const ValueKey<String>('study-personalized-generate-button')), findsNothing);
      expect(find.byKey(const ValueKey<String>('study-ai-question-input')), findsOneWidget);
      expect(find.textContaining('Không giải hộ và không quan sát người học'), findsOneWidget);

      // Bấm Gửi ảnh đề bài -> Hủy consent không gọi picker; Đồng ý mới gọi picker
      await _tapKey(tester, 'study-ai-photo-consent-btn');
      await tester.tap(find.byKey(const ValueKey<String>('study-photo-consent-cancel')));
      await tester.pumpAndSettle();
      expect(photoPicker.pickPhotoCalls, 0);

      await _tapKey(tester, 'study-ai-photo-consent-btn');
      await tester.tap(find.byKey(const ValueKey<String>('study-photo-consent-accept')));
      await tester.pumpAndSettle();
      expect(photoPicker.pickPhotoCalls, 1);
      expect(find.textContaining('de_toan_12.jpg'), findsWidgets);

      await tester.enterText(
        find.byKey(const ValueKey<String>('study-ai-question-input')),
        'Mình chưa tìm được tập xác định.',
      );
      await _tapKey(tester, 'study-ai-send-button');

      expect(aiGateway.helpCalls, 1);
      expect(aiGateway.lastSubjectCode, 'math');
      expect(aiGateway.lastGradeLevel, 'Lớp 12');
      expect(aiGateway.lastTaskTitle, contains('Đạt 8.5+ THPT'));
      expect(aiGateway.lastQuestionText, contains('de_toan_12.jpg'));
      expect(studyVm.aiTurns.length, 2);
    },
  );

  testWidgets(
    'T093 TC-04: Học cùng bạn không hiển thị Học một mình bên dưới phòng bạn bè, mặc định tắt AI phòng, và TodayScreen chỉ có 1 điểm vào Không gian học',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 860);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();
      await guestVm.saveStudyProfile(
        const StudyProfile(
          gradeLevel: 'Lớp 12',
          selectedSubjectCodes: <String>['math'],
        ),
      );
      addTearDown(guestVm.dispose);

      final StudyFocusViewModel studyVm = StudyFocusViewModel(
        repository: LocalStudyFocusRepository(store: store),
        bridge: const UnboundStudyFocusBridge(),
        enablePeriodicTicker: false,
      );
      await studyVm.initialize(ownerScopeKey: 'user:t093_friends');
      addTearDown(studyVm.dispose);

      // Kiểm tra TodayScreen chỉ có duy nhất 1 điểm vào Không gian học (today-dir-study)
      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: TodayScreen(
              viewModel: guestVm,
              studyViewModel: studyVm,
              onCreateAlarm: () {},
              onEditAlarm: (_) {},
              onOpenTimetableAndProfile: () {},
              onOpenStudySpace: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('today-dir-study')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('today-open-study-space')), findsNothing);

      // Mở StudySpaceScreen -> chọn Học cùng bạn -> Tạo phòng mới
      final DebugFixtureCommunityRepository communityRepo =
          DebugFixtureCommunityRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: StudySpaceScreen(
            guestViewModel: guestVm,
            studyViewModel: studyVm,
            communityRepository: communityRepo,
            onClose: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _tapKey(tester, 'study-mode-friends');
      expect(find.byKey(const ValueKey<String>('study-friends-media-notice')), findsOneWidget);
      expect(find.text('1. Chọn việc học cụ thể'), findsNothing);
      expect(find.byKey(const ValueKey<String>('study-personalized-generate-button')), findsNothing);

      await _tapKey(tester, 'study-open-community-hub');
      await _tapKey(tester, 'community-create-room-toggle');
      expect(find.byKey(const ValueKey<String>('community-create-subject-math')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('community-create-subject-chemistry')), findsNothing);

      await tester.enterText(
        find.byKey(const ValueKey<String>('community-room-title-input')),
        'Nhóm Toán 12 tối nay',
      );
      await _tapKey(tester, 'community-create-room-submit');

      // Đã vào phòng bạn bè: tuyệt đối KHÔNG hiển thị khối Học một mình hoặc Tạo câu luyện bên dưới!
      expect(find.byKey(const ValueKey<String>('meet-study-room-panel')), findsOneWidget);
      expect(find.textContaining('chưa truyền cuộc gọi âm thanh/video'), findsOneWidget);
      expect(find.text('Mic chưa khả dụng'), findsOneWidget);
      expect(find.text('Camera chưa khả dụng'), findsOneWidget);
      expect(find.text('1. Chọn việc học cụ thể'), findsNothing);
      expect(find.byKey(const ValueKey<String>('study-start-button')), findsNothing);
      expect(find.byKey(const ValueKey<String>('study-personalized-generate-button')), findsNothing);
      // Mặc định phòng tạo mới không tự bật AI cho tới khi chủ phòng mời
      expect(find.byKey(const ValueKey<String>('meet-tile-mindclock-ai')), findsNothing);
    },
  );
}
