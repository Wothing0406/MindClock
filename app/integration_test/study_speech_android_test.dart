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
      'Android TTS native contract, actual callback or explicit unavailable fallback',
      (tester) async {
    final gateway = MethodChannelStudySpeechGateway();
    final vm = StudySpeechViewModel(gateway: gateway);
    vm.configure(scope: 'integration-test', allowed: true);
    final events = <StudySpeechEvent>[];
    final sub = gateway.events.listen(events.add);
    await tester.pumpWidget(MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      home: Scaffold(
          body: ListenableBuilder(
              listenable: vm,
              builder: (context, _) => Column(children: [
                    MindClockAiAnimatedAvatar(
                        isSpeaking: vm.isSpeaking, onLightBackground: true),
                    const Text('Kiểm thử giọng đọc Android'),
                    if (vm.errorVi != null) Text(vm.errorVi!),
                  ]))),
    ));
    final read = vm.readReply('Bạn hãy thử trình bày bước đầu tiên.');
    // pump real time, so native initialization/engine callbacks can finish.
    for (var i = 0; i < 200 && (vm.isBusy || events.isEmpty); i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (vm.errorVi != null) break;
    }
    await read;
    final started = events.any((e) => e.state == StudySpeechState.started);
    expect(started || vm.errorVi != null, isTrue);
    binding.reportData = <String, dynamic>{
      'nativePlaybackStarted': started,
      'explicitFallback': vm.errorVi != null,
      'eventStates': events.map((e) => e.state.name).toList(),
      'noMicrophoneUsed': true,
    };
    debugPrint('T071_NATIVE_OUTCOME: ${binding.reportData}');
    vm.stop();
    await tester.pump(const Duration(milliseconds: 300));
    expect(vm.isSpeaking, isFalse);
    expect(vm.isBusy, isFalse);
    await sub.cancel();
    await tester.pumpWidget(const SizedBox.shrink());
    vm.dispose();
  });

  testWidgets('native bridge rejects unsupported version', (tester) async {
    const channel = MethodChannel('mindclock/study_speech');
    await expectLater(
        channel.invokeMethod<void>(
            'speak', {'bridgeVersion': 99, 'id': 'x', 'text': 'Test'}),
        throwsA(
            isA<PlatformException>().having((e) => e.code, 'code', 'VERSION')));
  });
}
