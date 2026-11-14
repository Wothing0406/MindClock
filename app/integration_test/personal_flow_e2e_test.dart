import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mindclock_app/app.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/remote_personal_flow_repository.dart';
import 'package:mindclock_app/data/services/firebase_auth_gateway.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';

import '../test/support/loopback_v1_contract_server.dart';

class _TestCameraGateway implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    return CameraCaptureOutcome(
      status: CameraCaptureStatus.captured,
      bytes: Uint8List.fromList(<int>[0xFF, 0xD8, 0xFF, 0xE0, 10, 20, 30]),
      mimeType: 'image/jpeg',
      fileName: 'e2e_handwritten.jpg',
    );
  }
}

/// Kiểm thử hành trình đầu-cuối theo hướng dẫn `integration_test` hiện hành
/// (`IntegrationTestWidgetsFlutterBinding.ensureInitialized()`, KHÔNG bật
/// `enableFlutterDriverExtension()` hay `flutter_driver`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Luồng cá nhân đầy đủ trên UI: đăng nhập -> câu hỏi -> nộp bài -> XP server -> đăng xuất cô lập & giữ báo thức',
    (WidgetTester tester) async {
      final LoopbackV1ContractServer server =
          await LoopbackV1ContractServer.start();
      addTearDown(server.close);

      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final FirebaseAuthGateway authGateway = FirebaseAuthGateway(
        store: store,
        firebaseWebApiKey: 'e2e-test-key',
        identityBaseUri: server.identityBaseUri,
        secureTokenBaseUri: server.secureTokenBaseUri,
      );
      final RemotePersonalFlowRepository personalRepo =
          RemotePersonalFlowRepository(
        apiClient: PersonalApiClient(
          baseUri: server.baseUri,
          authGateway: authGateway,
        ),
      );

      await tester.pumpWidget(
        MindClockApp(
          repository: GuestWorkspaceRepository(store: store),
          alarmScheduler: const UnboundAlarmSchedulerService(),
          authGateway: authGateway,
          personalRepository: personalRepo,
          cameraGateway: _TestCameraGateway(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Vào từ màn chào mừng -> Chỉ báo thức -> Lưu báo thức local 06:00
      await tester.tap(find.byKey(const ValueKey<String>('guest-alarm-only')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('save-alarm-config')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('save-alarm-config')));
      await tester.pumpAndSettle();

      expect(find.text('06:00'), findsWidgets);

      // 2. Sang tab Luyện tập, đăng nhập User A
      await tester.tap(find.byKey(const ValueKey<String>('nav-practice')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-email-field')),
        'usera@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-password-field')),
        'password123',
      );
      await tester.tap(find.byKey(const ValueKey<String>('auth-submit-button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('auth-logged-in-email')),
          findsOneWidget);

      // 3. Tải câu hỏi, nhập đáp án + trình bày đúng -> Server cấp +10 XP
      await tester.tap(find.byKey(const ValueKey<String>('practice-start-normal')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey<String>('practice-question-prompt')),
          findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey<String>('practice-answer-field')),
        '8',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('practice-reasoning-field')),
        '2x - 6 = 10 suy ra 2x = 16 nen x = 8',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('practice-submit-text')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('practice-submit-text')));
      await tester.pumpAndSettle();

      expect(find.text('XP server cấp: +10 XP'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('progress-server-xp')),
        findsOneWidget,
      );

      // 4. Đăng xuất User A -> đăng nhập User B -> XP không rò rỉ và báo thức vẫn còn ở tab Hôm nay
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('auth-sign-out-button')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('auth-sign-out-button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-email-field')),
        'userb@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey<String>('auth-password-field')),
        'password123',
      );
      await tester.tap(find.byKey(const ValueKey<String>('auth-submit-button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('0 XP'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey<String>('nav-today')));
      await tester.pumpAndSettle();
      expect(find.text('06:00'), findsWidgets);
    },
  );
}
