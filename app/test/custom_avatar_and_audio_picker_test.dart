import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/media_picker_gateway.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/alarm_config_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/me_guest_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/onboarding_setup_screen.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

class _FakeMediaPickerGateway implements MediaPickerGateway {
  MediaPickResult nextAvatarResult = const MediaPickResult.cancelled();
  MediaPickResult nextAudioResult = const MediaPickResult.cancelled();
  bool previewShouldSucceed = true;
  int previewCalls = 0;
  int stopPreviewCalls = 0;
  String? lastPreviewSoundOption;
  String? lastPreviewCustomPath;
  bool? lastPreviewLoop;

  @override
  Future<MediaPickResult> pickAvatarImage() async => nextAvatarResult;

  @override
  Future<MediaPickResult> pickAlarmAudio() async => nextAudioResult;

  @override
  Future<bool> previewAudio({
    required String soundOption,
    String? customSoundPath,
    bool loop = false,
  }) async {
    previewCalls += 1;
    lastPreviewSoundOption = soundOption;
    lastPreviewCustomPath = customSoundPath;
    lastPreviewLoop = loop;
    return previewShouldSucceed;
  }

  @override
  Future<void> stopAudioPreview() async {
    stopPreviewCalls += 1;
  }
}

class _NoopStudyFocusBridge implements StudyFocusBridge {
  @override
  bool get isPlatformConnected => false;

  @override
  Future<void> cancelStudyReminder() async {}

  @override
  Future<StudyNotificationPermission> getNotificationPermissionStatus() async =>
      StudyNotificationPermission.unknown;

  @override
  Future<DigitalWellbeingOpenResult> openDigitalWellbeingFocusSettings() async {
    return const DigitalWellbeingOpenResult(
      opened: false,
      target: DigitalWellbeingTarget.unavailable,
      messageVi: 'Không hỗ trợ trên môi trường test.',
    );
  }

  @override
  Future<void> playSessionEndCue() async {}

  @override
  Future<StudyNotificationPermission> requestNotificationPermission() async =>
      StudyNotificationPermission.denied;

  @override
  Future<void> showSingleStudyReminder({
    required String sessionId,
    required String titleVi,
    required String bodyVi,
  }) async {}
}

Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.4,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('T055 Avatar assets, custom photo & custom alarm/study audio', () {
    test('avatar_sunrise.png loads cleanly & StudyProfile/AlarmConfig serialize custom media',
        () async {
      final ByteData avatarBytes =
          await rootBundle.load('assets/avatars/avatar_sunrise.png');
      expect(avatarBytes.lengthInBytes, greaterThan(1000));

      const StudyProfile profile = StudyProfile(
        alias: 'Minh Khang',
        avatarId: 'ha_nhan',
        customAvatarPath: '/data/user/0/com.mindclock.app/files/avatars/me.png',
      );
      final StudyProfile roundTrip = StudyProfile.fromJson(profile.toJson());
      expect(roundTrip.avatarId, 'ha_nhan');
      expect(
        roundTrip.customAvatarPath,
        '/data/user/0/com.mindclock.app/files/avatars/me.png',
      );
      expect(roundTrip.copyWith(clearCustomAvatarPath: true).customAvatarPath, isNull);

      const AlarmConfig alarm = AlarmConfig(
        id: 'alarm_custom',
        hour: 6,
        minute: 15,
        soundOption: AlarmSoundOption.customLocal,
        customSoundPath: '/data/user/0/com.mindclock.app/files/sounds/lofi.mp3',
        customSoundLabel: 'lofi.mp3',
      );
      final AlarmConfig alarmRoundTrip = AlarmConfig.fromJson(alarm.toJson());
      expect(alarmRoundTrip.soundOption, AlarmSoundOption.customLocal);
      expect(
        alarmRoundTrip.customSoundPath,
        '/data/user/0/com.mindclock.app/files/sounds/lofi.mp3',
      );
      expect(alarmRoundTrip.customSoundLabel, 'lofi.mp3');
      expect(
        alarmRoundTrip.copyWith(clearCustomSound: true).customSoundPath,
        isNull,
      );
    });

    testWidgets(
        'TC-01: OnboardingSetupScreen & MeGuestScreen support illustrated presets and custom device avatar',
        (WidgetTester tester) async {
      final Directory tempDir = Directory.systemTemp.createTempSync('mc_avatar_');
      addTearDown(() {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });
      final File dummyPng = File('${tempDir.path}/picked_avatar.png');
      final ByteData? sampleBytes = await tester.runAsync(
        () => rootBundle.load('assets/avatars/avatar_sunrise.png'),
      );
      expect(sampleBytes, isNotNull);
      dummyPng.writeAsBytesSync(sampleBytes!.buffer.asUint8List());

      final _FakeMediaPickerGateway picker = _FakeMediaPickerGateway()
        ..nextAvatarResult = MediaPickResult(
          picked: true,
          localPath: dummyPng.path,
          displayName: 'picked_avatar.png',
        );

      StudyProfile? savedProfile;
      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: OnboardingSetupScreen(
              initialProfile: const StudyProfile(
                alias: 'Mai Anh',
                gradeLevel: 'Lớp 11',
                selectedSubjectCodes: <String>['math'],
              ),
              mediaPickerGateway: picker,
              onSaveProfile: (StudyProfile p) => savedProfile = p,
              onSkipLater: () {},
              onAlarmOnly: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollAndTap(tester, find.byKey(const ValueKey<String>('avatar-ha_nhan')));
      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('pick-custom-avatar-btn')),
      );
      expect(
        find.byKey(const ValueKey<String>('clear-custom-avatar-btn')),
        findsOneWidget,
      );
      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('onboarding-save')),
      );
      expect(savedProfile, isNotNull);
      expect(savedProfile!.avatarId, 'ha_nhan');
      expect(savedProfile!.customAvatarPath, dummyPng.path);

      final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: InMemoryKeyValueStore()),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await vm.initialize();
      await vm.saveStudyProfile(savedProfile!);

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: MeGuestScreen(
              viewModel: vm,
              mediaPickerGateway: picker,
              onEditProfileAndTimetable: () {},
              onResetGuestData: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('me-clear-avatar-btn')),
      );
      expect(vm.profile.customAvatarPath, isNull);

      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('me-pick-avatar-btn')),
      );
      expect(vm.profile.customAvatarPath, dummyPng.path);
    });

    testWidgets(
        'TC-02: AlarmConfigScreen picks custom audio, previews cleanly, and persists customSoundPath',
        (WidgetTester tester) async {
      final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: InMemoryKeyValueStore()),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await vm.initialize();

      final _FakeMediaPickerGateway picker = _FakeMediaPickerGateway()
        ..nextAudioResult = const MediaPickResult(
          picked: true,
          localPath: '/data/user/0/com.mindclock.app/files/sounds/morning.mp3',
          displayName: 'morning.mp3',
        );

      String? savedBanner;
      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: AlarmConfigScreen(
            viewModel: vm,
            mediaPickerGateway: picker,
            onSaved: (String msg) => savedBanner = msg,
            onCancel: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('sound-custom_local')),
      );
      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('pick-custom-alarm-audio-btn')),
      );
      expect(find.textContaining('morning.mp3'), findsWidgets);

      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('preview-alarm-audio-btn')),
      );
      expect(picker.previewCalls, 1);
      expect(picker.lastPreviewSoundOption, 'custom_local');
      expect(
        picker.lastPreviewCustomPath,
        '/data/user/0/com.mindclock.app/files/sounds/morning.mp3',
      );
      expect(picker.lastPreviewLoop, isFalse);

      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('save-alarm-config')),
      );
      expect(savedBanner, isNotNull);
      expect(vm.alarms.length, 1);
      expect(vm.alarms.first.soundOption, AlarmSoundOption.customLocal);
      expect(
        vm.alarms.first.customSoundPath,
        '/data/user/0/com.mindclock.app/files/sounds/morning.mp3',
      );
      expect(vm.alarms.first.customSoundLabel, 'morning.mp3');
      expect(picker.stopPreviewCalls, greaterThanOrEqualTo(1));
    });

    testWidgets(
        'StudySpaceScreen stops & locks ambient device audio when switched to Học sâu',
        (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();

      final StudyFocusViewModel studyVm = StudyFocusViewModel(
        repository: LocalStudyFocusRepository(store: store),
        bridge: _NoopStudyFocusBridge(),
        enablePeriodicTicker: false,
      );
      await studyVm.initialize();

      final _FakeMediaPickerGateway picker = _FakeMediaPickerGateway()
        ..nextAudioResult = const MediaPickResult(
          picked: true,
          localPath: '/data/user/0/com.mindclock.app/files/sounds/focus_rain.mp3',
          displayName: 'focus_rain.mp3',
        );

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: StudySpaceScreen(
              guestViewModel: guestVm,
              studyViewModel: studyVm,
              mediaPickerGateway: picker,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('study-pick-ambient-audio-btn')),
      );
      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('study-toggle-ambient-audio-btn')),
      );
      expect(picker.previewCalls, 1);
      expect(picker.lastPreviewLoop, isTrue);

      await _scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('study-cadence-deep')),
      );
      expect(picker.stopPreviewCalls, greaterThanOrEqualTo(1));
      expect(
        find.textContaining('Đang khóa im lặng hoàn toàn theo chế độ Học sâu'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('study-pick-ambient-audio-btn')),
        findsNothing,
      );
    });
  });
}
