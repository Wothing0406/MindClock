import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mindclock_app/data/services/method_channel_study_speech_gateway.dart';
import 'package:mindclock_app/domain/services/study_speech_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_speech_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/mindclock_ai_avatar.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'Gemini-generated WAV plays through Android and avatar follows playback',
      (tester) async {
    final sample = await rootBundle
        .load('assets/companions/mindclock-ai/voice-preview.wav');
    final gateway = MethodChannelStudySpeechGateway.withAudio(
        synthesize: (_) async => sample.buffer.asUint8List());
    final vm = StudySpeechViewModel(gateway: gateway);
    vm.configure(scope: 'voice-harness', allowed: true);
    final events = <StudySpeechEvent>[];
    final sub = gateway.events.listen(events.add);
    await tester.pumpWidget(MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: Scaffold(
            body: ListenableBuilder(
                listenable: vm,
                builder: (context, child) => Column(children: [
                      const Text('MindClock AI · Kiểm giọng Gemini'),
                      MindClockAiAnimatedAvatar(
                          isSpeaking: vm.isSpeaking, onLightBackground: true),
                      if (vm.errorVi != null) Text(vm.errorVi!),
                    ])))));
    final work = vm.readReply(
        'Mẫu giọng Gemini đã tạo; không phải câu trả lời từ phiên học.');
    bool sawSpeaking = false;
    for (var i = 0; i < 300 && (vm.isBusy || events.isEmpty); i++) {
      await tester.pump(const Duration(milliseconds: 100));
      sawSpeaking = sawSpeaking || vm.isSpeaking;
      if (vm.errorVi != null) break;
    }
    await work;
    expect(vm.errorVi, isNull);
    expect(sawSpeaking, isTrue);
    expect(events.any((e) => e.state == StudySpeechState.started), isTrue);
    expect(events.any((e) => e.state == StudySpeechState.done), isTrue);
    expect(vm.isSpeaking, isFalse);
    final cache =
        Directory('/data/data/com.mindclock.app/cache/mindclock_speech');
    expect(cache.existsSync(), isTrue);
    expect(cache.listSync(), isEmpty);
    binding.reportData = {
      'geminiSamplePlayed': true,
      'cacheEmptyAfterPlayback': true,
      'events': events.map((e) => e.state.name).toList()
    };
    debugPrint('T072_NATIVE_PLAYBACK: ${binding.reportData}');
    await sub.cancel();
    await tester.pumpWidget(const SizedBox.shrink());
    vm.dispose();
  });
}
