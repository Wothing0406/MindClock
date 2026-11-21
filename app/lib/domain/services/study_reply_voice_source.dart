import 'dart:typed_data';

abstract interface class StudyReplyVoiceSource {
  Future<Uint8List> synthesizeReply(
      {required String sessionId, required String text});
}
