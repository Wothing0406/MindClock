import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/remote_personal_flow_repository.dart';
import 'package:mindclock_app/data/services/firebase_auth_gateway.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/models/auth_session.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/mindclock_shell_screen.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';

class _DirectHttpOverrides extends HttpOverrides {}

class _NoopCameraGateway implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    return const CameraCaptureOutcome(
      status: CameraCaptureStatus.unavailable,
      messageVi: 'Test camera.',
    );
  }
}

void main() {
  test(
    'T076 TC-01: FirebaseAuthGateway fallback sang /v1/auth/* khi Firebase trả OPERATION_NOT_ALLOWED',
    () async {
      final HttpServer mockServer =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => mockServer.close(force: true));

      final List<String> pathsHit = <String>[];
      mockServer.listen((HttpRequest req) async {
        pathsHit.add('${req.method} ${req.uri.path}');
        final String raw = await utf8.decodeStream(req);
        final Map<String, dynamic> body = raw.trim().isNotEmpty
            ? jsonDecode(raw) as Map<String, dynamic>
            : <String, dynamic>{};

        if (req.uri.path.contains('accounts:signUp') ||
            req.uri.path.contains('accounts:signInWithPassword')) {
          req.response
            ..statusCode = 400
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(<String, dynamic>{
              'error': <String, dynamic>{
                'code': 400,
                'message': 'OPERATION_NOT_ALLOWED',
              },
            }));
          await req.response.close();
          return;
        }

        if (req.uri.path == '/v1/auth/register') {
          req.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(<String, dynamic>{
              'uid': 'loc_user_001',
              'email': body['email'],
              'idToken': 'hs256_access_1',
              'refreshToken': 'hs256_refresh_1',
              'emailVerified': true,
            }));
          await req.response.close();
          return;
        }

        if (req.uri.path == '/v1/auth/login') {
          if (body['password'] != 'StrongPass@99') {
            req.response
              ..statusCode = 401
              ..headers.contentType = ContentType.json
              ..write(jsonEncode(<String, dynamic>{
                'error': <String, dynamic>{
                  'code': 'INVALID_LOGIN_CREDENTIALS',
                  'message': 'Email hoặc mật khẩu chưa đúng.',
                },
              }));
            await req.response.close();
            return;
          }
          req.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(<String, dynamic>{
              'uid': 'loc_user_001',
              'email': body['email'],
              'idToken': 'hs256_access_2',
              'refreshToken': 'hs256_refresh_2',
              'emailVerified': true,
            }));
          await req.response.close();
          return;
        }

        if (req.uri.path == '/v1/auth/refresh') {
          req.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(<String, dynamic>{
              'uid': 'loc_user_001',
              'idToken': 'hs256_access_3',
              'refreshToken': 'hs256_refresh_3',
            }));
          await req.response.close();
          return;
        }

        req.response.statusCode = 404;
        await req.response.close();
      });

      final Uri base = Uri.parse('http://127.0.0.1:${mockServer.port}');
      final FirebaseAuthGateway gateway = FirebaseAuthGateway(
        store: InMemoryKeyValueStore(),
        firebaseWebApiKey: 'dummy-key',
        identityBaseUri: base.replace(path: '/identity'),
        secureTokenBaseUri: base.replace(path: '/secure'),
        backendBaseUri: base,
        httpClientFactory: () => HttpOverrides.runWithHttpOverrides(
          HttpClient.new,
          _DirectHttpOverrides(),
        ),
      );

      final AuthSession reg = await gateway.signUpWithEmail(
        email: 'hs@mindclock.vn',
        password: 'StrongPass@99',
      );
      expect(reg.isAuthenticated, isTrue);
      expect(reg.uid, 'loc_user_001');
      expect(reg.idToken, 'hs256_access_1');

      await expectLater(
        () => gateway.signInWithEmail(
          email: 'hs@mindclock.vn',
          password: 'WrongPassword@1',
        ),
        throwsA(isA<AuthException>()),
      );

      final AuthSession login = await gateway.signInWithEmail(
        email: 'hs@mindclock.vn',
        password: 'StrongPass@99',
      );
      expect(login.idToken, 'hs256_access_2');

      final AuthSession refreshed = await gateway.refreshIdToken();
      expect(refreshed.idToken, 'hs256_access_3');
      expect(pathsHit, contains('POST /v1/auth/register'));
      expect(pathsHit, contains('POST /v1/auth/login'));
      expect(pathsHit, contains('POST /v1/auth/refresh'));
    },
  );

  testWidgets(
    'T076 TC-02: TodayScreen hiển thị Danh mục 6 tính năng MVP rõ ràng, điều hướng 1 chạm ở 320dp chữ 200%',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final InMemoryKeyValueStore kv = InMemoryKeyValueStore();
      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: kv),
        alarmScheduler: const UnboundAlarmSchedulerService(),
      );
      await guestVm.initialize();
      await guestVm.completeOnboardingAsLater(alarmOnly: false);

      final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
        authGateway: DebugFixtureAuthGateway(),
        repository: DebugFixturePersonalFlowRepository(),
        draftStore: OfflineTextDraftStore(store: kv),
        cameraGateway: _NoopCameraGateway(),
      );
      await personalVm.initialize();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: MindClockTheme.buildThemeData(),
            home: MindClockShellScreen(
              viewModel: guestVm,
              personalViewModel: personalVm,
              communityRepository: DebugFixtureCommunityRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('today-feature-directory')),
        findsOneWidget,
      );
      for (final String tileKey in const <String>[
        'today-dir-alarm',
        'today-dir-practice',
        'today-dir-study',
        'today-dir-timetable',
        'today-dir-arena',
        'today-dir-profile',
      ]) {
        expect(find.byKey(ValueKey<String>(tileKey)), findsOneWidget);
      }

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('today-dir-arena')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('today-dir-arena')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('arena-hub-scroll')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('nav-today')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('today-dir-practice')),
      );
      await tester
          .tap(find.byKey(const ValueKey<String>('today-dir-practice')));
      await tester.pumpAndSettle();
      expect(find.text('Tiến độ học tập riêng tư'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'T076 TC-03: Sign-in Firebase EMAIL_NOT_FOUND fallback sang PostgreSQL & RemotePersonalFlowRepository.fetchProfileSnapshot khôi phục hồ sơ',
    () async {
      final HttpServer mockServer =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => mockServer.close(force: true));

      mockServer.listen((HttpRequest req) async {
        if (req.uri.path.contains('accounts:signInWithPassword')) {
          req.response
            ..statusCode = 400
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(<String, dynamic>{
              'error': <String, dynamic>{
                'code': 400,
                'message': 'EMAIL_NOT_FOUND',
              },
            }));
          await req.response.close();
          return;
        }
        if (req.uri.path == '/v1/auth/login') {
          req.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(<String, dynamic>{
              'uid': 'loc_returning_01',
              'email': 'cuong@mindclock.vn',
              'idToken': 'tok_ret_1',
              'refreshToken': 'ref_ret_1',
              'emailVerified': true,
            }));
          await req.response.close();
          return;
        }
        if (req.uri.path == '/v1/me' && req.method == 'GET') {
          req.response
            ..statusCode = 200
            ..headers.contentType = ContentType.json
            ..write(jsonEncode(<String, dynamic>{
              'id': 'u_ret_1',
              'alias': 'Minh Cuong 12A',
              'avatarId': 'avatar_ha_nhan',
              'gradeLevel': 'Lớp 12',
              'selectedSubjects': <String>['TOAN', 'VAT_LY'],
              'goalLabel': 'Đạt 9+ Lý',
            }));
          await req.response.close();
          return;
        }
        req.response.statusCode = 404;
        await req.response.close();
      });

      final Uri base = Uri.parse('http://127.0.0.1:${mockServer.port}');
      final FirebaseAuthGateway gateway = FirebaseAuthGateway(
        store: InMemoryKeyValueStore(),
        firebaseWebApiKey: 'dummy-key',
        identityBaseUri: base.replace(path: '/identity'),
        secureTokenBaseUri: base.replace(path: '/secure'),
        backendBaseUri: base,
        httpClientFactory: () => HttpOverrides.runWithHttpOverrides(
          HttpClient.new,
          _DirectHttpOverrides(),
        ),
      );
      final AuthSession session = await gateway.signInWithEmail(
        email: 'cuong@mindclock.vn',
        password: 'StrongPass@99',
      );
      expect(session.uid, 'loc_returning_01');
      expect(session.idToken, 'tok_ret_1');

      final RemotePersonalFlowRepository repo = RemotePersonalFlowRepository(
        apiClient: PersonalApiClient(
          baseUri: base,
          authGateway: gateway,
          httpClientFactory: () => HttpOverrides.runWithHttpOverrides(
            HttpClient.new,
            _DirectHttpOverrides(),
          ),
        ),
      );
      final StudyProfile? profile = await repo.fetchProfileSnapshot();
      expect(profile, isNotNull);
      expect(profile!.alias, 'Minh Cuong 12A');
      expect(profile.avatarId, 'ha_nhan');
      expect(profile.selectedSubjectCodes, <String>['math', 'physics']);
    },
  );
}
