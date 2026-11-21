import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../data/services/local_id_generator.dart';
import '../../../../domain/services/study_speech_gateway.dart';
import '../../../../domain/models/personal_flow_models.dart';

/// Playback state belongs to the current screen/account/session only.
class StudySpeechViewModel extends ChangeNotifier {
  StudySpeechViewModel(
      {required StudySpeechGateway gateway,
      this.startTimeout = const Duration(seconds: 15)})
      : _gateway = gateway {
    _subscription = gateway.events.listen(_onEvent);
  }

  final StudySpeechGateway _gateway;
  final Duration startTimeout;
  late final StreamSubscription<StudySpeechEvent> _subscription;
  String? _scope;
  bool _allowed = false;
  bool _disposed = false;
  String? _id;
  Timer? _watchdog;
  bool _speaking = false;
  String? _errorVi;

  bool get isSpeaking => _speaking;
  bool get isBusy => _id != null;
  String? get errorVi => _errorVi;

  void configure({required String scope, required bool allowed}) {
    if (_scope == scope && _allowed == allowed) return;
    _scope = scope;
    _allowed = allowed;
    stop();
  }

  Future<void> readReply(String text) async {
    if (_disposed || !_allowed || text.trim().isEmpty) return;
    // Invalidate callbacks synchronously before awaiting any native work.
    stop();
    final id = LocalIdGenerator.nextUuidV4();
    _id = id;
    _errorVi = null;
    notifyListeners();
    _watchdog = Timer(startTimeout, () {
      if (_id != id) return;
      stop();
      _errorVi = 'Chưa phát được giọng đọc. Bạn có thể đọc nội dung bên dưới.';
      notifyListeners();
    });
    try {
      await _gateway.speak(id: id, text: text.trim());
    } catch (error) {
      if (_disposed || _id != id) return;
      stop();
      _errorVi = error is PersonalApiException
          ? error.messageVi
          : 'Chưa phát được giọng đọc. Nội dung vẫn ở bên dưới.';
      notifyListeners();
    }
  }

  void _onEvent(StudySpeechEvent event) {
    if (_disposed || !_allowed || event.id != _id) return;
    _watchdog?.cancel();
    _speaking = event.state == StudySpeechState.started;
    if (_speaking) {
      // Bound a stuck engine even if it never sends a terminal callback.
      final id = _id;
      _watchdog = Timer(const Duration(minutes: 3), () {
        if (_id == id) stop();
      });
    } else {
      _id = null;
      if (event.state == StudySpeechState.error) {
        _errorVi = event.messageVi ??
            'Giọng đọc bị gián đoạn. Bạn vẫn có thể đọc câu trả lời.';
      }
    }
    notifyListeners();
  }

  void stop() {
    _watchdog?.cancel();
    final wasBusy = isBusy;
    _id = null;
    _speaking = false;
    _errorVi = null;
    if (wasBusy) unawaited(_gateway.stop());
    if (!_disposed && wasBusy) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    unawaited(_subscription.cancel());
    _gateway.dispose();
    super.dispose();
  }
}
