import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/core/widgets/mindclock_cards.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_community_sheet.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';

void main() {
  testWidgets(
    'T058 Gói B: Quét phòng Meet công khai, AI ghép nhóm, Hồ sơ công khai, Kết bạn & Avatar AI 2D không tràn ở 320dp 200%',
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
      await guestVm.saveStudyProfile(
        const StudyProfile(
          alias: 'Minh Khang',
          gradeLevel: 'Lớp 11',
          selectedSubjectCodes: <String>['math', 'physics'],
          goalLabel: 'Ôn thi khối A',
        ),
      );

      final StudyFocusViewModel studyVm = StudyFocusViewModel(
        repository: LocalStudyFocusRepository(store: store),
        bridge: const UnboundStudyFocusBridge(),
        enablePeriodicTicker: false,
      );
      await studyVm.initialize(ownerScopeKey: 'user_khang');

      final DebugFixtureCommunityRepository communityRepo =
          DebugFixtureCommunityRepository();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(2.0),
            disableAnimations: true,
          ),
          child: MaterialApp(
            theme: MindClockTheme.buildThemeData(),
            home: StudySpaceScreen(
              guestViewModel: guestVm,
              studyViewModel: studyVm,
              communityRepository: communityRepo,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Chọn nhánh Học cùng bạn -> Mở sảnh phòng học cùng bạn
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('study-mode-friends')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('study-mode-friends')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('study-open-community-hub')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('study-open-community-hub')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('study-community-hub-sheet')),
        findsOneWidget,
      );

      // 2. Bấm AI ghép nhóm theo trình độ
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('community-ai-match-btn')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('community-ai-match-btn')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('community-ai-match-heading')),
        findsOneWidget,
      );

      // 3. Chuyển sang tab Tìm bạn & Kết bạn -> Mở hồ sơ công khai -> Gửi kết bạn
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('community-tab-friends')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('community-tab-friends')),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('community-profile-peer_quang_huy')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('community-profile-peer_quang_huy')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
            const ValueKey<String>('public-profile-sheet-peer_quang_huy')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('profile-add-friend-peer_quang_huy')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('profile-add-friend-peer_quang_huy')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đã gửi lời mời kết bạn'), findsOneWidget);
      Navigator.of(
        tester.element(find.byKey(
            const ValueKey<String>('public-profile-sheet-peer_quang_huy'))),
      ).pop();
      await tester.pumpAndSettle();

      // 4. Quay lại tab Phòng công khai -> Vào phòng Meet -> Thấy lưới thành viên & MindClock AI 2D
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('community-tab-rooms')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('community-tab-rooms')),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('community-join-room_toan_11')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('community-join-room_toan_11')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('meet-study-room-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('meet-tile-mindclock-ai')),
        findsOneWidget,
      );
      expect(
        find.byType(MindClockAiAnimatedAvatar),
        findsOneWidget,
      );

      // REST metadata does not prove live media. Unsupported controls stay disabled.
      expect(find.text('Mic chưa khả dụng'), findsOneWidget);
      expect(find.text('Camera chưa khả dụng'), findsOneWidget);
      expect(
          tester
              .widget<MindClockButton>(
                  find.byKey(const ValueKey('meet-toggle-mic')))
              .onPressed,
          isNull);
      expect(
          tester
              .widget<MindClockButton>(
                  find.byKey(const ValueKey('meet-toggle-cam')))
              .onPressed,
          isNull);

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('meet-leave-room')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('meet-leave-room')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('meet-study-room-panel')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
