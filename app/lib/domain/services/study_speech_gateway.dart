import 'dart:async';

enum StudySpeechState { started, done, stopped, error }

class StudySpeechEvent {
  const StudySpeechEvent(this.id, this.state, {this.messageVi});
  final String id;
  final StudySpeechState state;
  final String? messageVi;
}

/// Reads a user-selected reply. No microphone, recording or automatic playback.
abstract interface class StudySpeechGateway {
  Stream<StudySpeechEvent> get events;
  Future<void> speak({required String id, required String text});
  Future<void> stop();
  void dispose();
}
