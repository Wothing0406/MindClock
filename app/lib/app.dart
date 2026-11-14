import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/debug/debug_fixture_alarm_sync_gateway.dart';
import 'data/debug/debug_fixture_auth_gateway.dart';
import 'data/debug/debug_fixture_personal_flow_repository.dart';
import 'data/debug/debug_fixture_study_ai_gateway.dart';
import 'data/repositories/guest_workspace_repository.dart';
import 'data/repositories/local_study_focus_repository.dart';
import 'data/repositories/remote_alarm_sync_gateway.dart';
import 'data/repositories/remote_personal_flow_repository.dart';
import 'data/repositories/remote_study_ai_gateway.dart';
import 'data/services/firebase_auth_gateway.dart';
import 'data/services/local_key_value_store.dart';
import 'data/services/method_channel_camera_gateway.dart';
import 'data/services/method_channel_study_focus_bridge.dart';
import 'data/services/offline_text_draft_store.dart';
import 'data/services/pending_alarm_event_store.dart';
import 'data/services/personal_api_client.dart';
import 'domain/services/alarm_scheduler_service.dart';
import 'domain/services/alarm_sync_gateway.dart';
import 'domain/services/auth_session_gateway.dart';
import 'domain/services/camera_capture_gateway.dart';
import 'domain/services/personal_flow_repository.dart';
import 'domain/services/study_ai_gateway.dart';
import 'domain/services/study_focus_bridge.dart';
import 'ui/core/theme/mindclock_theme.dart';
import 'ui/features/guest_shell/view_models/guest_workspace_view_model.dart';
import 'ui/features/guest_shell/views/mindclock_shell_screen.dart';
import 'ui/features/personal_flow/view_models/personal_flow_view_model.dart';
import 'ui/features/study_focus/view_models/study_focus_view_model.dart';

const String _envApiBaseUrl = String.fromEnvironment('MINDCLOCK_API_BASE_URL');
const String _envFirebaseWebApiKey =
    String.fromEnvironment('MINDCLOCK_FIREBASE_WEB_API_KEY');
const bool _envUseDebugFixture =
    bool.fromEnvironment('MINDCLOCK_DEBUG_FIXTURE', defaultValue: false);

class MindClockApp extends StatefulWidget {
  const MindClockApp({
    super.key,
    required this.repository,
    this.alarmScheduler,
    this.alarmSyncGateway,
    this.pendingAlarmEventStore,
    this.authGateway,
    this.personalRepository,
    this.cameraGateway,
    this.draftStore,
    this.studyFocusBridge,
    this.studyAiGateway,
    this.studyNowProvider,
    this.enableStudyTicker = true,
  });

  final GuestWorkspaceRepository repository;
  final AlarmSchedulerService? alarmScheduler;
  final AlarmSyncGateway? alarmSyncGateway;
  final PendingAlarmEventStore? pendingAlarmEventStore;
  final AuthSessionGateway? authGateway;
  final PersonalFlowRepository? personalRepository;
  final CameraCaptureGateway? cameraGateway;
  final OfflineTextDraftStore? draftStore;
  final StudyFocusBridge? studyFocusBridge;
  final StudyAiGateway? studyAiGateway;
  final DateTime Function()? studyNowProvider;
  final bool enableStudyTicker;

  @override
  State<MindClockApp> createState() => _MindClockAppState();
}

class _MindClockAppState extends State<MindClockApp> {
  late final GuestWorkspaceViewModel _viewModel;
  late final PersonalFlowViewModel _personalViewModel;
  late final StudyFocusViewModel _studyFocusViewModel;

  @override
  void initState() {
    super.initState();
    final LocalKeyValueStore kvStore = widget.repository.store;
    final AuthSessionGateway authGateway = widget.authGateway ??
        createDefaultAuthGateway(store: kvStore);
    final PersonalApiClient sharedApiClient =
        createDefaultPersonalApiClient(authGateway: authGateway);

    final AlarmSyncGateway alarmSyncGateway = widget.alarmSyncGateway ??
        createDefaultAlarmSyncGateway(apiClient: sharedApiClient);
    final PendingAlarmEventStore pendingEventStore =
        widget.pendingAlarmEventStore ??
            PendingAlarmEventStore(store: kvStore);

    _viewModel = GuestWorkspaceViewModel(
      repository: widget.repository,
      alarmScheduler:
          widget.alarmScheduler ?? createDefaultAlarmSchedulerService(),
      alarmSyncGateway: alarmSyncGateway,
      pendingAlarmEventStore: pendingEventStore,
    );

    final PersonalFlowRepository personalRepository =
        widget.personalRepository ??
            createDefaultPersonalRepository(
              authGateway: authGateway,
              apiClient: sharedApiClient,
            );
    final CameraCaptureGateway cameraGateway =
        widget.cameraGateway ?? const MethodChannelCameraCaptureGateway();
    final OfflineTextDraftStore draftStore =
        widget.draftStore ?? OfflineTextDraftStore(store: kvStore);

    _personalViewModel = PersonalFlowViewModel(
      authGateway: authGateway,
      repository: personalRepository,
      cameraGateway: cameraGateway,
      draftStore: draftStore,
    );
    _studyFocusViewModel = StudyFocusViewModel(
      repository: LocalStudyFocusRepository(store: kvStore),
      bridge: widget.studyFocusBridge ?? createDefaultStudyFocusBridge(),
      aiGateway: widget.studyAiGateway ??
          createDefaultStudyAiGateway(apiClient: sharedApiClient),
      nowProvider: widget.studyNowProvider,
      enablePeriodicTicker: widget.enableStudyTicker,
    );
    _initializeAll();
  }

  Future<void> _initializeAll() async {
    await _viewModel.initialize();
    await _personalViewModel.initialize();
    await _viewModel.setAccountContext(
      ownerScopeKey: _personalViewModel.authSession.ownerScopeKey,
      isAuthenticated: _personalViewModel.authSession.isAuthenticated,
    );
    await _studyFocusViewModel.initialize(
      ownerScopeKey: _personalViewModel.authSession.ownerScopeKey,
    );
    await _studyFocusViewModel.setAccountAuthenticated(
      _personalViewModel.authSession.isAuthenticated,
      gradeLevel: _viewModel.profile.gradeLevel,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _personalViewModel.dispose();
    _studyFocusViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindClock',
      debugShowCheckedModeBanner: false,
      theme: MindClockTheme.buildThemeData(),
      home: MindClockShellScreen(
        viewModel: _viewModel,
        personalViewModel: _personalViewModel,
        studyViewModel: _studyFocusViewModel,
      ),
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

StudyFocusBridge createDefaultStudyFocusBridge() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return const MethodChannelStudyFocusBridge();
  }
  return const UnboundStudyFocusBridge();
}

AuthSessionGateway createDefaultAuthGateway({
  required LocalKeyValueStore store,
}) {
  if (kDebugMode && _envUseDebugFixture) {
    return DebugFixtureAuthGateway();
  }
  return FirebaseAuthGateway(
    store: store,
    firebaseWebApiKey: _envFirebaseWebApiKey,
  );
}

PersonalApiClient createDefaultPersonalApiClient({
  required AuthSessionGateway authGateway,
}) {
  final Uri? baseUri = _envApiBaseUrl.trim().isNotEmpty
      ? Uri.tryParse(_envApiBaseUrl.trim())
      : null;
  return PersonalApiClient(
    baseUri: baseUri,
    authGateway: authGateway,
  );
}

PersonalFlowRepository createDefaultPersonalRepository({
  required AuthSessionGateway authGateway,
  PersonalApiClient? apiClient,
}) {
  if (kDebugMode && _envUseDebugFixture) {
    return DebugFixturePersonalFlowRepository();
  }
  return RemotePersonalFlowRepository(
    apiClient:
        apiClient ?? createDefaultPersonalApiClient(authGateway: authGateway),
  );
}

AlarmSyncGateway createDefaultAlarmSyncGateway({
  required PersonalApiClient apiClient,
}) {
  if (kDebugMode && _envUseDebugFixture) {
    return const DebugFixtureAlarmSyncGateway();
  }
  return RemoteAlarmSyncGateway(apiClient: apiClient);
}

StudyAiGateway createDefaultStudyAiGateway({
  required PersonalApiClient apiClient,
}) {
  if (kDebugMode && _envUseDebugFixture) {
    return const DebugFixtureStudyAiGateway();
  }
  return RemoteStudyAiGateway(apiClient: apiClient);
}
