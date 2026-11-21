import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/repositories/remote_study_ai_gateway.dart';
import 'package:mindclock_app/data/services/local_id_generator.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/method_channel_study_speech_gateway.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/auth_session.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/domain/services/study_speech_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/mindclock_ai_avatar.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

/// Test-only dev principal; deliberately NOT a Firebase login E2E test.
class _DevAuth extends DebugFixtureAuthGateway {
  _DevAuth(this.uid);
  final String uid;
  @override
  Future<AuthSession> loadSavedSession() async => AuthSession(
      status: AuthStatus.authenticated,
      uid: uid,
      idToken: 'dev:$uid',
      isDebugFixture: true);
  @override
  Future<AuthSession> refreshIdToken() => loadSavedSession();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'real API question → Gemini reply → consent → cloud WAV → Android avatar',
      (tester) async {
    final auth = _DevAuth('voice_network_${LocalIdGenerator.nextUuidV4()}');
    final api = PersonalApiClient(
        baseUri: Uri.parse('http://10.0.2.2:8000'),
        authGateway: auth,
        requestTimeout: const Duration(seconds: 50));
    final store = InMemoryKeyValueStore();
    final guest = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService());
    await guest.initialize();
    final vm = StudyFocusViewModel(
        repository: LocalStudyFocusRepository(store: store),
        bridge: const UnboundStudyFocusBridge(),
        aiGateway: RemoteStudyAiGateway(apiClient: api),
        enablePeriodicTicker: false);
    final gateway = MethodChannelStudySpeechGateway.withAudio(
        synthesize: vm.createReplyVoice);
    final events = <StudySpeechEvent>[];
    final sub = gateway.events.listen(events.add);
    bool cleanup = false;
    try {
      await api.getJson('/me');
      await vm.initialize(ownerScopeKey: 'user:${auth.uid}');
      await vm.setAccountAuthenticated(true, gradeLevel: 'Lớp 10');
      await vm.startSession(
          overrideTaskTitle: 'Ôn phương trình', overrideSubjectCode: 'TOAN');
      expect(
          await vm.requestAiHelp(
              questionText:
                  'Em nên bắt đầu từ đâu với phương trình 2x + 3 = 7?'),
          isTrue);
      await tester.pumpWidget(MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: StudySpaceScreen(
              guestViewModel: guest,
              studyViewModel: vm,
              speechGateway: gateway,
              onClose: () {})));
      await tester.pumpAndSettle();
      final read = find.byKey(const ValueKey('study-ai-read-1'));
      await tester.ensureVisible(read);
      await tester.tap(read);
      await tester.pumpAndSettle();
      expect(events, isEmpty);
      await tester
          .tap(find.byKey(const ValueKey('study-voice-consent-accept')));
      bool sawSpeaking = false;
      for (var i = 0; i < 900; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        sawSpeaking = sawSpeaking ||
            tester
                .widget<MindClockAiAnimatedAvatar>(
                    find.byType(MindClockAiAnimatedAvatar))
                .isSpeaking;
        if (events.any((e) =>
                e.state == StudySpeechState.done ||
                e.state == StudySpeechState.error) ||
            find
                .byKey(const ValueKey('study-ai-speech-error'))
                .evaluate()
                .isNotEmpty) {
          break;
        }
      }
      expect(find.byKey(const ValueKey('study-ai-speech-error')), findsNothing);
      expect(sawSpeaking, isTrue);
      expect(
          events.map((e) => e.state),
          containsAllInOrder(
              [StudySpeechState.started, StudySpeechState.done]));
      expect(
          tester
              .widget<MindClockAiAnimatedAvatar>(
                  find.byType(MindClockAiAnimatedAvatar))
              .isSpeaking,
          isFalse);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await sub.cancel();
      gateway.dispose();
      vm.dispose();
      guest.dispose();
      await api.deleteNoContent('/me');
      cleanup = true;
    }
    binding.reportData = {
      'realBackendAndGemini': true,
      'nativeEvents': events.map((e) => e.state.name).toList(),
      'authMode': 'development test principal; not Firebase login',
      'testAccountDeleted': cleanup
    };
    debugPrint('T072_NETWORK_PLAYBACK: ${binding.reportData}');
  });
}
