import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_study_ai_gateway.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/repositories/remote_study_ai_gateway.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/method_channel_study_speech_gateway.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/domain/services/study_reply_voice_source.dart';
import 'package:mindclock_app/domain/services/study_speech_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

class _CloudAi extends DebugFixtureStudyAiGateway
    implements StudyReplyVoiceSource {
  int calls = 0;
  @override
  Future<Uint8List> synthesizeReply(
      {required String sessionId, required String text}) async {
    calls++;
    return Uint8List.fromList(
        [1]); // Native channel is separately mocked in this widget test.
  }
}

class _Client extends PersonalApiClient {
  _Client()
      : super(
            baseUri: Uri.parse('http://localhost'),
            authGateway: DebugFixtureAuthGateway());
  String? route;
  Map<String, dynamic>? payload;
  Duration? capturedTimeout;
  Map<String, dynamic> response = {};
  @override
  Future<Map<String, dynamic>> postJson(String path,
      {required Map<String, dynamic> body,
      required String idempotencyKey,
      Duration? timeout}) async {
    route = path;
    payload = body;
    capturedTimeout = timeout;
    expect(idempotencyKey, matches(RegExp(r'^[a-f0-9-]{36}$')));
    return response;
  }
}

class _VoiceInput implements StudyVoiceInputGateway {
  int calls = 0;
  @override
  Future<String?> recognizeQuestion() async {
    calls++;
    return 'Mình chưa hiểu bước đặt ẩn.';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('remote voice payload is authenticated API request, valid WAV only',
      () async {
    final client = _Client();
    final raw = Uint8List(50)
      ..setRange(0, 4, ascii.encode('RIFF'))
      ..setRange(8, 12, ascii.encode('WAVE'));
    client.response = {
      'mimeType': 'audio/wav',
      'audioBase64': base64Encode(raw)
    };
    final source = RemoteStudyAiGateway(apiClient: client);
    expect(await source.synthesizeReply(sessionId: 's1', text: 'Gợi ý'), raw);
    expect(client.route, '/study/sessions/s1/speech');
    expect(client.payload, {'text': 'Gợi ý', 'consentGranted': true});
    expect(client.capturedTimeout, const Duration(seconds: 50));
    client.response = {
      'mimeType': 'audio/wav',
      'audioBase64': base64Encode([1, 2, 3])
    };
    await expectLater(source.synthesizeReply(sessionId: 's1', text: 'Gợi ý'),
        throwsA(isA<PersonalApiException>()));
  });

  test('stop/dispose while cloud is pending discards late audio', () async {
    final binding =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('test/cloud-voice');
    final calls = <MethodCall>[];
    binding.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    for (final dispose in [false, true]) {
      final result = Completer<Uint8List>();
      final gateway = MethodChannelStudySpeechGateway.withAudio(
          channel: channel, synthesize: (_) => result.future);
      final work = gateway.speak(id: 'one', text: 'Gợi ý');
      if (dispose) {
        gateway.dispose();
      } else {
        await gateway.stop();
      }
      result.complete(Uint8List(50));
      await work;
      expect(calls.where((c) => c.method == 'playWav'), isEmpty);
      gateway.dispose();
    }
    binding.setMockMethodCallHandler(channel, null);
  });

  test('ready cloud audio goes to real native playback method, not TTS speak',
      () async {
    final binding =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('test/ready-voice');
    final calls = <MethodCall>[];
    binding.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final audio = Uint8List.fromList([1, 2, 3]);
    final gateway = MethodChannelStudySpeechGateway.withAudio(
        channel: channel, synthesize: (_) async => audio);
    await gateway.speak(id: 'two', text: 'Gợi ý');
    expect(calls.single.method, 'playWav');
    expect((calls.single.arguments as Map)['wav'], audio);
    await gateway.stop();
    gateway.dispose();
    binding.setMockMethodCallHandler(channel, null);
  });

  testWidgets(
      'consent cancel never sends text; accept triggers cloud voice once',
      (tester) async {
    final store = InMemoryKeyValueStore();
    final guest = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService());
    await guest.initialize();
    final ai = _CloudAi();
    final voiceInput = _VoiceInput();
    final vm = StudyFocusViewModel(
        repository: LocalStudyFocusRepository(store: store),
        bridge: const UnboundStudyFocusBridge(),
        aiGateway: ai,
        enablePeriodicTicker: false);
    await vm.initialize(ownerScopeKey: 'user:A');
    await vm.setAccountAuthenticated(true);
    await vm.startSession(overrideTaskTitle: 'Ôn Toán');
    await vm.requestAiHelp(questionText: 'Bắt đầu từ đâu?');
    final binding =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const channel = MethodChannel('mindclock/study_speech');
    binding.setMockMethodCallHandler(channel, (_) async => null);
    await tester.pumpWidget(MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: StudySpaceScreen(
            guestViewModel: guest,
            studyViewModel: vm,
            voiceInputGateway: voiceInput,
            onClose: () {})));
    await tester.pumpAndSettle();
    final read = find.byKey(const ValueKey('study-ai-read-1'));
    await tester.ensureVisible(read);
    await tester.tap(read);
    await tester.pumpAndSettle();
    expect(ai.calls, 0);
    await tester.tap(find.byKey(const ValueKey('study-voice-consent-cancel')));
    await tester.pumpAndSettle();
    expect(ai.calls, 0);
    final mic = find.byKey(const ValueKey('study-ai-voice-input'));
    await tester.ensureVisible(mic);
    await tester.tap(mic);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('study-mic-consent-cancel')));
    await tester.pumpAndSettle();
    expect(voiceInput.calls, 0);
    await tester.tap(mic);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('study-mic-consent-accept')));
    await tester.pumpAndSettle();
    expect(voiceInput.calls, 1);
    expect(
        tester
            .widget<TextField>(
                find.byKey(const ValueKey('study-ai-question-input')))
            .controller!
            .text,
        'Mình chưa hiểu bước đặt ẩn.');
    expect(vm.aiTurns.length, 2);
    await tester.ensureVisible(read);
    await tester.tap(read);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('study-voice-consent-accept')));
    await tester.pump();
    expect(ai.calls, 1);
    await tester.tap(read);
    await tester.pump(); // stop the queued audio request
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    vm.dispose();
    guest.dispose();
    binding.setMockMethodCallHandler(channel, null);
  });
}
