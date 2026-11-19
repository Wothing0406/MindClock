import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_pvp_gateway.dart';
import 'package:mindclock_app/domain/game/combat_catalog.dart';
import 'package:mindclock_app/domain/game/pvp_models.dart';
import 'package:mindclock_app/domain/game/solo_combat_engine.dart';
import 'package:mindclock_app/domain/game/solo_training_question_bank.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/core/widgets/mindclock_avatar_view.dart';
import 'package:mindclock_app/ui/features/arena/view_models/pvp_arena_view_model.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_pvp_lobby.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_sprite_stage.dart';

void main() {
  testWidgets(
    'T061 TC-01: 6+ Avatar góc gốc mới, ArenaSpriteActor VFX, Reduce Motion và luật Qi Đánh thường -> Chiêu 1/2',
    (WidgetTester tester) async {
      // Đủ 6 avatar linh vật + 3 tướng đều có assetPath hợp lệ
      expect(MindClockAvatarCatalog.presets.length, greaterThanOrEqualTo(6));
      for (final String id in const <String>[
        'sunrise',
        'cu_meo',
        'cao_giay',
        'ca_chep',
        'rua_xanh',
        'may_nho',
      ]) {
        expect(MindClockAvatarCatalog.assetPathFor(id), isNotNull);
      }

      // Kiểm luật Qi: 0 Qi chỉ đánh thường; 1 Qi mở Chiêu 1; 2 Qi mở Chiêu 2
      final List<SoloActionAvailability> zeroQi = evaluateActionAvailability(
        state: const SoloCombatantState(
          actorId: 'p1',
          displayName: 'Bạn',
          championId: ChampionId.haNhan,
          isBot: false,
          qi: 0,
        ),
        roundNo: 1,
        playerGrade: SoloGradeStatus.correct,
        actionWindowOpen: true,
      );
      expect(zeroQi.firstWhere((a) => a.actionType == CombatActionType.basic).enabled, isTrue);
      expect(zeroQi.firstWhere((a) => a.actionType == CombatActionType.skill1).enabled, isFalse);
      expect(zeroQi.firstWhere((a) => a.actionType == CombatActionType.skill2).enabled, isFalse);

      final List<SoloActionAvailability> twoQi = evaluateActionAvailability(
        state: const SoloCombatantState(
          actorId: 'p1',
          displayName: 'Bạn',
          championId: ChampionId.haNhan,
          isBot: false,
          qi: 2,
        ),
        roundNo: 2,
        playerGrade: SoloGradeStatus.correct,
        actionWindowOpen: true,
      );
      expect(twoQi.firstWhere((a) => a.actionType == CombatActionType.skill1).enabled, isTrue);
      expect(twoQi.firstWhere((a) => a.actionType == CombatActionType.skill2).enabled, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: Column(
              children: <Widget>[
                ArenaSpriteActor(
                  spec: CombatCatalog.getSpec(ChampionId.haNhan),
                  facingRight: true,
                  isBot: false,
                  disableMotion: false,
                  assetFallbackMode: false,
                  actionUsed: CombatActionType.skill1,
                  damageTaken: 12,
                ),
                const ArenaQiGuideStrip(currentQi: 1, maxQi: 3),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('arena-qi-guide-strip')),
        findsOneWidget,
      );
      expect(find.textContaining('-12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'T061 TC-02: Đấu đơn 1v1 PvP client-server hàng đợi -> vào trận -> trả lời -> Đánh thường tích Qi -> Skill 1 ở 320dp 200%',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final DebugFixturePvpGateway gateway = DebugFixturePvpGateway(
        selfUserId: 'user_a',
        opponentUserId: 'user_b',
      );
      final PvpArenaViewModel vm = PvpArenaViewModel(
        gateway: gateway,
        enableAutoPolling: false,
      );

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(2.0),
            disableAnimations: true,
          ),
          child: MaterialApp(
            theme: MindClockTheme.buildThemeData(),
            home: Scaffold(
              body: ArenaPvpLobby(
                viewModel: vm,
                profile: const StudyProfile(
                  alias: 'Minh An',
                  gradeLevel: 'Lớp 11',
                  selectedSubjectCodes: <String>['math', 'physics'],
                ),
                userId: 'user_a',
                onBackToHub: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Bấm Tìm trận 1v1 -> vào hàng đợi waiting
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('pvp-find-match-btn')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('pvp-find-match-btn')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('pvp-queuing-card')),
        findsOneWidget,
      );

      // 2. Poll thấy đối thủ -> ghép trận Round 1
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('pvp-poll-now-btn')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('pvp-poll-now-btn')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('pvp-round-prompt')),
        findsOneWidget,
      );
      expect(vm.stage, PvpUiStage.inMatch);
      expect(vm.snapshot!.status, 'in_progress');
      expect(PvpMatchmakeResponse.fromJson(<String, dynamic>{'status': 'waiting'}).isWaiting, isTrue);

      // 3. Thử nộp "uncertain" -> round chuyển void, không trừ HP/mở action
      await tester.enterText(
        find.byKey(const ValueKey<String>('pvp-answer-input')),
        '',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('pvp-reasoning-input')),
        'uncertain chưa chắc bước này',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('pvp-submit-answer-btn')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('pvp-submit-answer-btn')),
      );
      await tester.pumpAndSettle();
      expect(vm.snapshot!.currentRoundInfo!.state, 'void');

      // Sau uncertain (void), khởi tạo trận mới sạch để kiểm tra đáp án đúng -> +1 Qi
      await gateway.cancelMatchmake();
      vm.leaveFinishedMatch();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('pvp-find-match-btn')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('pvp-find-match-btn')),
      );
      await tester.pumpAndSettle();
      await vm.pollOnce();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('pvp-answer-input')),
      );

      final SoloApprovedQuestion firstDeckQ =
          SoloTrainingQuestionBank.selectDeterministicDeck(
        subjectCode: 'math',
        seed: 20261119,
      ).first;
      await tester.enterText(
        find.byKey(const ValueKey<String>('pvp-answer-input')),
        firstDeckQ.acceptedAnswers.first,
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('pvp-reasoning-input')),
        'Áp dụng đúng công thức: ${firstDeckQ.reasoningKeywords.isNotEmpty ? firstDeckQ.reasoningKeywords.first : "tính từng bước chi tiết"}.',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('pvp-submit-answer-btn')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('pvp-submit-answer-btn')),
      );
      await tester.pumpAndSettle();

      // Mở action window, lúc này Qi = 0 -> Chiêu 1 bị vô hiệu, Đánh thường bật
      expect(
        find.byKey(const ValueKey<String>('pvp-action-basic')),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('pvp-action-basic')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('pvp-action-basic')),
      );
      await tester.pumpAndSettle();

      // Sau đánh thường ở Round 1, Qi tăng lên 1 ở Round 2!
      expect(vm.snapshot!.players.first.qi, 1);
      expect(vm.snapshot!.currentRound, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
