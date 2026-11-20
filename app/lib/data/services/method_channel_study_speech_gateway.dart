import 'dart:async';

import 'package:flutter/services.dart';

import '../../domain/services/study_speech_gateway.dart';

class MethodChannelStudySpeechGateway implements StudySpeechGateway {
  MethodChannelStudySpeechGateway({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('mindclock/study_speech') {
    _channel.setMethodCallHandler(_onEvent);
  }

  final MethodChannel _channel;
  final _events = StreamController<StudySpeechEvent>.broadcast();
  bool _disposed = false;
  bool _hasRequest = false;

  @override
  Stream<StudySpeechEvent> get events => _events.stream;

  Future<void> _onEvent(MethodCall call) async {
    if (_disposed || call.method != 'speechState') return;
    final raw = call.arguments;
    if (raw is! Map || raw['id'] is! String) return;
    final state = switch (raw['state']) {
      'started' => StudySpeechState.started,
      'done' => StudySpeechState.done,
      'stopped' => StudySpeechState.stopped,
      'error' => StudySpeechState.error,
      _ => null,
    };
    if (state == null) return;
    _events.add(StudySpeechEvent(raw['id'] as String, state,
        messageVi: raw['messageVi'] as String?));
  }

  @override
  Future<void> speak({required String id, required String text}) async {
    if (_disposed) throw StateError('Speech gateway disposed');
    _hasRequest = true;
    await _channel.invokeMethod<void>('speak', <String, Object>{
      'bridgeVersion': 1,
      'id': id,
      'text': text,
    }).timeout(const Duration(seconds: 15));
  }

  @override
  Future<void> stop() async {
    if (!_hasRequest) return;
    _hasRequest = false;
    try {
      await _channel.invokeMethod<void>('stop',
          const {'bridgeVersion': 1}).timeout(const Duration(seconds: 2));
    } catch (_) {
      // Native lifecycle independently stops speech if the channel is lost.
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(stop());
    _channel.setMethodCallHandler(null);
    unawaited(_events.close());
  }
}
