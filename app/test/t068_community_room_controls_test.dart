import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_community_repository.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/repositories/local_study_focus_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/study_focus_bridge.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/me_guest_screen.dart';
import 'package:mindclock_app/ui/features/study_focus/view_models/study_focus_view_model.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_space_screen.dart';
import 'package:mindclock_app/domain/models/community_models.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/core/widgets/mindclock_cards.dart';
import 'package:mindclock_app/ui/features/study_focus/views/study_community_sheet.dart';

class _TrackingRepo extends DebugFixtureCommunityRepository {
  int? capacity;
  String? joinedCode;
  String? lastSubject;
  String? lastGrade;
  @override
  Future<List<PublicStudyRoomSummary>> listPublicRooms(
      {String? gradeLevel, String? subjectCode}) {
    lastSubject = subjectCode;
    lastGrade = gradeLevel;
    return super
        .listPublicRooms(gradeLevel: gradeLevel, subjectCode: subjectCode);
  }

  @override
  Future<StudyRoomDetail> createRoom(
      {required String title,
      required String subjectCode,
      required String gradeLevel,
      String targetLevel = 'basic',
      String visibility = 'public',
      int maxMembers = 4,
      bool aiCompanionEnabled = true}) {
    capacity = maxMembers;
    return super.createRoom(
        title: title,
        subjectCode: subjectCode,
        gradeLevel: gradeLevel,
        targetLevel: targetLevel,
        visibility: visibility,
        maxMembers: maxMembers,
        aiCompanionEnabled: aiCompanionEnabled);
  }

  @override
  Future<StudyRoomDetail> joinRoom(String roomId,
      {String? roomCode,
      bool micEnabled = false,
      bool camEnabled = false,
      String statusNote = 'Đang tập trung'}) {
    joinedCode = roomCode;
    return super.joinRoom(roomId,
        roomCode: roomCode,
        micEnabled: micEnabled,
        camEnabled: camEnabled,
        statusNote: statusNote);
  }
}

Future<void> _open(WidgetTester tester, _TrackingRepo repo) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
              disableAnimations: true, textScaler: const TextScaler.linear(2)),
          child: child!),
      home: Builder(
          builder: (context) => Scaffold(
              body: TextButton(
                  onPressed: () => showStudyCommunityHub(
                      context: context,
                      repository: repo,
                      currentProfile: const StudyProfile(
                          gradeLevel: 'Lớp 11',
                          selectedSubjectCodes: ['math'])),
                  child: const Text('Mở'))))));
  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey<String>(key));
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('bộ lọc môn/lớp được gửi server, chỉ còn chỗ ẩn phòng đầy',
      (tester) async {
    final repo = _TrackingRepo();
    await _open(tester, repo);
    await _tap(tester, 'community-filter-subject-math');
    await _tap(tester, 'community-filter-grade-Lớp 11');
    expect(repo.lastSubject, 'math');
    expect(repo.lastGrade, 'Lớp 11');
    await tester.pumpWidget(const SizedBox.shrink());
    await _open(tester, _FullRepo());
    await _tap(tester, 'community-filter-available');
    expect(find.text('Phòng đã đầy'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'vào phòng từ tab Tôi trả detail để hiển thị phòng học, không bỏ kết quả',
      (tester) async {
    final store = InMemoryKeyValueStore();
    final guest = GuestWorkspaceViewModel(
        repository: GuestWorkspaceRepository(store: store),
        alarmScheduler: const UnboundAlarmSchedulerService());
    await guest.initialize();
    addTearDown(guest.dispose);
    final study = StudyFocusViewModel(
        repository: LocalStudyFocusRepository(store: store),
        bridge: const UnboundStudyFocusBridge(),
        enablePeriodicTicker: false);
    await study.initialize(ownerScopeKey: 'test');
    addTearDown(study.dispose);
    final repo = _TrackingRepo();
    StudyRoomDetail? joined;
    await tester.pumpWidget(MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!),
        home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
                body: joined == null
                    ? MeGuestScreen(
                        viewModel: guest,
                        communityRepository: repo,
                        onEditProfileAndTimetable: () {},
                        onResetGuestData: () {},
                        onRoomJoined: (room) => setState(() => joined = room))
                    : StudySpaceScreen(
                        guestViewModel: guest,
                        studyViewModel: study,
                        communityRepository: repo,
                        initialRoom: joined,
                        onClose: () {})))));
    await _tap(tester, 'me-open-community-hub');
    await _tap(tester, 'community-join-room_toan_11');
    expect(joined?.summary.roomId, 'room_toan_11');
    expect(find.byKey(const ValueKey('meet-study-room-panel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lời mời đã gửi có thể hủy trên giao diện', (tester) async {
    final repo = _TrackingRepo();
    await repo.sendFriendRequest('peer_quang_huy');
    final requests = await repo.fetchFriendRequests();
    final id = requests.outgoing.first.requestId;
    await _open(tester, repo);
    await _tap(tester, 'community-tab-friends');
    expect(find.text('Lời mời bạn đã gửi'), findsOneWidget);
    await _tap(tester, 'community-cancel-$id');
    expect((await repo.fetchFriendRequests()).outgoing, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('host chọn 2 chỗ thay hardcode 6, form không tràn 320dp 200%',
      (tester) async {
    final repo = _TrackingRepo();
    await _open(tester, repo);
    await _tap(tester, 'community-create-room-toggle');
    final fields = find.byType(TextField);
    // Code input comes before room title.
    await tester.ensureVisible(fields.last);
    await tester.enterText(fields.last, 'Nhóm ôn 11');
    await _tap(tester, 'community-capacity-2');
    await _tap(tester, 'community-create-room-submit');
    expect(repo.capacity, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mã phòng được chuẩn hóa và truyền đầy đủ tới repository',
      (tester) async {
    final repo = _TrackingRepo();
    await _open(tester, repo);
    await tester.enterText(
        find.byKey(const ValueKey('community-room-code')), ' mc101 ');
    FocusManager.instance.primaryFocus?.unfocus();
    await _tap(tester, 'community-join-code');
    expect(repo.joinedCode, 'MC101');
    expect(tester.takeException(), isNull);
  });

  testWidgets('phòng đầy không cho bấm vào', (tester) async {
    await _open(tester, _FullRepo());
    expect(find.text('Phòng đã đầy'), findsWidgets);
    final button = tester.widget<MindClockButton>(
        find.byKey(const ValueKey('community-join-full')));
    expect(button.onPressed, isNull);
  });
}

class _FullRepo extends _TrackingRepo {
  @override
  Future<List<PublicStudyRoomSummary>> listPublicRooms(
          {String? gradeLevel, String? subjectCode}) async =>
      [
        PublicStudyRoomSummary.fromJson({
          'roomId': 'full',
          'title': 'Đã đủ người',
          'maxMembers': 2,
          'memberCount': 2
        }),
      ];
}
