import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/auth_session.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/auth_session_gateway.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/mindclock_shell_screen.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';

class _NoopCameraGateway implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    return const CameraCaptureOutcome(
      status: CameraCaptureStatus.unavailable,
      messageVi: 'Chưa dùng camera',
    );
  }
}

class _ConfigNotFoundAuthGateway implements AuthSessionGateway {
  @override
  bool get isDebugFixture => false;

  @override
  Future<AuthSession> loadSavedSession() async => const AuthSession.guest();

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    throw const AuthException(
      code: 'CONFIGURATION_NOT_FOUND',
      messageVi:
          'Firebase Auth chưa bật tính năng Email/Password. Vui lòng bật tại Firebase Console (Authentication > Sign-in method).',
    );
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw const AuthException(
      code: 'CONFIGURATION_NOT_FOUND',
      messageVi:
          'Firebase Auth chưa bật tính năng Email/Password. Vui lòng bật tại Firebase Console (Authentication > Sign-in method).',
    );
  }

  @override
  Future<AuthSession> refreshIdToken() async => const AuthSession.guest();

  @override
  Future<AuthSession> markSessionExpired({String? messageVi}) async =>
      const AuthSession.guest();

  @override
  Future<void> signOut() async {}
}

Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.4,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollAndEnter(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await Scrollable.ensureVisible(
    tester.element(finder),
    alignment: 0.3,
    duration: Duration.zero,
  );
  await tester.pumpAndSettle();
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

void main() {
  group('R2 Auth & Onboarding Flow (ON-01..ON-06)', () {
    testWidgets(
      'TC-01 (ON-01): WelcomeScreen hiện khung Giải thích quyền và không tràn ở 320dp 200%',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 760);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await guestVm.initialize();

        final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
          authGateway: DebugFixtureAuthGateway(),
          repository: DebugFixturePersonalFlowRepository(),
          draftStore: OfflineTextDraftStore(store: store),
          cameraGateway: _NoopCameraGateway(),
        );
        await personalVm.initialize();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 760),
              textScaler: TextScaler.linear(2.0),
              disableAnimations: true,
            ),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: MindClockShellScreen(
                viewModel: guestVm,
                personalViewModel: personalVm,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey<String>('welcome-permission-guide')),
          findsOneWidget,
        );
        expect(find.textContaining('Giải thích quyền'), findsOneWidget);
        expect(
          find.byKey(const ValueKey<String>('welcome-auth-start')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey<String>('guest-alarm-only')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'TC-02 & TC-04 (ON-02, ON-04, ON-05): Validation form đăng ký + happy path email bất kỳ -> Onboarding THPT -> Hôm nay',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await guestVm.initialize();

        final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
          authGateway: DebugFixtureAuthGateway(),
          repository: DebugFixturePersonalFlowRepository(),
          draftStore: OfflineTextDraftStore(store: store),
          cameraGateway: _NoopCameraGateway(),
        );
        await personalVm.initialize();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: MindClockShellScreen(
                viewModel: guestVm,
                personalViewModel: personalVm,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('welcome-auth-start')),
        );

        // 1. Email không hợp lệ
        await _scrollAndEnter(
          tester,
          find.byKey(const ValueKey<String>('auth-email-input')),
          'khong-phai-email',
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-submit-btn')),
        );
        expect(find.textContaining('email hợp lệ'), findsOneWidget);

        // 2. Email ngoài Gmail hợp lệ nhưng xác nhận mật khẩu lệch
        await _scrollAndEnter(
          tester,
          find.byKey(const ValueKey<String>('auth-alias-input')),
          'Minh Khang',
        );
        await _scrollAndEnter(
          tester,
          find.byKey(const ValueKey<String>('auth-email-input')),
          'khang@school.edu.vn',
        );
        await _scrollAndEnter(
          tester,
          find.byKey(const ValueKey<String>('auth-password-input')),
          'MatKhau123',
        );
        await _scrollAndEnter(
          tester,
          find.byKey(const ValueKey<String>('auth-confirm-password-input')),
          'KhacMatKhau',
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-submit-btn')),
        );
        expect(find.textContaining('không khớp'), findsOneWidget);

        // 3. Khớp mật khẩu nhưng chưa tích điều khoản
        await _scrollAndEnter(
          tester,
          find.byKey(const ValueKey<String>('auth-confirm-password-input')),
          'MatKhau123',
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-submit-btn')),
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('auth-error-banner')),
            matching: find.textContaining('điều khoản'),
          ),
          findsOneWidget,
        );

        // 4. Tích điều khoản nhưng chưa tích xác nhận độ tuổi
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-consent-terms')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-submit-btn')),
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey<String>('auth-error-banner')),
            matching: find.textContaining('THPT'),
          ),
          findsOneWidget,
        );

        // 5. Tích độ tuổi -> Đăng ký thành công -> Onboarding THPT -> Hôm nay
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-consent-age')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-submit-btn')),
        );

        expect(personalVm.authSession.isAuthenticated, isTrue);
        expect(find.byKey(const ValueKey<String>('grade-Lớp 11')), findsOneWidget);

        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('grade-Lớp 11')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('subject-math')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('onboarding-save')),
        );

        expect(find.byKey(const ValueKey<String>('nav-today')), findsOneWidget);
        expect(guestVm.profile.alias, 'Minh Khang');
        expect(guestVm.profile.gradeLevel, 'Lớp 11');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'TC-03 (ON-01, ON-03): Lỗi CONFIGURATION_NOT_FOUND không tạo tài khoản giả và cho vào Chỉ dùng báo thức trên máy',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await guestVm.initialize();

        final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
          authGateway: _ConfigNotFoundAuthGateway(),
          repository: DebugFixturePersonalFlowRepository(),
          draftStore: OfflineTextDraftStore(store: store),
          cameraGateway: _NoopCameraGateway(),
        );
        await personalVm.initialize();

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: MaterialApp(
              theme: MindClockTheme.buildThemeData(),
              home: MindClockShellScreen(
                viewModel: guestVm,
                personalViewModel: personalVm,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('welcome-auth-start')),
        );
        await _scrollAndEnter(
          tester,
          find.byKey(const ValueKey<String>('auth-email-input')),
          'student@example.edu.vn',
        );
        await _scrollAndEnter(
          tester,
          find.byKey(const ValueKey<String>('auth-password-input')),
          'Secret123',
        );
        await _scrollAndEnter(
          tester,
          find.byKey(const ValueKey<String>('auth-confirm-password-input')),
          'Secret123',
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-consent-terms')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-consent-age')),
        );
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-submit-btn')),
        );

        expect(personalVm.authSession.isAuthenticated, isFalse);
        expect(find.textContaining('Firebase Console'), findsOneWidget);

        // Chuyển sang đường dự phòng Chỉ dùng báo thức trên máy
        await _scrollAndTap(
          tester,
          find.byKey(const ValueKey<String>('auth-offline-alarm-fallback')),
        );
        expect(
          find.byKey(const ValueKey<String>('save-alarm-config')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    test(
      'TC-05 (ON-06): Đổi tài khoản A -> B cô lập hồ sơ riêng nhưng vẫn giữ báo thức local trên máy',
      () async {
        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceViewModel vm = GuestWorkspaceViewModel(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await vm.initialize();

        // Tài khoản A đăng nhập, lưu hồ sơ riêng và tạo báo thức local
        await vm.setAccountContext(
          ownerScopeKey: 'user_a',
          isAuthenticated: true,
        );
        await vm.saveStudyProfile(
          const StudyProfile(
            alias: 'Học sinh A',
            gradeLevel: 'Lớp 12',
            goalLabel: 'Ôn thi đại học khối A',
            selectedSubjectCodes: <String>['math', 'physics'],
          ),
        );
        await vm.saveAlarm(
          const AlarmConfig(
            id: 'alarm-shared-local',
            label: 'Chuông sáng chung trên máy',
            hour: 6,
            minute: 0,
            enabled: true,
            mode: AlarmMode.challenge,
          ),
        );
        expect(vm.profile.alias, 'Học sinh A');
        expect(vm.alarms.any((AlarmConfig a) => a.id == 'alarm-shared-local'), isTrue);

        // Đăng xuất -> chuyển sang tài khoản B
        await vm.setAccountContext(
          ownerScopeKey: 'user_b',
          isAuthenticated: true,
        );

        // Hồ sơ/TKB của A không được rò sang B
        expect(vm.profile.alias, isNot('Học sinh A'));
        expect(vm.profile.goalLabel, isNot('Ôn thi đại học khối A'));
        // Báo thức local trên máy vẫn tồn tại và chỉnh sửa được
        expect(vm.alarms.any((AlarmConfig a) => a.id == 'alarm-shared-local'), isTrue);
      },
    );
  });
}
