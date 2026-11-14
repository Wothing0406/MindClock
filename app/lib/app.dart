import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/repositories/guest_workspace_repository.dart';
import 'data/services/local_key_value_store.dart';
import 'domain/services/alarm_scheduler_service.dart';
import 'ui/core/theme/mindclock_theme.dart';
import 'ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'ui/features/guest_shell/views/mindclock_shell_screen.dart';

class MindClockApp extends StatefulWidget {
  const MindClockApp({
    super.key,
    required this.repository,
    this.alarmScheduler,
  });

  final GuestWorkspaceRepository repository;
  final AlarmSchedulerService? alarmScheduler;

  @override
  State<MindClockApp> createState() => _MindClockAppState();
}

class _MindClockAppState extends State<MindClockApp> {
  late final GuestWorkspaceViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = GuestWorkspaceViewModel(
      repository: widget.repository,
      alarmScheduler:
          widget.alarmScheduler ?? createDefaultAlarmSchedulerService(),
    )..initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindClock',
      debugShowCheckedModeBanner: false,
      theme: MindClockTheme.buildThemeData(),
      home: MindClockShellScreen(viewModel: _viewModel),
    );
  }
}

GuestWorkspaceRepository createDefaultGuestRepository() {
  return GuestWorkspaceRepository(store: SharedPreferencesKeyValueStore());
}

AlarmSchedulerService createDefaultAlarmSchedulerService() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidMethodChannelAlarmSchedulerService();
  }
  return const UnboundAlarmSchedulerService();
}
