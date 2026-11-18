import 'dart:convert';

import '../../domain/models/guest_workspace.dart';
import '../../domain/models/study_profile.dart';
import '../../domain/models/timetable.dart';
import '../services/local_key_value_store.dart';

/// Hồ sơ & TKB lưu riêng theo từng `ownerScopeKey` (tách biệt tài khoản A/B theo ON-06).
class ScopedAccountWorkspaceData {
  const ScopedAccountWorkspaceData({
    required this.profile,
    required this.timetable,
  });

  final StudyProfile profile;
  final WeeklyTimetable timetable;
}

class GuestWorkspaceRepository {
  const GuestWorkspaceRepository({required LocalKeyValueStore store})
      : _store = store;

  static const String workspaceKey = 'mindclock_guest_workspace_v1';
  static const String scopedPrefix = 'mindclock_scoped_account_v1_';

  final LocalKeyValueStore _store;

  LocalKeyValueStore get store => _store;

  Future<GuestWorkspace> load() async {
    final String? raw = await _store.readString(workspaceKey);
    if (raw == null || raw.trim().isEmpty) {
      return GuestWorkspace.initial();
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return GuestWorkspace.fromJson(decoded);
      }
    } catch (_) {
      // Nếu dữ liệu cũ hỏng định dạng, trả trạng thái khởi tạo an toàn thay vì crash.
    }
    return GuestWorkspace.initial();
  }

  Future<GuestWorkspace> save(GuestWorkspace workspace) async {
    final GuestWorkspace stamped = workspace.copyWith(
      lastSavedIso: DateTime.now().toIso8601String(),
    );
    await _store.writeString(workspaceKey, jsonEncode(stamped.toJson()));
    return stamped;
  }

  Future<ScopedAccountWorkspaceData?> loadScopedAccountData(
    String ownerScopeKey,
  ) async {
    final String cleanKey = ownerScopeKey.trim();
    if (cleanKey.isEmpty) return null;
    final String? raw = await _store.readString('$scopedPrefix$cleanKey');
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final Object? rawProfile = decoded['profile'];
        final Object? rawTimetable = decoded['timetable'];
        return ScopedAccountWorkspaceData(
          profile: rawProfile is Map<String, dynamic>
              ? StudyProfile.fromJson(rawProfile)
              : const StudyProfile(),
          timetable: rawTimetable is Map<String, dynamic>
              ? WeeklyTimetable.fromJson(rawTimetable)
              : WeeklyTimetable(),
        );
      }
    } catch (_) {
      // Bỏ qua dữ liệu hỏng và trả null để dùng khởi tạo an toàn.
    }
    return null;
  }

  Future<void> saveScopedAccountData(
    String ownerScopeKey, {
    required StudyProfile profile,
    required WeeklyTimetable timetable,
  }) async {
    final String cleanKey = ownerScopeKey.trim();
    if (cleanKey.isEmpty) return;
    await _store.writeString(
      '$scopedPrefix$cleanKey',
      jsonEncode(<String, dynamic>{
        'profile': profile.toJson(),
        'timetable': timetable.toJson(),
      }),
    );
  }

  Future<void> clearScopedAccountData(String ownerScopeKey) async {
    final String cleanKey = ownerScopeKey.trim();
    if (cleanKey.isEmpty) return;
    await _store.remove('$scopedPrefix$cleanKey');
  }

  Future<void> clear() async {
    await _store.remove(workspaceKey);
  }
}
