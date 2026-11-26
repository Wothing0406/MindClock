import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/repositories/arena_cosmetic_store.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/game/arena_lobby_models.dart';
import 'package:mindclock_app/domain/game/combat_catalog.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/arena/view_models/solo_arena_view_model.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_screen.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_sprite_stage.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';

void main() {
  test(
    'T064 TC-01: 3 tướng gốc assets/game, nativeFacingRight chuẩn, frame sequences & zero pay-to-win',
    () {
      expect(
        CombatCatalog.mapCourtyardAssetPath,
        'assets/game/maps/study-courtyard.webp',
      );

      final ChampionSpec haNhan = CombatCatalog.getSpec(ChampionId.haNhan);
      final ChampionSpec tuyetDinh = CombatCatalog.getSpec(ChampionId.tuyetDinh);
      final ChampionSpec hanBoi = CombatCatalog.getSpec(ChampionId.hanBoiPhap);

      expect(haNhan.nativeFacingRight, isTrue);
      expect(hanBoi.nativeFacingRight, isTrue);
      expect(tuyetDinh.nativeFacingRight, isFalse);

      for (final ChampionSpec spec in <ChampionSpec>[haNhan, tuyetDinh, hanBoi]) {
        expect(spec.portraitAssetPath, contains('assets/game/characters/'));
        expect(spec.animatedIdleAssetPath, endsWith('/runtime/idle.webp'));
        for (final String action in const <String>[
          'basic',
          'skill1',
          'skill2',
          'victory',
        ]) {
          expect(spec.framesForAction(action).length, 6);
        }
        for (final String action in const <String>['hurt', 'stun', 'heal']) {
          expect(spec.framesForAction(action).length, 4);
        }
      }

      expect(resolveArenaSpriteClip(), 'idle');
      expect(
        resolveArenaSpriteClip(actionUsed: CombatActionType.skill2),
        'skill2',
      );
      expect(resolveArenaSpriteClip(damageTaken: 14), 'hurt');
      expect(resolveArenaSpriteClip(healAmount: 8), 'heal');
      expect(resolveArenaSpriteClip(isStunned: true), 'stun');
      expect(
        resolveArenaSpriteClip(isWinner: true, actionUsed: CombatActionType.basic),
        'victory',
      );

      for (final ArenaCosmeticItem item in ArenaCosmeticCatalog.allItems) {
        expect(item.bonusDamage, 0);
        expect(item.bonusHp, 0);
        expect(item.bonusArmor, 0);
      }

      final List<ArenaCosmeticItem> day1 =
          ArenaCosmeticCatalog.dailyOfferingsForDate(DateTime(2026, 11, 20));
      final List<ArenaCosmeticItem> day2 =
          ArenaCosmeticCatalog.dailyOfferingsForDate(DateTime(2026, 11, 21));
      expect(day1.length, 4);
      expect(
        day1.map((e) => e.id).toList(),
        isNot(equals(day2.map((e) => e.id).toList())),
      );
    },
  );

  testWidgets(
    'T064 TC-02/03/04: Sảnh chờ 3 tướng gốc animated, BXH kiến thức opt-in/filter & Daily Shop mua+trang bị bền vững ở 320dp',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: kv),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();

      final SoloArenaViewModel arenaVm = SoloArenaViewModel();
      final ArenaCosmeticStore cosmeticStore = ArenaCosmeticStore(
        store: kv,
        ownerScopeKey: guestVm.ownerScopeKey,
        nowProvider: () => DateTime(2026, 11, 20),
      );
      await cosmeticStore.load();

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: ArenaScreen(
              guestViewModel: guestVm,
              arenaViewModel: arenaVm,
              cosmeticStore: cosmeticStore,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Sảnh chờ hiển thị banner ví Xu & 3 tướng gốc với switch trực tiếp
      expect(
        find.byKey(const ValueKey<String>('arena-lobby-profile-banner')),
        findsOneWidget,
      );
      expect(find.text('120 Xu'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('arena-lobby-champion-showcase')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-lobby-champ-tuyet_dinh')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-lobby-champ-tuyet_dinh')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Tập Trung Đột Phá'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('arena-lobby-champ-han_boi_phap')),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Bích Chướng Cổ Giới'), findsOneWidget);

      // 2. Tab Bảng xếp hạng: kiểm tra bộ lọc môn/khối + ẩn danh opt-in + không giờ dậy
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-lobby-tab-leaderboard')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-lobby-tab-leaderboard')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('arena-leaderboard-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('arena-lb-entry-self_user')),
        findsOneWidget,
      );
      expect(find.textContaining('05:'), findsNothing);
      expect(find.textContaining('06:'), findsNothing);
      expect(find.textContaining('AM'), findsNothing);

      // Tắt opt-in -> user biến mất khỏi BXH
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-leaderboard-optin-toggle')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-leaderboard-optin-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('arena-lb-entry-self_user')),
        findsNothing,
      );

      // Bật lại + lọc Toán
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-leaderboard-optin-toggle')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-lb-subject-math')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-lb-subject-math')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('arena-lb-entry-peer_gia_huy')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('arena-lb-entry-peer_minh_anh')),
        findsOneWidget,
      );

      // 3. Tab Daily Shop: mua vật phẩm mỹ thuật hợp túi tiền -> trừ Xu -> lưu & tự trang bị
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-lobby-tab-shop')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-lobby-tab-shop')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('arena-daily-shop-panel')),
        findsOneWidget,
      );

      final ArenaCosmeticItem affordable = cosmeticStore.todayOfferings
          .firstWhere((ArenaCosmeticItem i) => i.priceCoins <= 120);
      final Key buyBtnKey = ValueKey<String>('arena-shop-action-${affordable.id}');
      await tester.ensureVisible(find.byKey(buyBtnKey));
      await tester.tap(find.byKey(buyBtnKey));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('arena-shop-feedback')),
        findsOneWidget,
      );
      expect(cosmeticStore.state.mindCoins, 120 - affordable.priceCoins);
      expect(cosmeticStore.state.ownedItemIds.contains(affordable.id), isTrue);

      // Mở lại store từ LocalKeyValueStore -> vẫn nhớ vật phẩm đã mua & Xu
      final ArenaCosmeticStore reloaded = ArenaCosmeticStore(
        store: kv,
        ownerScopeKey: guestVm.ownerScopeKey,
        nowProvider: () => DateTime(2026, 11, 20),
      );
      await reloaded.load();
      expect(reloaded.state.mindCoins, 120 - affordable.priceCoins);
      expect(reloaded.state.ownedItemIds.contains(affordable.id), isTrue);

      // Idempotency thưởng trận: cùng matchKey không cộng 2 lần
      final int gain1 = await reloaded.awardMatchResult(
        matchKey: 'm_001',
        won: true,
        correctRounds: 3,
        totalRounds: 4,
        isPvp: false,
      );
      final int gain2 = await reloaded.awardMatchResult(
        matchKey: 'm_001',
        won: true,
        correctRounds: 3,
        totalRounds: 4,
        isPvp: false,
      );
      expect(gain1, greaterThan(0));
      expect(gain2, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
