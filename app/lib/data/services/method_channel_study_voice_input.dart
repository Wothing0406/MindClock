import 'package:flutter/services.dart';
import '../../domain/services/study_speech_gateway.dart';

class MethodChannelStudyVoiceInput implements StudyVoiceInputGateway {
  const MethodChannelStudyVoiceInput();
  @override
  Future<String?> recognizeQuestion() =>
      const MethodChannel('mindclock/study_speech').invokeMethod<String>(
          'recognizeQuestion', const {'bridgeVersion': 1});
}
