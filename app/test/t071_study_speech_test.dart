import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_study_ai_gateway.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/method_channel_study_speech_gateway.dart';
import 'package:mindclock_app/domain/models/study_focus_models.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/domain/services/study_speech_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_speech_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/mindclock_ai_avatar.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

class _Speech implements StudySpeechGateway {
  final bus = StreamController<StudySpeechEvent>.broadcast(sync: true);
  final ids = <String>[];
  int stops = 0;
  Completer<void>? pending;
  bool fail = false;
  @override
  Stream<StudySpeechEvent> get events => bus.stream;
  @override
  Future<void> speak({required String id, required String text}) async {
    ids.add(id);
    if (fail) throw StateError('No engine');
    if (pending != null) await pending!.future;
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  void dispose() {
    unawaited(bus.close());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'queued is not speaking; started/done from current engine id are authoritative',
      () async {
    final gateway = _Speech();
    final vm = StudySpeechViewModel(gateway: gateway);
    vm.configure(scope: 'A/session1', allowed: true);
    expect(gateway.ids, isEmpty);
    await vm.readReply('Một gợi ý');
    expect(vm.isBusy, isTrue);
    expect(vm.isSpeaking, isFalse);
    gateway.bus.add(const StudySpeechEvent('old', StudySpeechState.started));
    expect(vm.isSpeaking, isFalse);
    gateway.bus
        .add(StudySpeechEvent(gateway.ids.last, StudySpeechState.started));
    expect(vm.isSpeaking, isTrue);
    gateway.bus.add(StudySpeechEvent(gateway.ids.last, StudySpeechState.done));
    expect(vm.isSpeaking, isFalse);
    expect(vm.isBusy, isFalse);
    vm.dispose();
  });

  test(
      'stop while initialization pending prevents stale start and late failure',
      () async {
    final gateway = _Speech()..pending = Completer<void>();
    final vm = StudySpeechViewModel(gateway: gateway);
    vm.configure(scope: 'A/session1', allowed: true);
    final pending = vm.readReply('Một gợi ý');
    vm.stop();
    gateway.bus
        .add(StudySpeechEvent(gateway.ids.last, StudySpeechState.started));
    gateway.pending!.completeError(StateError('cancelled'));
    await pending;
    expect(vm.isBusy, isFalse);
    expect(vm.isSpeaking, isFalse);
    expect(vm.errorVi, isNull);
    vm.dispose();
  });

  test(
      'account/session/background change invalidates callbacks; forbidden read is ignored',
      () async {
    final gateway = _Speech();
    final vm = StudySpeechViewModel(gateway: gateway);
    vm.configure(scope: 'A/session1', allowed: true);
    await vm.readReply('Riêng tư A');
    final old = gateway.ids.last;
    vm.configure(scope: 'B/session2', allowed: true);
    gateway.bus.add(StudySpeechEvent(old, StudySpeechState.started));
    expect(vm.isSpeaking, isFalse);
    vm.configure(scope: 'B/session2', allowed: false);
    await vm.readReply('Không được đọc');
    expect(gateway.ids.length, 1);
    vm.dispose();
  });

  test('engine error resets mouth and allows explicit retry', () async {
    final gateway = _Speech()..fail = true;
    final vm = StudySpeechViewModel(gateway: gateway);
    vm.configure(scope: 'A', allowed: true);
    await vm.readReply('Gợi ý');
    expect(vm.errorVi, isNotNull);
    expect(vm.isBusy, isFalse);
    gateway.fail = false;
    await vm.readReply('Gợi ý');
    gateway.bus.add(StudySpeechEvent(gateway.ids.last, StudySpeechState.error));
    expect(vm.isSpeaking, isFalse);
    expect(vm.errorVi, isNotNull);
    vm.dispose();
  });

  testWidgets('initialization timeout stops playback and cannot later animate',
      (tester) async {
    final gateway = _Speech()..pending = Completer<void>();
    final vm = StudySpeechViewModel(gateway: gateway);
    vm.configure(scope: 'A', allowed: true);
    final pending = vm.readReply('Gợi ý');
    await tester.pump(const Duration(seconds: 16));
    expect(vm.isBusy, isFalse);
    expect(vm.errorVi, isNotNull);
    gateway.bus
        .add(StudySpeechEvent(gateway.ids.last, StudySpeechState.started));
    expect(vm.isSpeaking, isFalse);
    gateway.pending!.complete();
    await pending;
    vm.dispose();
  });

  test(
      'bridge versioned payload and event parsing; missing plugin remains an error',
      () async {
    const channel = MethodChannel('test/mindclock/speech');
    final binding =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <MethodCall>[];
    binding.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final gateway = MethodChannelStudySpeechGateway(channel: channel);
    final events = <StudySpeechEvent>[];
    final sub = gateway.events.listen(events.add);
    await gateway.speak(id: 'u1', text: 'Một bước');
    expect(calls.last.arguments,
        {'bridgeVersion': 1, 'id': 'u1', 'text': 'Một bước'});
    final data = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('speechState', {'id': 'u1', 'state': 'started'}));
    await binding.handlePlatformMessage(channel.name, data, (ByteData? _) {});
    await Future<void>.delayed(Duration.zero);
    expect(events.single.state, StudySpeechState.started);
    await gateway.stop();
    expect(calls.last.method, 'stop');
    await sub.cancel();
    gateway.dispose();
    binding.setMockMethodCallHandler(channel, null);
    final missing = MethodChannelStudySpeechGateway(channel: channel);
    await expectLater(missing.speak(id: 'u2', text: 'Một bước'),
        throwsA(isA<MissingPluginException>()));
    missing.dispose();
  });

  for (final deep in <bool>[false, true]) {
    testWidgets('screen explicit read and lifecycle; deep=$deep',
        (tester) async {
      final store = InMemoryKeyValueStore();
      final guest = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService());
      await guest.initialize();
      final vm = StudyFocusViewModel(
          repository: LocalStudyFocusRepository(store: store),
          bridge: const UnboundStudyFocusBridge(),
          aiGateway: const DebugFixtureStudyAiGateway(),
          enablePeriodicTicker: false);
      await vm.initialize(ownerScopeKey: 'user:A');
      await vm.setAccountAuthenticated(true);
      vm.setCadence(deep ? StudyCadence.deepSilent : StudyCadence.interval);
      await vm.startSession(overrideTaskTitle: 'Ôn Toán');
      await vm.requestAiHelp(questionText: 'Bắt đầu từ đâu?');
      final gateway = _Speech();
      await tester.pumpWidget(MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: StudySpaceScreen(
              guestViewModel: guest,
              studyViewModel: vm,
              speechGateway: gateway,
              onClose: () {})));
      await tester.pumpAndSettle();
      final read = find.byKey(const ValueKey('study-ai-read-1'));
      expect(gateway.ids, isEmpty);
      if (deep) {
        expect(read, findsNothing);
      } else {
        await tester.ensureVisible(read);
        await tester.tap(read);
        await tester.pump();
        expect(gateway.ids.length, 1);
        expect(
            tester
                .widget<MindClockAiAnimatedAvatar>(
                    find.byType(MindClockAiAnimatedAvatar))
                .isSpeaking,
            isFalse);
        gateway.bus
            .add(StudySpeechEvent(gateway.ids.last, StudySpeechState.started));
        await tester.pump();
        expect(
            tester
                .widget<MindClockAiAnimatedAvatar>(
                    find.byType(MindClockAiAnimatedAvatar))
                .isSpeaking,
            isTrue);
        final stopsBeforeBackground = gateway.stops;
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        expect(gateway.stops, greaterThan(stopsBeforeBackground));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
        expect(
            tester
                .widget<MindClockAiAnimatedAvatar>(
                    find.byType(MindClockAiAnimatedAvatar))
                .isSpeaking,
            isFalse);
        expect(gateway.ids.length, 1); // Never auto-resumes.
        await vm.setAccountAuthenticated(false);
        await tester.pump();
        expect(read, findsNothing);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      vm.dispose();
      guest.dispose();
    });
  }
}
