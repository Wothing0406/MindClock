import 'package:flutter/material.dart';

import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../personal_flow/view_models/personal_flow_view_model.dart';
import '../../personal_flow/views/practice_session_screen.dart';
import '../../study_focus/view_models/study_focus_view_model.dart';
import '../../study_focus/views/study_space_screen.dart';
import '../view_models/guest_workspace_view_model.dart';
import 'alarm_config_screen.dart';
import 'alarm_ring_screen.dart';
import 'me_guest_screen.dart';
import 'onboarding_setup_screen.dart';
import 'timetable_profile_screen.dart';
import 'today_screen.dart';
import 'welcome_screen.dart';

enum _GuestFlowStage {
  welcome,
  onboardingSetup,
  mainTabs,
  alarmConfig,
  timetableProfile,
  studySpace,
}

/// Khung điều hướng chính 3 tab (Hôm nay, Luyện tập, Tôi) — lược bỏ hoàn toàn Đấu trường.
class MindClockShellScreen extends StatefulWidget {
  const MindClockShellScreen({
    super.key,
    required this.viewModel,
    required this.personalViewModel,
    this.studyViewModel,
  });

  final GuestWorkspaceViewModel viewModel;
  final PersonalFlowViewModel personalViewModel;
  final StudyFocusViewModel? studyViewModel;

  @override
  State<MindClockShellScreen> createState() => _MindClockShellScreenState();
}

class _MindClockShellScreenState extends State<MindClockShellScreen>
    with WidgetsBindingObserver {
  _GuestFlowStage _stage = _GuestFlowStage.welcome;
  int _selectedTabIndex = 0;
  AlarmConfig? _editingAlarm;
  String? _todayBanner;
  bool _syncedInitialRoute = false;
  bool _activeAlarmPlayingInQuestion = false;
  String? _activeAlarmIdInQuestion;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) {
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
        backgroundColor: mc.paper,
        body: Center(
          child: Text('Đang tải dữ liệu trên máy...', style: mc.bodyStyle),
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
            widget.viewModel.dismissActiveRingUi();
            widget.personalViewModel.startSession(
              alarmId: alarmId,
              subjectCode: activeRing.subjectCode,
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
              activeSessionId: widget.personalViewModel.activeSession?.sessionId,
            );
            if (!mounted) return;
            setState(() {
              _activeAlarmPlayingInQuestion = false;
              _activeAlarmIdInQuestion = null;
              _todayBanner = 'Đã dừng khẩn cấp báo thức cục bộ.';
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
            onStartGuestSetup: () {
              setState(() => _stage = _GuestFlowStage.onboardingSetup);
            },
            onSkipLater: () async {
              await widget.viewModel.completeOnboardingAsLater(alarmOnly: false);
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

      case _GuestFlowStage.onboardingSetup:
        return Scaffold(
          backgroundColor: mc.paper,
          body: OnboardingSetupScreen(
            initialProfile: widget.viewModel.profile,
            onSaveProfile: (StudyProfile nextProfile) async {
              await widget.viewModel.saveStudyProfile(nextProfile);
              if (!mounted) return;
              setState(() {
                _todayBanner =
                    'Đã lưu thiết lập học tập cục bộ trên máy.';
                _stage = _GuestFlowStage.mainTabs;
                _selectedTabIndex = 0;
              });
            },
            onSkipLater: () async {
              await widget.viewModel.completeOnboardingAsLater(alarmOnly: false);
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
              child: Text('Không gian học chưa được khởi tạo.', style: mc.bodyStyle),
            ),
          );
        }
        return StudySpaceScreen(
          guestViewModel: widget.viewModel,
          studyViewModel: studyVm,
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
            body = MeGuestScreen(
              viewModel: widget.viewModel,
              personalViewModel: widget.personalViewModel,
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
            );
          case 0:
          default:
            body = TodayScreen(
              viewModel: widget.viewModel,
              studyViewModel: widget.studyViewModel,
              lastActionBanner: _todayBanner,
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
                          'Báo thức đang phát nhỏ tiếng.',
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
                              activeSessionId:
                                  widget.personalViewModel.activeSession?.sessionId,
                            );
                            if (!mounted) return;
                            setState(() {
                              _activeAlarmPlayingInQuestion = false;
                              _activeAlarmIdInQuestion = null;
                              _todayBanner =
                                  'Đã dừng khẩn cấp báo thức cục bộ.';
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
                key: const ValueKey<String>('nav-me'),
                label: AppStrings.navMe,
                icon: MindClockIconKind.user,
                selected: selectedIndex == 2,
                onTap: () => onSelect(2),
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
              softWrap: true,
              style: mc.chipLabelStyle.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
