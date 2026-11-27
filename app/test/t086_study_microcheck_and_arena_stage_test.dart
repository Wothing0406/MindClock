import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_study_ai_gateway.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/arena/view_models/solo_arena_view_model.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_skill_hand.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_stage_widget.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

class _TestStudyBridge implements StudyFocusBridge {
  @override
  bool get isPlatformConnected => true;

  @override
  Future<void> cancelStudyReminder() async {}

  @override
  Future<StudyNotificationPermission> getNotificationPermissionStatus() async =>
      StudyNotificationPermission.granted;

  @override
  Future<DigitalWellbeingOpenResult> openDigitalWellbeingFocusSettings() async =>
      const DigitalWellbeingOpenResult(
        opened: false,
        target: DigitalWellbeingTarget.unavailable,
        messageVi: 'Không hỗ trợ',
      );

  @override
  Future<void> playSessionEndCue() async {}

  @override
  Future<StudyNotificationPermission> requestNotificationPermission() async =>
      StudyNotificationPermission.granted;

  @override
  Future<void> showSingleStudyReminder({
    required String sessionId,
    required String titleVi,
    required String bodyVi,
  }) async {}
}

void main() {
  testWidgets(
      'T086 StudySpaceScreen Micro-Check 60s & Khóa giải hộ Socratic hoạt động chuẩn ở 320dp 200%',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
    final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
      repository: GuestWorkspaceRepository(store: kv),
      alarmScheduler: const UnboundAlarmSchedulerService(),
    );
    await guestVm.initialize();

    final StudyFocusViewModel studyVm = StudyFocusViewModel(
      repository: LocalStudyFocusRepository(store: kv),
      bridge: _TestStudyBridge(),
      aiGateway: const DebugFixtureStudyAiGateway(),
      enablePeriodicTicker: false,
    );
    await studyVm.initialize();
    await studyVm.setAccountAuthenticated(true, gradeLevel: 'Lớp 11');
    await studyVm.startSession();

    await tester.pumpWidget(
      MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: StudySpaceScreen(
            guestViewModel: guestVm,
            studyViewModel: studyVm,
            onClose: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Kiểm tra Micro-Check 60s
    final Finder mcToggle =
        find.byKey(const ValueKey<String>('study-microcheck-toggle'));
    await tester.ensureVisible(mcToggle);
    await tester.tap(mcToggle);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('study-microcheck-prompt')),
      findsOneWidget,
    );
    final Finder opt0 =
        find.byKey(const ValueKey<String>('study-microcheck-opt-0'));
    await tester.ensureVisible(opt0);
    await tester.tap(opt0);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('study-microcheck-feedback')),
      findsOneWidget,
    );

    // 2. Bật Khóa giải hộ Socratic -> gửi rỗng bước tự thử bị chặn
    final Finder lockToggle =
        find.byKey(const ValueKey<String>('study-ai-socratic-lock-toggle'));
    await tester.ensureVisible(lockToggle);
    await tester.tap(lockToggle);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('study-ai-question-input')),
      'Giải giúp mình bài này',
    );
    final Finder sendBtn =
        find.byKey(const ValueKey<String>('study-ai-send-button'));
    await tester.ensureVisible(sendBtn);
    await tester.tap(sendBtn);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('study-ai-socratic-warning')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'T086 ArenaStageWidget & ArenaSkillHand hiển thị thanh cảnh báo tụ chiêu và dock thẻ chiến đấu',
      (WidgetTester tester) async {
    final SoloArenaViewModel vm = SoloArenaViewModel(enableRoundTimer: false);
    vm.startSoloMatch();

    await tester.pumpWidget(
      MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ArenaStageWidget(
                  playerState: vm.playerState,
                  botState: vm.botState.copyWith(qi: 2),
                  compact: false,
                  reduceMotion: true,
                  skipEffects: true,
                  soundEnabled: false,
                  assetFallbackMode: false,
                ),
                ArenaSkillHand(
                  champion: vm.playerState.championId,
                  options: vm.actionOptions,
                  onAction: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('arena-stage-expanded')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('arena-enemy-charge-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('arena-skill-hand-dock')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
