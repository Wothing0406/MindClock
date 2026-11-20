import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/domain/game/combat_catalog.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/arena/view_models/solo_arena_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/mindclock_shell_screen.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';

class _NoopCameraGateway implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    return const CameraCaptureOutcome(
      status: CameraCaptureStatus.unavailable,
      messageVi: 'E2E game không cần camera.',
    );
  }
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.45,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterVisibleText(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.35,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Kiểm thử Game Đấu trường G1 end-to-end trên Android Emulator thật.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Arena G1 Emulator E2E: Hub -> Setup & Modal chi tiết tướng -> Loading Game -> Battle công bằng -> Summary (0 RP) -> Replay',
    (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();
      await guestVm.completeOnboardingAsLater(alarmOnly: false);

      final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
        authGateway: DebugFixtureAuthGateway(),
        repository: DebugFixturePersonalFlowRepository(),
        draftStore: OfflineTextDraftStore(store: store),
        cameraGateway: _NoopCameraGateway(),
      );
      await personalVm.initialize();

      final SoloArenaViewModel arenaVm = SoloArenaViewModel(
        initialSeed: 20261119,
        enableRoundTimer: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MindClockShellScreen(
            viewModel: guestVm,
            personalViewModel: personalVm,
            arenaViewModel: arenaVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Vào tab Đấu trường -> Hub -> Setup
      await _tapVisible(
          tester, find.byKey(const ValueKey<String>('nav-arena')));
      expect(find.byKey(const ValueKey<String>('arena-hub-scroll')),
          findsOneWidget);
      await _tapVisible(
          tester, find.byKey(const ValueKey<String>('arena-enter-solo')));

      // 2. Mở modal xem nội tại/skill của Tuyệt Đỉnh rồi đóng lại
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('arena-champion-detail-tuyet_dinh')),
      );
      expect(
        find.byKey(
            const ValueKey<String>('arena-champion-detail-sheet-tuyet_dinh')),
        findsOneWidget,
      );
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('arena-champion-detail-close')),
      );

      // 2b. Chọn giới hạn 30s/lượt ở T062 trên Setup
      await _tapVisible(
        tester,
        find.byKey(const ValueKey<String>('arena-timer-30')),
      );
      expect(arenaVm.noTimeLimit, isFalse);
      expect(arenaVm.roundTimeLimitSeconds, 30);

      // 3. Bấm Bắt đầu Luyện đơn -> đi qua Loading Game (ArenaSection.loading) -> Battle
      final Finder startBtn =
          find.byKey(const ValueKey<String>('arena-start-solo-match'));
      await Scrollable.ensureVisible(
        tester.element(startBtn),
        alignment: 0.45,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await tester.tap(startBtn);
      await tester.pump();
      expect(arenaVm.section, ArenaSection.loading);
      expect(find.byKey(const ValueKey<String>('arena-loading-screen')),
          findsOneWidget);

      final Finder enterNowBtn =
          find.byKey(const ValueKey<String>('arena-enter-battle-now'));
      await tester.ensureVisible(enterNowBtn);
      await tester.pump();
      await tester.tap(enterNowBtn);
      await tester.pumpAndSettle();
      expect(arenaVm.section, ArenaSection.battle);
      expect(find.byKey(const ValueKey<String>('arena-stage-map-image')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('arena-round-countdown')), findsOneWidget);
      expect(find.text('Thời gian còn: 30s'), findsOneWidget);

      // 4. Kiểm tra uncertain không phạt HP
      await _enterVisibleText(
        tester,
        find.byKey(const ValueKey<String>('arena-answer-input')),
        '?',
      );
      await _enterVisibleText(
        tester,
        find.byKey(const ValueKey<String>('arena-reasoning-input')),
        'chua chac chan',
      );
      await _tapVisible(
          tester, find.byKey(const ValueKey<String>('arena-submit-answer')));
      expect(find.byKey(const ValueKey<String>('arena-grade-pill-uncertain')),
          findsOneWidget);
      await _tapVisible(
          tester, find.byKey(const ValueKey<String>('arena-uncertain-swap')));
      expect(arenaVm.playerState.hp, baseHp);

      // 5. Đánh các round tới Summary (0 RP)
      for (int guard = 0;
          guard < maxCombatRounds && arenaVm.section == ArenaSection.battle;
          guard++) {
        final q = arenaVm.currentQuestion!;
        await _enterVisibleText(
          tester,
          find.byKey(const ValueKey<String>('arena-answer-input')),
          q.acceptedAnswers.first,
        );
        await _enterVisibleText(
          tester,
          find.byKey(const ValueKey<String>('arena-reasoning-input')),
          '${q.reasoningKeywords.first} dung theo de bai',
        );
        await _tapVisible(
            tester, find.byKey(const ValueKey<String>('arena-submit-answer')));
        expect(find.byKey(const ValueKey<String>('arena-grade-pill-correct')),
            findsOneWidget);

        await _tapVisible(
            tester, find.byKey(const ValueKey<String>('arena-action-basic')));
        expect(find.byKey(const ValueKey<String>('arena-next-round')),
            findsOneWidget);

        await _tapVisible(
            tester, find.byKey(const ValueKey<String>('arena-next-round')));
      }

      expect(arenaVm.section, ArenaSection.summary);
      expect(find.byKey(const ValueKey<String>('arena-summary-scroll')),
          findsOneWidget);
      expect(find.textContaining('0 RP'), findsWidgets);

      // 6. Bấm Luyện lại -> kiểm tra lại Loading Game
      final Finder replayBtn =
          find.byKey(const ValueKey<String>('arena-replay-same-seed'));
      await Scrollable.ensureVisible(
        tester.element(replayBtn),
        alignment: 0.45,
        duration: Duration.zero,
      );
      await tester.pumpAndSettle();
      await tester.tap(replayBtn);
      await tester.pump();
      expect(arenaVm.section, ArenaSection.loading);
      await tester.pumpAndSettle();
      expect(arenaVm.section, ArenaSection.battle);
      expect(tester.takeException(), isNull);
    },
  );
}
