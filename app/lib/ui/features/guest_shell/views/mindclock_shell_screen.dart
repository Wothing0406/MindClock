import 'package:flutter/material.dart';

import '../../../../data/services/method_channel_media_picker_gateway.dart';
import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/community_models.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../../domain/services/media_picker_gateway.dart';
import '../../../../domain/services/morning_question_selector.dart';
import '../../../../domain/services/pvp_gateway.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_brand_mark.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../arena/view_models/solo_arena_view_model.dart';
import '../../arena/views/arena_screen.dart';
import '../../personal_flow/view_models/personal_flow_view_model.dart';
import '../../personal_flow/views/practice_session_screen.dart';
import '../../study_focus/view_models/study_focus_view_model.dart';
import '../../study_focus/views/study_space_screen.dart';
import '../view_models/guest_workspace_view_model.dart';
import 'alarm_config_screen.dart';
import 'alarm_ring_screen.dart';
import 'auth_screen.dart';
import 'me_guest_screen.dart';
import 'onboarding_setup_screen.dart';
import 'timetable_profile_screen.dart';
import 'today_screen.dart';
import 'welcome_screen.dart';

enum _GuestFlowStage {
  welcome,
  auth,
  onboardingSetup,
  mainTabs,
  alarmConfig,
  timetableProfile,
  studySpace,
}

/// Khung điều hướng chính 4 tab (Hôm nay, Luyện tập, Đấu trường G1, Tôi).
class MindClockShellScreen extends StatefulWidget {
  const MindClockShellScreen({
    super.key,
    required this.viewModel,
    required this.personalViewModel,
    this.studyViewModel,
    this.arenaViewModel,
    this.communityRepository,
    this.pvpGateway,
    this.mediaPickerGateway,
  });

  final GuestWorkspaceViewModel viewModel;
  final PersonalFlowViewModel personalViewModel;
  final StudyFocusViewModel? studyViewModel;
  final SoloArenaViewModel? arenaViewModel;
  final CommunityRepository? communityRepository;
  final PvpGateway? pvpGateway;
  final MediaPickerGateway? mediaPickerGateway;

  @override
  State<MindClockShellScreen> createState() => _MindClockShellScreenState();
}

class _MindClockShellScreenState extends State<MindClockShellScreen>
    with WidgetsBindingObserver {
  _GuestFlowStage _stage = _GuestFlowStage.welcome;
  int _selectedTabIndex = 0;
  StudyRoomDetail? _joinedCommunityRoom;
  String? _roomOwnerScope;
  AlarmConfig? _editingAlarm;
  String? _todayBanner;
  bool _syncedInitialRoute = false;
  bool _activeAlarmPlayingInQuestion = false;
  String? _activeAlarmIdInQuestion;
  late final SoloArenaViewModel _ownedArenaViewModel;

  SoloArenaViewModel get _arenaVm =>
      widget.arenaViewModel ?? _ownedArenaViewModel;

  @override
  void initState() {
    super.initState();
    _ownedArenaViewModel = SoloArenaViewModel();
    WidgetsBinding.instance.addObserver(this);
    widget.viewModel.addListener(_onViewModelChanged);
    widget.personalViewModel.addListener(_onViewModelChanged);
    widget.studyViewModel?.addListener(_onViewModelChanged);
    _syncFromViewModel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.viewModel.removeListener(_onViewModelChanged);
    widget.personalViewModel.removeListener(_onViewModelChanged);
    widget.studyViewModel?.removeListener(_onViewModelChanged);
    _ownedArenaViewModel.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      widget.studyViewModel?.onAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      widget.studyViewModel?.onAppResumed();
      if (widget.viewModel.isLoaded) {
        widget.viewModel.refreshOsStatus();
      }
    }
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    _syncFromViewModel();
    setState(() {});
  }

  void _syncFromViewModel() {
    if (!_syncedInitialRoute && widget.viewModel.isLoaded) {
      _syncedInitialRoute = true;
      _stage = widget.viewModel.workspace.onboardingCompleted
          ? _GuestFlowStage.mainTabs
          : _GuestFlowStage.welcome;
    }
    final String scope = widget.personalViewModel.authSession.ownerScopeKey;
    final bool isAuth = widget.personalViewModel.authSession.isAuthenticated;
    if (_roomOwnerScope != scope || !isAuth) {
      _joinedCommunityRoom = null;
      _roomOwnerScope = scope;
    }

    if (widget.viewModel.isLoaded &&
        (widget.viewModel.ownerScopeKey != scope ||
            widget.viewModel.isAuthenticated != isAuth)) {
      widget.viewModel.setAccountContext(
        ownerScopeKey: scope,
        isAuthenticated: isAuth,
      );
    }

    final StudyFocusViewModel? studyVm = widget.studyViewModel;
    if (studyVm != null && studyVm.isLoaded) {
      if (studyVm.ownerScopeKey != scope) {
        studyVm.setOwnerScope(scope);
      }
      if (studyVm.isAuthenticated != isAuth ||
          studyVm.gradeLevel != widget.viewModel.profile.gradeLevel) {
        studyVm.setAccountAuthenticated(
          isAuth,
          gradeLevel: widget.viewModel.profile.gradeLevel,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;

    if (!widget.viewModel.isLoaded) {
      return Scaffold(
        key: const ValueKey<String>('app-boot-loading'),
        backgroundColor: mc.night,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(mc.space24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const MindClockBrandMark(size: 88),
                    SizedBox(height: mc.space16),
                    Text(
                      'MindClock',
                      style: mc.screenTitleStyle.copyWith(color: mc.nightText),
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      'Đang tải dữ liệu trên máy...',
                      textAlign: TextAlign.center,
                      style: mc.bodyStyle.copyWith(color: mc.nightText),
                    ),
                    SizedBox(height: mc.space16),
                    const MindClockLoadingProgressBar(onNightSurface: true),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final AlarmRingPayload? activeRing = widget.viewModel.activeRingPayload;
    if (activeRing != null) {
      return Scaffold(
        backgroundColor: mc.night,
        body: AlarmRingScreen(
          payload: activeRing,
          onOpenQuestion: () {
            final String alarmId = activeRing.alarmId;
            String? resolvedSubject = activeRing.subjectCode;
            if (resolvedSubject == null || resolvedSubject.trim().isEmpty) {
              AlarmConfig? matchedAlarm;
              for (final AlarmConfig a in widget.viewModel.alarms) {
                if (a.id == alarmId) {
                  matchedAlarm = a;
                  break;
                }
              }
              matchedAlarm ??= AlarmConfig(
                id: alarmId,
                hour: 6,
                minute: 0,
                mode: activeRing.mode,
                subjectRule: AlarmSubjectRule.todaySchedule,
              );
              final MorningQuestionProposal proposal =
                  MorningQuestionSelector.resolveForAlarm(
                alarm: matchedAlarm,
                profile: widget.viewModel.profile,
                timetable: widget.viewModel.timetable,
                weekday: DateTime.now().weekday,
              );
              if (proposal.subjectCode.trim().isNotEmpty) {
                resolvedSubject = proposal.subjectCode;
              }
            }
            widget.viewModel.dismissActiveRingUi();
            widget.personalViewModel.startSession(
              alarmId: alarmId,
              subjectCode: resolvedSubject,
              gradeLevel: widget.viewModel.profile.gradeLevel,
              challengeMode: activeRing.mode == AlarmMode.challenge,
            );
            setState(() {
              _activeAlarmPlayingInQuestion = true;
              _activeAlarmIdInQuestion = alarmId;
              _stage = _GuestFlowStage.mainTabs;
              _selectedTabIndex = 1;
            });
          },
          onSnooze5Min: activeRing.mode == AlarmMode.normal
              ? () async {
                  await widget.viewModel.snoozeActiveAlarm(minutes: 5);
                  if (!mounted) return;
                  setState(() {
                    _todayBanner = widget.viewModel.lastSchedulerMessage;
                    _stage = _GuestFlowStage.mainTabs;
                    _selectedTabIndex = 0;
                  });
                }
              : null,
          onEmergencyStop: () async {
            await widget.viewModel.triggerEmergencyStop(
              alarmId: activeRing.alarmId,
              activeSessionId:
                  widget.personalViewModel.activeSession?.sessionId,
            );
            if (!mounted) return;
            setState(() {
              _activeAlarmPlayingInQuestion = false;
              _activeAlarmIdInQuestion = null;
              _todayBanner = 'Đã dừng chuông báo thức.';
              _stage = _GuestFlowStage.mainTabs;
              _selectedTabIndex = 0;
            });
          },
        ),
      );
    }

    switch (_stage) {
      case _GuestFlowStage.welcome:
        return Scaffold(
          backgroundColor: mc.paper,
          body: WelcomeScreen(
            onStartAuth: () {
              setState(() => _stage = _GuestFlowStage.auth);
            },
            onAlarmOnly: () async {
              await widget.viewModel.completeOnboardingAsLater(alarmOnly: true);
              if (!mounted) return;
              setState(() {
                _editingAlarm = null;
                _stage = _GuestFlowStage.alarmConfig;
              });
            },
          ),
        );

      case _GuestFlowStage.auth:
        return Scaffold(
          backgroundColor: mc.paper,
          body: AuthScreen(
            personalViewModel: widget.personalViewModel,
            onAuthenticated: (String? alias) async {
              final bool isSignedIn =
                  widget.personalViewModel.authSession.isAuthenticated;
              if (isSignedIn) {
                await widget.personalViewModel.recordConsent(
                  scope: 'terms_and_privacy',
                  version: '2026-11',
                  granted: true,
                );
              }
              if (alias != null && alias.isNotEmpty) {
                final StudyProfile updatedProfile =
                    widget.viewModel.profile.copyWith(alias: alias);
                await widget.viewModel.saveStudyProfile(updatedProfile);
                if (isSignedIn) {
                  await widget.personalViewModel.syncProfileToServer(
                    updatedProfile,
                  );
                }
                if (!mounted) return;
                setState(() {
                  _stage = _GuestFlowStage.onboardingSetup;
                });
                return;
              }

              // Đăng nhập tài khoản cũ: khôi phục hồ sơ từ server/cục bộ và vào thẳng Hôm nay nếu đã có môn học.
              final StudyProfile? remoteProfile =
                  await widget.personalViewModel.fetchRemoteProfileIfSignedIn();
              if (remoteProfile != null &&
                  (remoteProfile.selectedSubjectCodes.isNotEmpty ||
                      remoteProfile.alias.isNotEmpty)) {
                final StudyProfile merged = widget.viewModel.profile.copyWith(
                  alias: remoteProfile.alias.isNotEmpty
                      ? remoteProfile.alias
                      : widget.viewModel.profile.alias,
                  avatarId: remoteProfile.avatarId,
                  gradeLevel: remoteProfile.gradeLevel ??
                      widget.viewModel.profile.gradeLevel,
                  selectedSubjectCodes:
                      remoteProfile.selectedSubjectCodes.isNotEmpty
                          ? remoteProfile.selectedSubjectCodes
                          : widget.viewModel.profile.selectedSubjectCodes,
                  goalLabel: remoteProfile.goalLabel.isNotEmpty
                      ? remoteProfile.goalLabel
                      : widget.viewModel.profile.goalLabel,
                );
                await widget.viewModel.saveStudyProfile(merged);
              }

              final StudyProfile effectiveProfile = widget.viewModel.profile;
              final bool hasCompletedSetup =
                  effectiveProfile.selectedSubjectCodes.isNotEmpty;
              if (hasCompletedSetup) {
                await widget.viewModel.completeOnboardingAsLater(
                  alarmOnly: false,
                );
              }
              if (!mounted) return;
              setState(() {
                if (hasCompletedSetup) {
                  _todayBanner =
                      'Chào mừng ${effectiveProfile.alias.isNotEmpty ? effectiveProfile.alias : 'bạn'} quay lại!';
                  _stage = _GuestFlowStage.mainTabs;
                  _selectedTabIndex = 0;
                } else {
                  _stage = _GuestFlowStage.onboardingSetup;
                }
              });
            },
            onUseAlarmOnly: () async {
              await widget.viewModel.completeOnboardingAsLater(alarmOnly: true);
              if (!mounted) return;
              setState(() {
                _editingAlarm = null;
                _stage = _GuestFlowStage.alarmConfig;
              });
            },
            onBackToWelcome: () {
              setState(() => _stage = _GuestFlowStage.welcome);
            },
          ),
        );

      case _GuestFlowStage.onboardingSetup:
        return Scaffold(
          backgroundColor: mc.paper,
          body: OnboardingSetupScreen(
            initialProfile: widget.viewModel.profile,
            mediaPickerGateway:
                widget.mediaPickerGateway ?? MethodChannelMediaPickerGateway(),
            onSaveProfile: (StudyProfile nextProfile) async {
              await widget.viewModel.saveStudyProfile(nextProfile);
              if (widget.personalViewModel.authSession.isAuthenticated) {
                await widget.personalViewModel.syncProfileToServer(nextProfile);
                await widget.personalViewModel.syncTimetableToServer(
                  widget.viewModel.timetable,
                );
              }
              if (!mounted) return;
              setState(() {
                _todayBanner =
                    'Chào mừng ${nextProfile.alias.isNotEmpty ? nextProfile.alias : 'bạn'}! Kế hoạch học tập đã được thiết lập.';
                _stage = _GuestFlowStage.mainTabs;
                _selectedTabIndex = 0;
              });
            },
            onSkipLater: () async {
              await widget.viewModel
                  .completeOnboardingAsLater(alarmOnly: false);
              if (!mounted) return;
              setState(() {
                _stage = _GuestFlowStage.mainTabs;
                _selectedTabIndex = 0;
              });
            },
            onAlarmOnly: () async {
              await widget.viewModel.completeOnboardingAsLater(alarmOnly: true);
              if (!mounted) return;
              setState(() {
                _editingAlarm = null;
                _stage = _GuestFlowStage.alarmConfig;
              });
            },
          ),
        );

      case _GuestFlowStage.alarmConfig:
        return AlarmConfigScreen(
          viewModel: widget.viewModel,
          editingAlarm: _editingAlarm,
          mediaPickerGateway:
              widget.mediaPickerGateway ?? MethodChannelMediaPickerGateway(),
          studyAiGateway: widget.studyViewModel?.aiGateway,
          onSaved: (String message) {
            setState(() {
              _editingAlarm = null;
              _todayBanner = message;
              _stage = _GuestFlowStage.mainTabs;
              _selectedTabIndex = 0;
            });
          },
          onCancel: () {
            setState(() {
              _editingAlarm = null;
              _stage = _GuestFlowStage.mainTabs;
            });
          },
        );

      case _GuestFlowStage.timetableProfile:
        return TimetableProfileScreen(
          viewModel: widget.viewModel,
          personalViewModel: widget.personalViewModel,
          mediaPickerGateway:
              widget.mediaPickerGateway ?? MethodChannelMediaPickerGateway(),
          onClose: () {
            setState(() => _stage = _GuestFlowStage.mainTabs);
          },
        );

      case _GuestFlowStage.studySpace:
        final StudyFocusViewModel? studyVm = widget.studyViewModel;
        if (studyVm == null) {
          return Scaffold(
            backgroundColor: mc.paper,
            body: Center(
              child: Text('Không gian học chưa được khởi tạo.',
                  style: mc.bodyStyle),
            ),
          );
        }
        return StudySpaceScreen(
          key: ValueKey(
              'study-space-${widget.personalViewModel.authSession.ownerScopeKey}'),
          guestViewModel: widget.viewModel,
          studyViewModel: studyVm,
          communityRepository: widget.communityRepository,
          initialRoom: _joinedCommunityRoom,
          onRoomChanged: (room) => _joinedCommunityRoom = room,
          mediaPickerGateway:
              widget.mediaPickerGateway ?? MethodChannelMediaPickerGateway(),
          onClose: () {
            setState(() {
              _stage = _GuestFlowStage.mainTabs;
              _selectedTabIndex = 0;
            });
          },
        );

      case _GuestFlowStage.mainTabs:
        final Widget body;
        switch (_selectedTabIndex) {
          case 1:
            body = PracticeSessionScreen(
              guestViewModel: widget.viewModel,
              personalViewModel: widget.personalViewModel,
              onOpenProfileSetup: () {
                setState(() => _stage = _GuestFlowStage.timetableProfile);
              },
              onOpenStudySpace: widget.studyViewModel != null
                  ? () => setState(() => _stage = _GuestFlowStage.studySpace)
                  : null,
            );
          case 2:
            body = ArenaScreen(
              guestViewModel: widget.viewModel,
              arenaViewModel: _arenaVm,
              pvpGateway: widget.pvpGateway,
              currentUserId: widget.personalViewModel.authSession.uid,
            );
          case 3:
            body = MeGuestScreen(
              viewModel: widget.viewModel,
              personalViewModel: widget.personalViewModel,
              communityRepository: widget.communityRepository,
              onRoomJoined: (room) {
                setState(() {
                  _joinedCommunityRoom = room;
                  _stage = _GuestFlowStage.studySpace;
                });
              },
              mediaPickerGateway: widget.mediaPickerGateway ??
                  MethodChannelMediaPickerGateway(),
              onEditProfileAndTimetable: () {
                setState(() => _stage = _GuestFlowStage.timetableProfile);
              },
              onResetGuestData: () async {
                await widget.viewModel.resetLocalWorkspace();
                if (!mounted) return;
                setState(() {
                  _todayBanner = null;
                  _selectedTabIndex = 0;
                  _stage = _GuestFlowStage.welcome;
                });
              },
              onDeleteAccount: () async {
                final String scopeToDelete =
                    widget.personalViewModel.authSession.ownerScopeKey;
                final bool deleted =
                    await widget.personalViewModel.deleteAccount();
                if (!deleted) return;
                await widget.viewModel.clearDeletedAccountWorkspace(
                  scopeToDelete,
                );
                if (!mounted) return;
                setState(() {
                  _todayBanner = null;
                  _selectedTabIndex = 0;
                  _stage = _GuestFlowStage.welcome;
                });
              },
            );
          case 0:
          default:
            body = TodayScreen(
              viewModel: widget.viewModel,
              studyViewModel: widget.studyViewModel,
              communityRepository: widget.communityRepository,
              lastActionBanner: _todayBanner,
              onSelectTab: (int tabIdx) {
                setState(() => _selectedTabIndex = tabIdx);
              },
              onCreateAlarm: () {
                setState(() {
                  _editingAlarm = null;
                  _stage = _GuestFlowStage.alarmConfig;
                });
              },
              onEditAlarm: (AlarmConfig alarm) {
                setState(() {
                  _editingAlarm = alarm;
                  _stage = _GuestFlowStage.alarmConfig;
                });
              },
              onOpenTimetableAndProfile: () {
                setState(() => _stage = _GuestFlowStage.timetableProfile);
              },
              onOpenStudySpace: widget.studyViewModel != null
                  ? () => setState(() => _stage = _GuestFlowStage.studySpace)
                  : null,
            );
        }

        return Scaffold(
          backgroundColor: mc.paper,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                if (_activeAlarmPlayingInQuestion)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: mc.space16,
                      vertical: mc.space8,
                    ),
                    color: mc.night,
                    child: Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          AppStrings.ringSoundStoppedReviewNotice,
                          style: mc.captionStyle.copyWith(color: mc.nightText),
                        ),
                        MindClockButton(
                          key: const ValueKey<String>(
                            'shell-emergency-stop-bar',
                          ),
                          label: AppStrings.ringEmergencyStop,
                          icon: MindClockIconKind.warning,
                          variant: MindClockButtonVariant.secondary,
                          expand: false,
                          onPressed: () async {
                            await widget.viewModel.triggerEmergencyStop(
                              alarmId: _activeAlarmIdInQuestion,
                              activeSessionId: widget
                                  .personalViewModel.activeSession?.sessionId,
                            );
                            if (!mounted) return;
                            setState(() {
                              _activeAlarmPlayingInQuestion = false;
                              _activeAlarmIdInQuestion = null;
                              _todayBanner = 'Đã dừng chuông báo thức.';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(child: body),
              ],
            ),
          ),
          bottomNavigationBar: _MindClockThreeTabBar(
            selectedIndex: _selectedTabIndex,
            onSelect: (int idx) => setState(() => _selectedTabIndex = idx),
          ),
        );
    }
  }
}

class _MindClockThreeTabBar extends StatelessWidget {
  const _MindClockThreeTabBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: mc.surface,
        border: Border(top: BorderSide(color: mc.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: _TabItem(
                key: const ValueKey<String>('nav-today'),
                label: AppStrings.navToday,
                icon: MindClockIconKind.clock,
                selected: selectedIndex == 0,
                onTap: () => onSelect(0),
              ),
            ),
            Expanded(
              child: _TabItem(
                key: const ValueKey<String>('nav-practice'),
                label: AppStrings.navPractice,
                icon: MindClockIconKind.book,
                selected: selectedIndex == 1,
                onTap: () => onSelect(1),
              ),
            ),
            Expanded(
              child: _TabItem(
                key: const ValueKey<String>('nav-arena'),
                label: AppStrings.navArena,
                icon: MindClockIconKind.arena,
                selected: selectedIndex == 2,
                onTap: () => onSelect(2),
              ),
            ),
            Expanded(
              child: _TabItem(
                key: const ValueKey<String>('nav-me'),
                label: AppStrings.navMe,
                icon: MindClockIconKind.user,
                selected: selectedIndex == 3,
                onTap: () => onSelect(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final MindClockIconKind icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final Color color = selected ? mc.primary : mc.inkMuted;
    return MindClockPressable(
      onPressed: onTap,
      selected: selected,
      semanticLabel: 'Tab $label',
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: mc.space8,
          horizontal: mc.space4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MindClockIcon(icon, color: color, size: 22),
            SizedBox(height: mc.space4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: mc.chipLabelStyle.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
