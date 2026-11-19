import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/debug/debug_fixture_auth_gateway.dart';
import 'package:mindclock_app/data/debug/debug_fixture_personal_flow_repository.dart';
import 'package:mindclock_app/data/debug/debug_fixture_pvp_gateway.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/data/services/offline_text_draft_store.dart';
import 'package:mindclock_app/domain/game/solo_training_question_bank.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/guest_workspace.dart';
import 'package:mindclock_app/domain/models/personal_flow_models.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/models/subject_catalog.dart';
import 'package:mindclock_app/domain/models/timetable.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/domain/services/camera_capture_gateway.dart';
import 'package:mindclock_app/domain/services/morning_question_selector.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/arena/view_models/pvp_arena_view_model.dart';
import 'package:mindclock_app/ui/features/arena/view_models/solo_arena_view_model.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_pvp_lobby.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/ui/features/guest_shell/views/mindclock_shell_screen.dart';
import 'package:mindclock_app/ui/features/personal_flow/view_models/personal_flow_view_model.dart';

class _NoopCameraGateway implements CameraCaptureGateway {
  @override
  Future<CameraCaptureOutcome> captureHandwrittenPhoto() async {
    return const CameraCaptureOutcome(status: CameraCaptureStatus.cancelled);
  }
}

class _RingingAlarmScheduler extends UnboundAlarmSchedulerService {
  const _RingingAlarmScheduler(this._ringPayload);

  final AlarmRingPayload _ringPayload;

  @override
  Future<AlarmRingPayload?> consumePendingRingLaunch() async => _ringPayload;
}

void main() {
  test(
    'T062 TC-01: MorningQuestionSelector bỏ qua tiết activity (Chào cờ/SHL) để chọn môn chính khóa',
    () {
      expect(SubjectCatalog.nameFor('activity'), 'Sinh hoạt / HĐTN');
      expect(
        SubjectCatalog.nameFor('civic_econ'),
        'Giáo dục kinh tế và pháp luật',
      );

      final WeeklyTimetable tkb = WeeklyTimetable(
        days: <DaySchedule>[
          const DaySchedule(
            weekday: 1,
            isRestDay: false,
            entries: <TimetableEntry>[
              TimetableEntry(id: 's1', subjectCode: 'activity', startMinutes: 420),
              TimetableEntry(id: 's2', subjectCode: 'chemistry', startMinutes: 470),
              TimetableEntry(id: 's3', subjectCode: 'math', startMinutes: 520),
            ],
          ),
        ],
      );
      const StudyProfile profile = StudyProfile(
        gradeLevel: 'Lớp 12',
        selectedSubjectCodes: <String>['math', 'chemistry', 'physics'],
      );
      const AlarmConfig alarm = AlarmConfig(
        id: 'primary_morning',
        hour: 6,
        minute: 0,
        mode: AlarmMode.challenge,
        subjectRule: AlarmSubjectRule.todaySchedule,
      );

      final MorningQuestionProposal proposal =
          MorningQuestionSelector.resolveForAlarm(
        alarm: alarm,
        profile: profile,
        timetable: tkb,
        weekday: 1,
      );
      expect(proposal.subjectCode, 'chemistry');
      expect(proposal.explanationVi, contains('Hóa học'));
    },
  );

  test(
    'T062 TC-03/04: Offline bank có sẵn đáp án & xoay vòng đa môn; Online ai_regen nạp câu mới từ đề gốc',
    () async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final PersonalFlowViewModel vm = PersonalFlowViewModel(
        authGateway: DebugFixtureAuthGateway(),
        repository: DebugFixturePersonalFlowRepository(),
        cameraGateway: _NoopCameraGateway(),
        draftStore: OfflineTextDraftStore(store: store),
      );
      await vm.initialize();

      // 1. Khi mất mạng / chưa login: mở môn Hóa học -> lấy câu Hóa học & chấm đáp án có sẵn trên máy
      await vm.startSession(
        subjectCode: 'chemistry',
        gradeLevel: 'Lớp 12',
        challengeMode: true,
      );
      final String firstPrompt = vm.currentQuestion!.prompt;
      expect(vm.currentQuestion!.subjectCode, 'chemistry');
      expect(vm.currentQuestion!.questionId, 'g1-chem-001');

      final GradingResult? res = vm.checkOfflineBankAnswer(
        answerValue: '88',
        reasoningText: 'M(C4H8O2) = 4*12 + 8 + 32 = 88',
      );
      expect(res, isNotNull);
      expect(res!.verdict, GradingVerdict.correct);
      expect(res.xpAwarded, 0);
      expect(res.isServerAuthoritative, isFalse);
      expect(res.revealVi, contains('88'));

      // 2. Mở phiên kế tiếp cùng môn khi offline -> xoay vòng sang câu khác, không lặp lại 1 câu
      await vm.startSession(
        subjectCode: 'chemistry',
        challengeMode: false,
      );
      expect(vm.currentQuestion!.questionId, isNot('g1-chem-001'));
      expect(vm.currentQuestion!.prompt, isNot(firstPrompt));

      // 3. Khi đã đăng nhập & gọi preferAiRegen: nạp câu biến thể AI bám đề gốc vào phiên
      final bool signedUp = await vm.signUp(
        email: 'hocsinh12@mindclock.vn',
        password: 'MindClock@2026',
      );
      expect(signedUp, isTrue);
      await vm.startSession(
        subjectCode: 'math',
        preferAiRegen: true,
      );
      expect(vm.currentQuestion!.questionId, 'fixture-ai-regen-002');
      expect(vm.currentQuestion!.prompt, contains('3(x - 2) = 15'));
    },
  );

  testWidgets(
    'T062 TC-05: Đấu trường Solo đếm ngược thời gian chọn (30s), tự chuyển khi hết giờ, nạp câu liên tục & PvP countdown không có nhãn demo',
    (WidgetTester tester) async {
      final SoloArenaViewModel soloVm = SoloArenaViewModel(
        enableRoundTimer: false,
      );
      soloVm.setContinuousQuestionProvider(({
        required String subjectCode,
        required String seedQuestionId,
        required int roundNo,
      }) async {
        return SoloApprovedQuestion(
          id: 'ai_arena_round_$roundNo',
          revision: 1,
          rubricRevision: 1,
          subjectCode: subjectCode,
          gradeBand: 'Lớp 12',
          curriculum: 'gdpt_2018',
          approvedBy: 'ai_regen',
          prompt:
              'Câu nạp liên tục AI round $roundNo (từ $seedQuestionId): Tìm x khi 2x = 12.',
          reasoningPromptVi: 'Chia cả hai vế cho 2.',
          acceptedAnswers: const <String>['6', 'x=6'],
          reasoningKeywords: const <String>['chia', '6'],
          oneStepHintVi: 'x = 12 / 2.',
          gradingRubricStepsVi: const <String>['x = 6'],
          explanationAfterRevealVi: 'x = 6.',
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: ArenaScreen(
              guestViewModel: GuestWorkspaceViewModel(
                repository: GuestWorkspaceRepository(store: InMemoryKeyValueStore()),
                alarmScheduler: const UnboundAlarmSchedulerService(),
              ),
              arenaViewModel: soloVm,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vào setup Luyện đơn & chọn thời gian 30s/lượt
      soloVm.openSoloSetup();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-timer-30')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('arena-timer-30')));
      await tester.pumpAndSettle();
      expect(soloVm.noTimeLimit, isFalse);
      expect(soloVm.roundTimeLimitSeconds, 30);

      soloVm.startSoloMatch(showLoadingScreen: true);
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('arena-enter-battle-now')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('arena-enter-battle-now')),
      );
      await tester.pumpAndSettle();

      // Đồng hồ round hiện đúng 30s
      expect(
        find.byKey(const ValueKey<String>('arena-round-countdown')),
        findsOneWidget,
      );
      expect(find.text('Thời gian còn: 30s'), findsOneWidget);

      // Kích hoạt hết giờ -> sang trạng thái uncertain an toàn & đổi câu liên tục (nhận câu AI vừa nạp)
      final String firstArenaQ = soloVm.currentQuestion!.id;
      soloVm.triggerRoundTimeout();
      await tester.pumpAndSettle();
      expect(soloVm.phase, SoloBattlePhase.gradedUncertain);
      soloVm.swapQuestionOnUncertain();
      await tester.pumpAndSettle();
      expect(soloVm.phase, SoloBattlePhase.answering);
      expect(soloVm.currentQuestion!.id, isNot(firstArenaQ));

      // Kiểm tra PvP Lobby: đếm ngược deadlineAtIso & sạch chữ Demo/Mẫu PvP
      final PvpArenaViewModel pvpVm = PvpArenaViewModel(
        gateway: DebugFixturePvpGateway(),
        enableAutoPolling: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: Scaffold(
            body: ArenaPvpLobby(
              viewModel: pvpVm,
              profile: const StudyProfile(
                gradeLevel: 'Lớp 12',
                selectedSubjectCodes: <String>['math'],
              ),
              userId: 'debug_user_a',
              onBackToHub: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Demo'), findsNothing);
      expect(find.textContaining('Mẫu PvP'), findsNothing);
      expect(find.text('Đấu tập offline · 0 RP'), findsOneWidget);

      // Ghép trận (lần 1 queue -> pollOnce ra trận) -> thấy countdown Còn ...s
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('pvp-find-match-btn')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('pvp-find-match-btn')));
      await tester.pumpAndSettle();
      await pvpVm.pollOnce();
      await tester.pumpAndSettle();
      expect(pvpVm.stage, PvpUiStage.inMatch);
      expect(
        find.byKey(const ValueKey<String>('pvp-round-countdown')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'T062 TC-06/07: Báo thức tới giờ reo không có subjectCode tự phân giải môn TKB + không còn nhãn Demo/Thử phiên',
    (WidgetTester tester) async {
      final InMemoryKeyValueStore store = InMemoryKeyValueStore();
      final GuestWorkspaceRepository repo = GuestWorkspaceRepository(store: store);
      final int todayWeekday = DateTime.now().weekday;
      await repo.save(
        GuestWorkspace(
          onboardingCompleted: true,
          profile: const StudyProfile(
            alias: 'Minh Anh',
            gradeLevel: 'Lớp 12',
            selectedSubjectCodes: <String>['physics', 'math'],
          ),
          timetable: WeeklyTimetable(
            days: <DaySchedule>[
              DaySchedule(
                weekday: todayWeekday,
                isRestDay: false,
                entries: const <TimetableEntry>[
                  TimetableEntry(
                    id: 'e1',
                    subjectCode: 'activity',
                    startMinutes: 420,
                  ),
                  TimetableEntry(
                    id: 'e2',
                    subjectCode: 'physics',
                    startMinutes: 470,
                  ),
                ],
              ),
            ],
          ),
          alarms: const <AlarmConfig>[
            AlarmConfig(
              id: 'primary_morning',
              hour: 6,
              minute: 0,
              mode: AlarmMode.challenge,
              subjectRule: AlarmSubjectRule.todaySchedule,
            ),
          ],
        ),
      );

      final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
        repository: repo,
        alarmScheduler: const _RingingAlarmScheduler(
          AlarmRingPayload(
            alarmId: 'primary_morning',
            formattedTime: '06:00',
            mode: AlarmMode.challenge,
            label: 'Báo thức buổi sáng',
            subjectCode: null,
          ),
        ),
      );
      await guestVm.initialize();

      final PersonalFlowViewModel personalVm = PersonalFlowViewModel(
        authGateway: DebugFixtureAuthGateway(),
        repository: DebugFixturePersonalFlowRepository(),
        cameraGateway: _NoopCameraGateway(),
        draftStore: OfflineTextDraftStore(store: store),
      );
      await personalVm.initialize();

      await tester.pumpWidget(
        MaterialApp(
          theme: MindClockTheme.buildThemeData(),
          home: MindClockShellScreen(
            viewModel: guestVm,
            personalViewModel: personalVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Đang ở màn chuông báo thức reo đúng giờ -> bấm Mở câu hỏi
      expect(find.byKey(const ValueKey<String>('ring-open-question')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('ring-open-question')));
      await tester.pumpAndSettle();

      // Mở tab Luyện tập với câu hỏi Vật lí đúng TKB (sau khi bỏ qua Chào cờ)
      expect(personalVm.currentQuestion, isNotNull);
      expect(personalVm.currentQuestion!.subjectCode, 'physics');
      // Không còn nhãn Thử phiên báo thức thử thách hay Demo trên UI
      expect(find.text('Thử phiên báo thức thử thách'), findsNothing);
      expect(find.textContaining('Demo'), findsNothing);
      expect(find.text('Mở câu thử thách buổi sáng'), findsOneWidget);
    },
  );
}
