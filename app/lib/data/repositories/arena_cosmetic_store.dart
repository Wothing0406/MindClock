import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/game/arena_lobby_models.dart';
import '../services/local_key_value_store.dart';

/// Kết quả thao tác mua hoặc trang bị vật phẩm trong Daily Shop (`T064`).
class CosmeticActionOutcome {
  const CosmeticActionOutcome({
    required this.success,
    required this.messageVi,
    required this.state,
  });

  final bool success;
  final String messageVi;
  final ArenaWalletState state;
}

/// Quản lý ví MindCoin (chỉ kiếm từ học/đấu hợp lệ), vật phẩm mỹ thuật và tùy chọn
/// Bảng xếp hạng cục bộ theo `ownerScopeKey` (`AGENTS.md §3`, `docs/04-game/03`).
class ArenaCosmeticStore extends ChangeNotifier {
  ArenaCosmeticStore({
    required LocalKeyValueStore store,
    String ownerScopeKey = 'guest',
    DateTime Function()? nowProvider,
  })  : _store = store,
        _ownerScopeKey = ownerScopeKey,
        _nowProvider = nowProvider ?? DateTime.now;

  static const String storageKeyPrefix = 'mindclock_arena_cosmetic_v1_';

  final LocalKeyValueStore _store;
  String _ownerScopeKey;
  final DateTime Function() _nowProvider;

  ArenaWalletState _state = ArenaWalletState.initial();
  bool _loaded = false;

  ArenaWalletState get state => _state;
  bool get isLoaded => _loaded;
  String get ownerScopeKey => _ownerScopeKey;

  String get _storageKey => '$storageKeyPrefix$_ownerScopeKey';

  List<ArenaCosmeticItem> get todayOfferings =>
      ArenaCosmeticCatalog.dailyOfferingsForDate(_nowProvider());

  String get todayDateKey =>
      ArenaCosmeticCatalog.formatDateKey(_nowProvider());

  ArenaRankTier get currentTier =>
      ArenaCosmeticCatalog.tierForScore(_state.localFriendlyScore);

  Future<void> switchScope(String ownerScopeKey) async {
    final String clean = ownerScopeKey.trim().isEmpty ? 'guest' : ownerScopeKey.trim();
    if (_ownerScopeKey == clean && _loaded) return;
    _ownerScopeKey = clean;
    await load();
  }

  Future<void> load() async {
    final String? raw = await _store.readString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      _state = ArenaWalletState.initial();
      _loaded = true;
      notifyListeners();
      return;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _state = ArenaWalletState.fromJson(decoded);
      } else {
        _state = ArenaWalletState.initial();
      }
    } catch (_) {
      _state = ArenaWalletState.initial();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await _store.writeString(_storageKey, jsonEncode(_state.toJson()));
  }

  Future<CosmeticActionOutcome> buyItem(ArenaCosmeticItem item) async {
    if (_state.ownedItemIds.contains(item.id)) {
      return equipItem(item);
    }
    if (_state.mindCoins < item.priceCoins) {
      return CosmeticActionOutcome(
        success: false,
        messageVi:
            'Cần thêm ${item.priceCoins - _state.mindCoins} Xu để mở khóa ${item.nameVi}.',
        state: _state,
      );
    }

    final Set<String> nextOwned = Set<String>.from(_state.ownedItemIds)
      ..add(item.id);
    _state = _applyEquipToState(
      _state.copyWith(
        mindCoins: _state.mindCoins - item.priceCoins,
        ownedItemIds: nextOwned,
      ),
      item,
    );
    await _save();
    notifyListeners();
    return CosmeticActionOutcome(
      success: true,
      messageVi:
          'Đã mở khóa và trang bị ${item.nameVi} (chỉ mỹ thuật · 0 tăng chỉ số).',
      state: _state,
    );
  }

  Future<CosmeticActionOutcome> equipItem(ArenaCosmeticItem item) async {
    if (!_state.ownedItemIds.contains(item.id)) {
      return CosmeticActionOutcome(
        success: false,
        messageVi: 'Bạn chưa sở hữu ${item.nameVi}.',
        state: _state,
      );
    }
    _state = _applyEquipToState(_state, item);
    await _save();
    notifyListeners();
    return CosmeticActionOutcome(
      success: true,
      messageVi: 'Đã trang bị ${item.nameVi}.',
      state: _state,
    );
  }

  ArenaWalletState _applyEquipToState(
    ArenaWalletState base,
    ArenaCosmeticItem item,
  ) {
    return switch (item.category) {
      ArenaCosmeticCategory.frame => base.copyWith(equippedFrameId: item.id),
      ArenaCosmeticCategory.avatar => base.copyWith(equippedAvatarId: item.id),
      ArenaCosmeticCategory.aura => base.copyWith(equippedAuraId: item.id),
    };
  }

  Future<void> setLeaderboardOptIn(bool enabled) async {
    _state = _state.copyWith(leaderboardOptIn: enabled);
    await _save();
    notifyListeners();
  }

  /// Cộng MindCoin hợp lệ sau trận/lượt ôn (idempotent theo `matchKey`, không trừ Xu khi thua/bỏ).
  Future<int> awardMatchResult({
    required String matchKey,
    required bool won,
    required int correctRounds,
    required int totalRounds,
    required bool isPvp,
  }) async {
    if (_state.rewardedMatchKeys.contains(matchKey)) {
      return 0;
    }
    final int safeCorrect = correctRounds < 0 ? 0 : correctRounds;
    final int safeTotal = totalRounds < 0 ? 0 : totalRounds;
    final int baseReward = won ? 25 : 12;
    final int accuracyBonus = safeCorrect * 5 + (isPvp ? 8 : 0);
    final int earnedCoins = baseReward + accuracyBonus;
    final int earnedScore = safeCorrect * 18 + (won ? 30 : 10);

    final Set<String> nextKeys = Set<String>.from(_state.rewardedMatchKeys)
      ..add(matchKey);

    _state = _state.copyWith(
      mindCoins: _state.mindCoins + earnedCoins,
      localFriendlyScore: _state.localFriendlyScore + earnedScore,
      localMatchesCount: _state.localMatchesCount + 1,
      localCorrectRounds: _state.localCorrectRounds + safeCorrect,
      localTotalRounds: _state.localTotalRounds + safeTotal,
      rewardedMatchKeys: nextKeys,
    );
    await _save();
    notifyListeners();
    return earnedCoins;
  }

  /// Danh sách Bảng xếp hạng kiến thức giao hữu (chỉ xếp theo điểm & % chính xác).
  ///
  /// - Không bao giờ chứa giờ dậy, thời khóa biểu, trường học hay email.
  /// - Tôn trọng `leaderboardOptIn`: tắt -> không hiển thị dòng của người dùng.
  List<ArenaLeaderboardEntry> buildFriendlyLeaderboard({
    required String userAlias,
    required String userGradeLevel,
    required String primarySubjectCode,
    String subjectFilter = 'all',
    String gradeFilter = 'all',
  }) {
    final List<ArenaLeaderboardEntry> base = <ArenaLeaderboardEntry>[
      const ArenaLeaderboardEntry(
        id: 'peer_minh_anh',
        displayName: 'Minh Anh · Tổ hợp Tự nhiên',
        gradeBand: 'Lớp 12',
        subjectCode: 'math',
        accuracyPercent: 92,
        validMatchesCount: 18,
        friendlyScore: 860,
        rankTierId: 'kien_trien',
      ),
      const ArenaLeaderboardEntry(
        id: 'peer_gia_huy',
        displayName: 'Gia Huy · Vững nền Lý',
        gradeBand: 'Lớp 11',
        subjectCode: 'physics',
        accuracyPercent: 86,
        validMatchesCount: 14,
        friendlyScore: 620,
        rankTierId: 'tinh_hoa',
      ),
      const ArenaLeaderboardEntry(
        id: 'peer_thao_vy',
        displayName: 'Thảo Vy · Hóa hữu cơ',
        gradeBand: 'Lớp 12',
        subjectCode: 'chemistry',
        accuracyPercent: 81,
        validMatchesCount: 11,
        friendlyScore: 470,
        rankTierId: 'tinh_hoa',
      ),
      const ArenaLeaderboardEntry(
        id: 'peer_hoang_nam',
        displayName: 'Hoàng Nam · Bền bỉ Toán 10',
        gradeBand: 'Lớp 10',
        subjectCode: 'math',
        accuracyPercent: 78,
        validMatchesCount: 9,
        friendlyScore: 310,
        rankTierId: 'kham_pha',
      ),
      const ArenaLeaderboardEntry(
        id: 'peer_khanh_linh',
        displayName: 'Khánh Linh · Tiếng Anh 11',
        gradeBand: 'Lớp 11',
        subjectCode: 'english',
        accuracyPercent: 75,
        validMatchesCount: 8,
        friendlyScore: 245,
        rankTierId: 'dong_hanh',
      ),
    ];

    final List<ArenaLeaderboardEntry> pool = List<ArenaLeaderboardEntry>.from(base);
    if (_state.leaderboardOptIn) {
      final String cleanAlias =
          userAlias.trim().isEmpty ? 'Bạn học MindClock' : userAlias.trim();
      final String cleanGrade =
          userGradeLevel.trim().isEmpty ? 'Lớp 11' : userGradeLevel.trim();
      final String cleanSubj =
          primarySubjectCode.trim().isEmpty ? 'math' : primarySubjectCode.trim();
      pool.add(
        ArenaLeaderboardEntry(
          id: 'self_user',
          displayName: cleanAlias,
          gradeBand: cleanGrade,
          subjectCode: cleanSubj,
          accuracyPercent: _state.localAccuracyPercent,
          validMatchesCount: _state.localMatchesCount,
          friendlyScore: _state.localFriendlyScore,
          rankTierId: currentTier.id,
          isCurrentUser: true,
        ),
      );
    }

    final List<ArenaLeaderboardEntry> filtered = pool.where((ArenaLeaderboardEntry e) {
      final bool matchSubj =
          subjectFilter == 'all' || e.subjectCode == subjectFilter;
      final bool matchGrade =
          gradeFilter == 'all' || e.gradeBand == gradeFilter;
      return matchSubj && matchGrade;
    }).toList();

    filtered.sort((ArenaLeaderboardEntry a, ArenaLeaderboardEntry b) {
      final int byScore = b.friendlyScore.compareTo(a.friendlyScore);
      if (byScore != 0) return byScore;
      final int byAcc = b.accuracyPercent.compareTo(a.accuracyPercent);
      if (byAcc != 0) return byAcc;
      return b.validMatchesCount.compareTo(a.validMatchesCount);
    });
    return filtered;
  }
}
