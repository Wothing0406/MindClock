import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
      messageVi: 'Chưa dùng camera',
    );
  }
}

Future<void> _scrollCenterAndTap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.5,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollAndEnterText(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.3,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

void main() {
  group('G1 Arena Solo Widget Flow (GAME-06)', () {
    testWidgets(
      'Đấu trường -> Luyện đơn -> chọn môn/tướng -> uncertain/incorrect/correct -> chọn chiêu -> tổng kết & Reduce Motion 320dp 200%',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

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

        final SoloArenaViewModel arenaVm = SoloArenaViewModel(initialSeed: 2026);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
            ),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: MindClockShellScreen(
                viewModel: guestVm,
                personalViewModel: personalVm,
                arenaViewModel: arenaVm,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Vào tab Đấu trường -> thấy 3 mode, không có Đấu hạng
        await tester.tap(find.byKey(const ValueKey<String>('nav-arena')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey<String>('arena-enter-solo')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('arena-enter-1v1-locked')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('arena-enter-2v2-locked')), findsOneWidget);
        expect(find.text('Đấu hạng'), findsNothing);

        // 2. Vào Thiết lập Luyện đơn -> chọn Toán, tướng Hàn Bối Pháp, bật fallback asset
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-enter-solo')),
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-subject-math')),
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-champion-han_boi_phap')),
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-toggle-asset-fallback')),
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-start-solo-match')),
        );

        // 3. Đang giải câu: sân ở chế độ compact, fallback asset hiển thị an toàn, không lộ rubric
        expect(find.byKey(const ValueKey<String>('arena-stage-compact')), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('arena-rubric-reveal-box')), findsNothing);
        expect(find.textContaining('Khung tĩnh dự phòng'), findsOneWidget);

        // 4. Nộp câu mơ hồ -> uncertain -> đổi câu không mất HP
        await _scrollAndEnterText(
          tester,
          find.byKey(const ValueKey<String>('arena-answer-input')),
          '?',
        );
        await _scrollAndEnterText(
          tester,
          find.byKey(const ValueKey<String>('arena-reasoning-input')),
          'chưa rõ hướng làm',
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-submit-answer')),
        );

        expect(
          find.byKey(const ValueKey<String>('arena-grade-pill-uncertain')),
          findsOneWidget,
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-uncertain-swap')),
        );
        expect(arenaVm.playerState.hp, maxHp);

        // 5. Nộp sai (thiếu bước giải) -> Chưa đúng + gợi ý 1 bước -> sửa lại
        await _scrollAndEnterText(
          tester,
          find.byKey(const ValueKey<String>('arena-answer-input')),
          '999',
        );
        await _scrollAndEnterText(
          tester,
          find.byKey(const ValueKey<String>('arena-reasoning-input')),
          '',
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-submit-answer')),
        );
        expect(
          find.byKey(const ValueKey<String>('arena-grade-pill-incorrect')),
          findsOneWidget,
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-incorrect-retry')),
        );

        // 6. Nộp đúng đáp án + bước trình bày -> Đúng rõ -> sân mở rộng & nút Chiêu 1/2 ghi lý do khóa
        final q = arenaVm.currentQuestion!;
        await _scrollAndEnterText(
          tester,
          find.byKey(const ValueKey<String>('arena-answer-input')),
          q.acceptedAnswers.first,
        );
        await _scrollAndEnterText(
          tester,
          find.byKey(const ValueKey<String>('arena-reasoning-input')),
          '${q.reasoningKeywords.first} = 10',
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-submit-answer')),
        );

        expect(
          find.byKey(const ValueKey<String>('arena-grade-pill-correct')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey<String>('arena-stage-expanded')), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('arena-action-reason-skill_1')),
          findsOneWidget,
        );

        // 7. Chọn Đánh thường -> xem phản hồi Round 1 & mở Xem cách chấm
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-action-basic')),
        );
        expect(
          find.byKey(const ValueKey<String>('arena-round-feedback-title')),
          findsOneWidget,
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-feedback-rubric')),
        );
        expect(
          find.byKey(const ValueKey<String>('arena-rubric-reveal-box')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Hoàn thành trận Luyện đơn đến Tổng kết (0 RP) và Luyện lại cùng seed trên màn dọc 390x844',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

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

        final SoloArenaViewModel arenaVm = SoloArenaViewModel(initialSeed: 2026);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: MindClockShellScreen(
                viewModel: guestVm,
                personalViewModel: personalVm,
                arenaViewModel: arenaVm,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey<String>('nav-arena')));
        await tester.pumpAndSettle();
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-enter-solo')),
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-start-solo-match')),
        );

        final String firstRoundQuestionId = arenaVm.currentQuestion!.id;

        // Chạy hết trận đến màn Tổng kết
        for (int round = 1; round <= maxCombatRounds; round++) {
          if (arenaVm.section == ArenaSection.summary) {
            break;
          }
          final q = arenaVm.currentQuestion!;
          await _scrollAndEnterText(
            tester,
            find.byKey(const ValueKey<String>('arena-answer-input')),
            q.acceptedAnswers.first,
          );
          await _scrollAndEnterText(
            tester,
            find.byKey(const ValueKey<String>('arena-reasoning-input')),
            '${q.reasoningKeywords.first} -> kết quả',
          );
          await _scrollCenterAndTap(
            tester,
            find.byKey(const ValueKey<String>('arena-submit-answer')),
          );

          // Nếu đủ Qi dùng Chiêu 1 ở round sau, ngược lại Đánh thường
          final bool canUseSkill1 = arenaVm.actionOptions
              .any((a) => a.actionType == CombatActionType.skill1 && a.enabled);
          await _scrollCenterAndTap(
            tester,
            find.byKey(
              ValueKey<String>(
                canUseSkill1 ? 'arena-action-skill_1' : 'arena-action-basic',
              ),
            ),
          );
          await _scrollCenterAndTap(
            tester,
            find.byKey(const ValueKey<String>('arena-next-round')),
          );
        }

        expect(
          find.byKey(const ValueKey<String>('arena-summary-local-pill')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('arena-summary-outcome')),
          findsOneWidget,
        );
        expect(find.textContaining('0 RP'), findsOneWidget);
        expect(find.text('Đấu hạng'), findsNothing);

        // Mở xem cách chấm Round 1 trong Tổng kết
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-summary-rubric-1')),
        );
        expect(
          find.byKey(const ValueKey<String>('arena-rubric-reveal-box')),
          findsOneWidget,
        );

        // Luyện lại cùng seed -> nhận đúng lại câu hỏi Round 1
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-replay-same-seed')),
        );
        expect(arenaVm.currentRound, 1);
        expect(arenaVm.currentQuestion!.id, firstRoundQuestionId);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'T054: Đóng gói đủ 11 asset đấu trường, mở modal xem chi tiết nội tại/skill trước trận và render map + skill icon',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Xác nhận toàn bộ 11 asset ảnh gốc tải được qua asset bundle Flutter
        final List<String> expectedAssets = <String>[
          CombatCatalog.mapCourtyardAssetPath,
          CombatCatalog.basicAttackAssetPath,
          for (final ChampionSpec spec in CombatCatalog.champions.values) ...<String>[
            spec.portraitAssetPath,
            spec.skill1.iconAssetPath,
            spec.skill2.iconAssetPath,
          ],
        ];
        for (final String path in expectedAssets) {
          final ByteData bytes = await rootBundle.load(path);
          expect(bytes.lengthInBytes, greaterThan(1000), reason: 'Thiếu asset $path');
        }

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

        final SoloArenaViewModel arenaVm = SoloArenaViewModel(initialSeed: 2026);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
            ),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: MindClockShellScreen(
                viewModel: guestVm,
                personalViewModel: personalVm,
                arenaViewModel: arenaVm,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey<String>('nav-arena')));
        await tester.pumpAndSettle();
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-enter-solo')),
        );

        // Bấm xem chi tiết Tuyệt Đỉnh trước khi vào trận
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-champion-detail-tuyet_dinh')),
        );
        final Finder detailSheet = find.byKey(
          const ValueKey<String>('arena-champion-detail-sheet-tuyet_dinh'),
        );
        expect(detailSheet, findsOneWidget);
        expect(
          find.descendant(
            of: detailSheet,
            matching: find.textContaining('Nội tại: Tập Trung Đột Phá'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: detailSheet,
            matching: find.textContaining('Một Nét Thành Chiêu'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: detailSheet,
            matching: find.textContaining('Đường Kiếm Cuối Trang'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-champion-detail-close')),
        );
        expect(
          find.byKey(
            const ValueKey<String>('arena-champion-detail-sheet-tuyet_dinh'),
          ),
          findsNothing,
        );

        // Vào trận ở chế độ đồ họa thật -> thấy Map nền Võ đường Bình minh
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-subject-math')),
        );
        await _scrollCenterAndTap(
          tester,
          find.byKey(const ValueKey<String>('arena-start-solo-match')),
        );
        expect(
          find.byKey(const ValueKey<String>('arena-stage-map-image')),
          findsOneWidget,
        );
        expect(find.textContaining('Võ đường Bình minh'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
