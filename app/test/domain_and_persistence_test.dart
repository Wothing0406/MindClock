import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/data/repositories/guest_workspace_repository.dart';
import 'package:mindclock_app/data/services/local_key_value_store.dart';
import 'package:mindclock_app/domain/models/alarm_config.dart';
import 'package:mindclock_app/domain/models/study_profile.dart';
import 'package:mindclock_app/domain/models/subject_catalog.dart';
import 'package:mindclock_app/domain/models/timetable.dart';
import 'package:mindclock_app/domain/models/wake_suggestion.dart';
import 'package:mindclock_app/domain/services/alarm_scheduler_service.dart';
import 'package:mindclock_app/ui/core/strings/app_strings.dart';
import 'package:mindclock_app/ui/features/guest_shell/view_models/guest_workspace_view_model.dart';

void main() {
  group('WakeSuggestionCalculator', () {
    test('tính đúng 07:00 - 25 - 30 - 10 = 05:55', () {
      final WakeSuggestionResult result = WakeSuggestionCalculator.calculate(
        const WakeSuggestionInput(
          classStartMinutes: 7 * 60,
          commuteMinutes: 25,
          prepMinutes: 30,
          bufferMinutes: 10,
        ),
      );
      expect(result.isValidInput, isTrue);
      expect(result.hour, 5);
      expect(result.minute, 55);
      expect(result.crossedPreviousDay, isFalse);
      expect(result.formulaTextVi, contains('07:00'));
      expect(result.formulaTextVi, contains('05:55'));
    });

    test('xử lý qua nửa đêm 00:15 - 65p = 23:10 (hôm trước)', () {
      final WakeSuggestionResult result = WakeSuggestionCalculator.calculate(
        const WakeSuggestionInput(
          classStartMinutes: 15,
          commuteMinutes: 25,
          prepMinutes: 30,
          bufferMinutes: 10,
        ),
      );
      expect(result.isValidInput, isTrue);
      expect(result.formattedWakeTime, '23:10');
      expect(result.crossedPreviousDay, isTrue);
    });
  });

  group('UnboundAlarmSchedulerService & Khôi phục local', () {
    test(
      'chưa nối OS chỉ trả savedConfigOnly ("Đã lưu cấu hình"), không trả Đã sẵn sàng',
      () async {
        const AlarmSchedulerService service = UnboundAlarmSchedulerService();
        final AlarmPermissionSnapshot perms = await service.getPermissionStatus();
        final AlarmScheduleResult res = await service.scheduleAlarm(
          const AlarmConfig(id: 'a1', hour: 5, minute: 55),
        );

        expect(service.isOsBridgeConnected, isFalse);
        expect(perms.isOsBridgeConnected, isFalse);
        expect(perms.allGranted, isFalse);
        expect(perms.exactAlarm, OsPermissionState.unknown);
        expect(res.status, AlarmSyncStatus.savedConfigOnly);
        expect(res.messageVi, contains(AppStrings.alarmSavedConfigOnly));
        expect(res.messageVi.contains('Đã sẵn sàng'), isFalse);
      },
    );

    test(
      'khách hoàn thành thiết lập, sửa TKB không tự đổi giờ báo thức, mở lại app giữ nguyên dữ liệu',
      () async {
        final InMemoryKeyValueStore store = InMemoryKeyValueStore();
        final GuestWorkspaceRepository repo1 =
            GuestWorkspaceRepository(store: store);
        final GuestWorkspaceViewModel vm1 = GuestWorkspaceViewModel(
          repository: repo1,
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await vm1.initialize();

        await vm1.saveStudyProfile(
          const StudyProfile(
            gradeLevel: 'Lớp 9',
            selectedSubjectCodes: <String>['math', 'informatics'],
            prioritySubjects: <PrioritySubject>[
              PrioritySubject(subjectCode: 'math', level: PriorityLevel.high),
              PrioritySubject(
                subjectCode: 'informatics',
                level: PriorityLevel.medium,
              ),
            ],
            goalLabel: 'Ôn thi vào 10',
          ),
        );

        await vm1.addTimetableEntry(
          weekday: 1,
          subjectCode: 'math',
          startMinutes: 7 * 60,
        );
        await vm1.toggleRestDay(7, true);

        expect(SubjectCatalog.isApproved('informatics'), isFalse);

        final AlarmScheduleResult scheduleResult = await vm1.saveAlarm(
          const AlarmConfig(
            id: 'morning_1',
            hour: 5,
            minute: 55,
            repeatWeekdays: <int>[1, 3, 5],
            soundOption: AlarmSoundOption.clearBell,
            vibrateEnabled: true,
            mode: AlarmMode.challenge,
            subjectCode: 'informatics',
          ),
        );
        expect(scheduleResult.status, AlarmSyncStatus.savedConfigOnly);
        expect(
          vm1.statusLabelForAlarm(vm1.alarms.first),
          AppStrings.alarmSavedConfigOnly,
        );

        // Sửa lịch Thứ 2 từ 07:00 sang 07:30 -> tuyệt đối không tự sửa giờ chuông 05:55!
        final TimetableEntry originalEntry =
            vm1.timetable.dayFor(1).entries.first;
        await vm1.updateTimetableEntry(
          weekday: 1,
          updated: originalEntry.copyWith(startMinutes: 7 * 60 + 30),
        );

        expect(vm1.scheduleChangedSinceAlarmSave, isTrue);
        expect(vm1.primaryAlarm?.formattedTime, '05:55');

        // Giả lập đóng và mở lại app bằng repository + viewModel mới trên cùng local store
        final GuestWorkspaceRepository repo2 =
            GuestWorkspaceRepository(store: store);
        final GuestWorkspaceViewModel vm2 = GuestWorkspaceViewModel(
          repository: repo2,
          alarmScheduler: const UnboundAlarmSchedulerService(),
        );
        await vm2.initialize();

        expect(vm2.workspace.onboardingCompleted, isTrue);
        expect(vm2.profile.gradeLevel, 'Lớp 9');
        expect(
          vm2.profile.selectedSubjectCodes,
          equals(<String>['math', 'informatics']),
        );
        expect(vm2.profile.goalLabel, 'Ôn thi vào 10');
        expect(vm2.timetable.dayFor(7).isRestDay, isTrue);
        expect(
          vm2.timetable.dayFor(1).entries.first.formattedStartTime,
          '07:30',
        );
        expect(vm2.alarms.length, 1);
        expect(vm2.primaryAlarm?.formattedTime, '05:55');
        expect(vm2.primaryAlarm?.mode, AlarmMode.challenge);
        expect(vm2.primaryAlarm?.subjectCode, 'informatics');
        expect(
          vm2.statusLabelForAlarm(vm2.primaryAlarm!),
          AppStrings.alarmSavedConfigOnly,
        );
      },
    );

    test('Nhạc chuông Bermuda MP3 lưu và khôi phục đúng qua AlarmConfig JSON', () {
      const AlarmConfig original = AlarmConfig(
        id: 'alarm_bermuda_1',
        hour: 6,
        minute: 20,
        soundEnabled: true,
        soundOption: AlarmSoundOption.bermudaAlarm,
      );
      final AlarmConfig restored = AlarmConfig.fromJson(original.toJson());
      expect(restored.soundOption, AlarmSoundOption.bermudaAlarm);
      expect(restored.soundOption.id, 'bermuda_alarm');
      expect(restored.soundOption.labelVi, 'Nhạc chuông Bermuda');
    });
  });
}
