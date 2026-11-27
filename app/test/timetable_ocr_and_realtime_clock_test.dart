import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mindclock_app/app.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/personal_api_client.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/media_picker_gateway.dart';

void main() {
  Future<void> scrollAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> signUpAndEnterToday(WidgetTester tester) async {
    await scrollAndTap(
      tester,
      find.byKey(const ValueKey<String>('welcome-auth-start')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('auth-email-input')),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-email-input')),
      'ocr@mindclock.vn',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('auth-password-input')),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-password-input')),
      'MindClock@2026',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('auth-confirm-password-input')),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('auth-confirm-password-input')),
      'MindClock@2026',
    );
    await scrollAndTap(
      tester,
      find.byKey(const ValueKey<String>('auth-consent-terms')),
    );
    await scrollAndTap(
      tester,
      find.byKey(const ValueKey<String>('auth-consent-age')),
    );
    await scrollAndTap(
      tester,
      find.byKey(const ValueKey<String>('auth-submit-btn')),
    );
    await scrollAndTap(
      tester,
      find.byKey(const ValueKey<String>('onboarding-skip-plan')),
    );
  }

  testWidgets(
    'TC-RTC-01: TodayScreen hiển thị đồng hồ thời gian thực và đếm ngược báo thức kế tiếp',
    (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      await tester.pumpWidget(
        MindClockApp(
          repository: GuestWorkspaceRepository(store: store),
          personalRepository: DebugFixturePersonalFlowRepository(),
          authGateway: DebugFixtureAuthGateway(),
          alarmScheduler: const UnboundAlarmSchedulerService(),
          mediaPickerGateway: const UnboundMediaPickerGateway(),
          enableStudyTicker: false,
        ),
      );
      await tester.pumpAndSettle();

      // Đăng ký để vào thẳng màn Hôm nay
      await signUpAndEnterToday(tester);

      // Kiểm tra widget đồng hồ thời gian thực xuất hiện
      expect(find.byKey(const ValueKey<String>('today-realtime-clock-hm')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('today-realtime-clock-sec')), findsOneWidget);
      expect(find.text('Thời gian thực'), findsOneWidget);

      // Tích tắc thời gian
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey<String>('today-realtime-clock-sec')), findsOneWidget);
    },
  );

  testWidgets(
    'TC-OCR-01: TimetableProfileScreen có nút quét ảnh AI và áp dụng bản nháp TKB',
    (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      await tester.pumpWidget(
        MindClockApp(
          repository: GuestWorkspaceRepository(store: store),
          personalRepository: DebugFixturePersonalFlowRepository(),
          authGateway: DebugFixtureAuthGateway(),
          alarmScheduler: const UnboundAlarmSchedulerService(),
          mediaPickerGateway: const UnboundMediaPickerGateway(),
          enableStudyTicker: false,
        ),
      );
      await tester.pumpAndSettle();

      // Đăng ký để vào màn Hôm nay
      await signUpAndEnterToday(tester);

      // Mở màn Sửa thời khóa biểu & hồ sơ
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('today-edit-timetable-profile')),
      );

      // Tìm nút quét ảnh AI
      final Finder scanBtn = find.byKey(const ValueKey<String>('scan-timetable-photo-ai'));
      expect(scanBtn, findsOneWidget);

      // Bấm nút quét ảnh AI
      await scrollAndTap(tester, scanBtn);

      // Bản nháp AI nhận diện xuất hiện
      expect(find.byKey(const ValueKey<String>('apply-ai-timetable-draft')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('cancel-ai-timetable-draft')), findsOneWidget);

      // Bấm xác nhận lưu bản nháp TKB
      await scrollAndTap(
        tester,
        find.byKey(const ValueKey<String>('apply-ai-timetable-draft')),
      );

      // Đã cập nhật thành công
      expect(find.textContaining('Đã cập nhật thời khóa biểu từ AI thành công'), findsOneWidget);
    },
  );

  test(
    'TC-OCR-02 (T050): PersonalApiClient.parseTimetableImage gửi đúng POST /v1/timetable/parse-image (không bị /v1/v1/)',
    () async {
      final HttpServer server =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);

      final List<String> recordedPaths = <String>[];
      server.listen((HttpRequest req) async {
        recordedPaths.add('${req.method} ${req.uri.path}');
        req.response.statusCode = HttpStatus.ok;
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode(<String, dynamic>{'days': <dynamic>[]}));
        await req.response.close();
      });

      final DebugFixtureAuthGateway auth = DebugFixtureAuthGateway();
      await auth.signInWithEmail(email: 'student@school.edu.vn', password: 'Password123');
      final PersonalApiClient client = PersonalApiClient(
        baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
        authGateway: auth,
        httpClientFactory: () =>
            HttpOverrides.runWithHttpOverrides(HttpClient.new, _PassthroughHttpOverrides()),
      );

      await client.parseTimetableImage(imageBase64: 'ZmFrZV9pbWFnZQ==');
      expect(recordedPaths, <String>['POST /v1/timetable/parse-image']);
    },
  );
}

class _PassthroughHttpOverrides extends HttpOverrides {}
