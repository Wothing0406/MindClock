import 'dart:convert';

import '../../domain/models/guest_workspace.dart';
import '../services/local_key_value_store.dart';

class GuestWorkspaceRepository {
  const GuestWorkspaceRepository({required LocalKeyValueStore store})
      : _store = store;

  static const String workspaceKey = 'mindclock_guest_workspace_v1';

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

  Future<void> clear() async {
    await _store.remove(workspaceKey);
  }
}
