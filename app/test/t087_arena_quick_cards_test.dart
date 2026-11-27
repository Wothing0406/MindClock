import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/domain/game/solo_combat_engine.dart';
import 'package:mindclock_app/domain/game/solo_training_question_bank.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/features/arena/view_models/solo_arena_view_model.dart';
import 'package:mindclock_app/ui/features/arena/views/arena_screen.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';

void main() {
  test('T087 quickChoicesFor sinh 4 thẻ không trùng và đúng khớp đề', () {
    for (final SoloApprovedQuestion q
        in SoloTrainingQuestionBank.allCachedApprovedQuestions.take(6)) {
      final List<SoloQuickChoice> choices =
          SoloTrainingQuestionBank.quickChoicesFor(q);
      expect(choices.length, 4);
      expect(
        choices.any(
          (SoloQuickChoice c) =>
              gradeSoloTrainingSubmission(
                question: q,
                answerText: c.answerValue,
                reasoningText: c.reasoningStep,
              ).status ==
              SoloGradeStatus.correct,
        ),
        isTrue,
      );
    }
  });

  testWidgets('T087 ArenaScreen hỗ trợ chọn nhanh 1 chạm thẻ đáp án để mở chiêu',
      (WidgetTester tester) async {
    final GuestWorkspaceViewModel guestVm = GuestWorkspaceViewModel(
      repository: GuestWorkspaceRepository(store: InMemoryKeyValueStore()),
      alarmScheduler: const UnboundAlarmSchedulerService(),
    );
    await guestVm.initialize();

    final SoloArenaViewModel arenaVm =
        SoloArenaViewModel(enableRoundTimer: false);
    arenaVm.startSoloMatch();

    await tester.pumpWidget(
      MaterialApp(
        theme: MindClockTheme.buildThemeData(),
        home: Scaffold(
          body: ArenaScreen(
            arenaViewModel: arenaVm,
            guestViewModel: guestVm,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final SoloApprovedQuestion q = arenaVm.currentQuestion!;
    final List<SoloQuickChoice> choices =
        SoloTrainingQuestionBank.quickChoicesFor(q);
    final int correctIdx = choices.indexWhere(
      (SoloQuickChoice c) =>
          gradeSoloTrainingSubmission(
            question: q,
            answerText: c.answerValue,
            reasoningText: c.reasoningStep,
          ).status ==
          SoloGradeStatus.correct,
    );
    expect(correctIdx, greaterThanOrEqualTo(0));

    final Finder quickBtn =
        find.byKey(ValueKey<String>('arena-quick-card-$correctIdx'));
    await tester.ensureVisible(quickBtn);
    await tester.tap(quickBtn);
    await tester.pumpAndSettle();

    expect(arenaVm.phase, SoloBattlePhase.choosingAction);
    expect(find.byKey(const ValueKey<String>('arena-grade-pill-correct')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
