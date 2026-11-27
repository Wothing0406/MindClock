import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../../../domain/models/community_models.dart';
import '../../../../domain/models/personal_flow_models.dart';
import '../../../../domain/services/community_repository.dart';

/// REST room state; independent of study timer and live audio/video.
class StudyRoomSessionViewModel extends ChangeNotifier {
  StudyRoomSessionViewModel(
      {required CommunityRepository repository,
      StudyRoomDetail? initialRoom,
      this.pollInterval = const Duration(seconds: 5),
      this.enablePolling = true,
      DateTime Function()? nowProvider})
      : _repository = repository,
        _room = (initialRoom != null && initialRoom.summary.isOpen)
            ? initialRoom
            : null,
        _now = nowProvider ?? DateTime.now {
    _schedule();
  }

  final CommunityRepository _repository;
  final Duration pollInterval;
  final bool enablePolling;
  final DateTime Function() _now;
  StudyRoomDetail? _room;
  Timer? _ticker;
  int _epoch = 0;
  bool _fetching = false;
  bool _mutating = false;
  bool _foreground = true;
  bool _disposed = false;
  String? _message;
  DateTime? _syncedAt;

  StudyRoomDetail? get room => _room;
  bool get isBusy => _fetching || _mutating;
  bool get isMutating => _mutating;
  String? get message => _message;
  DateTime? get syncedAt => _syncedAt;
  bool get isHost =>
      _room?.members.any((m) => m.isSelf && m.role == 'host') ?? false;

  void _schedule() {
    _ticker?.cancel();
    _ticker = null;
    if (_disposed ||
        !_foreground ||
        !enablePolling ||
        _repository.isDebugFixture ||
        _room == null) {
      return;
    }
    _ticker = Timer.periodic(pollInterval, (_) => refresh());
  }

  void attach(StudyRoomDetail? room) {
    _epoch++;
    _room = (room != null && room.summary.isOpen) ? room : null;
    _message = null;
    _syncedAt = null;
    _schedule();
    notifyListeners();
  }

  void setForeground(bool foreground) {
    if (_disposed || foreground == _foreground) return;
    _foreground = foreground;
    if (!foreground) _epoch++;
    _schedule();
    if (foreground) refresh();
  }

  void _failure(Object error) {
    if (error is PersonalApiException) {
      _message = error.messageVi;
      if ([401, 403, 404, 410].contains(error.httpStatus)) {
        _room = null;
        _syncedAt = null;
        _schedule();
      }
    } else {
      _message =
          'Chưa cập nhật được phòng. Bạn có thể thử lại; thời gian học vẫn được giữ.';
    }
  }

  Future<void> refresh() async {
    final current = _room;
    if (_disposed || !_foreground || current == null || isBusy) return;
    final epoch = _epoch;
    _fetching = true;
    notifyListeners();
    try {
      final next = await _repository.fetchRoom(current.summary.roomId);
      if (_disposed || epoch != _epoch) return;
      if (!next.summary.isOpen || !next.members.any((m) => m.isSelf)) {
        _room = null;
        _syncedAt = null;
        _message = 'Phòng đã kết thúc hoặc bạn không còn là thành viên.';
        _schedule();
      } else {
        _room = next;
        _message = null;
        _syncedAt = _now();
      }
    } catch (error) {
      if (!_disposed && epoch == _epoch) _failure(error);
    } finally {
      _fetching = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> sendHeartbeat({String? statusNote}) => _change((id) async {
        final next =
            await _repository.heartbeatRoom(id, statusNote: statusNote);
        if (!next.summary.isOpen || !next.members.any((m) => m.isSelf)) {
          return null;
        }
        return next;
      });

  Future<bool> _change(Future<StudyRoomDetail?> Function(String) action) async {
    final current = _room;
    if (_disposed || current == null || _mutating) return false;
    final epoch = ++_epoch; // Invalidate a poll that began before this change.
    _mutating = true;
    _message = null;
    notifyListeners();
    try {
      final next = await action(current.summary.roomId);
      if (_disposed || epoch != _epoch) return false;
      _room = next;
      _syncedAt = next == null ? null : _now();
      _schedule();
      return true;
    } catch (error) {
      if (!_disposed && epoch == _epoch) _failure(error);
      return false;
    } finally {
      _mutating = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> saveSettings(
      {String? title,
      int? maxMembers,
      String? visibility,
      bool? aiCompanionEnabled}) async {
    if (!isHost) return false;
    return _change((id) => _repository.updateRoomSettings(id,
        title: title,
        maxMembers: maxMembers,
        visibility: visibility,
        aiCompanionEnabled: aiCompanionEnabled));
  }

  Future<bool> updateMedia(
          {bool? micEnabled, bool? camEnabled, bool? aiCompanionEnabled}) =>
      _change((id) => _repository.updateRoomMedia(id,
          micEnabled: micEnabled,
          camEnabled: camEnabled,
          aiCompanionEnabled: aiCompanionEnabled));

  Future<bool> leave({bool transferHost = false}) => _change((id) async {
        await _repository.leaveRoom(id, transferHost: transferHost);
        return null;
      });

  Future<bool> closeRoom() async {
    if (!isHost) return false;
    return _change((id) async {
      await _repository.closeRoom(id);
      return null;
    });
  }

  Future<bool> removeMember(String memberUserId) async {
    if (!isHost || memberUserId.trim().isEmpty) return false;
    final self = _room?.members.where((member) => member.isSelf).firstOrNull;
    if (self == null || self.userId == memberUserId) return false;
    return _change(
      (id) => _repository.removeRoomMember(id, memberUserId),
    );
  }

  Future<bool> deleteRoom() async {
    if (!isHost) return false;
    return _change((id) async {
      await _repository.deleteRoom(id);
      return null;
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    _ticker?.cancel();
    super.dispose();
  }
}
