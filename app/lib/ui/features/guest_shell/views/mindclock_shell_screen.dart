import 'package:flutter/material.dart';

import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../view_models/guest_workspace_view_model.dart';
import 'alarm_config_screen.dart';
import 'me_guest_screen.dart';
import 'onboarding_setup_screen.dart';
import 'practice_placeholder_screen.dart';
import 'timetable_profile_screen.dart';
import 'today_screen.dart';
import 'welcome_screen.dart';

enum _GuestFlowStage {
  welcome,
  onboardingSetup,
  mainTabs,
  alarmConfig,
  timetableProfile,
}

/// Khung điều hướng chính 3 tab (Hôm nay, Luyện tập, Tôi) — lược bỏ hoàn toàn Đấu trường.
class MindClockShellScreen extends StatefulWidget {
  const MindClockShellScreen({
    super.key,
    required this.viewModel,
  });

  final GuestWorkspaceViewModel viewModel;

  @override
  State<MindClockShellScreen> createState() => _MindClockShellScreenState();
}

class _MindClockShellScreenState extends State<MindClockShellScreen> {
  _GuestFlowStage _stage = _GuestFlowStage.welcome;
  int _selectedTabIndex = 0;
  AlarmConfig? _editingAlarm;
  String? _todayBanner;
  bool _syncedInitialRoute = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
    _syncFromViewModel();
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
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

      case _GuestFlowStage.mainTabs:
        final Widget body;
        switch (_selectedTabIndex) {
          case 1:
            body = PracticePlaceholderScreen(
              viewModel: widget.viewModel,
              onOpenProfileSetup: () {
                setState(() => _stage = _GuestFlowStage.timetableProfile);
              },
            );
          case 2:
            body = MeGuestScreen(
              viewModel: widget.viewModel,
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
            );
        }

        return Scaffold(
          backgroundColor: mc.paper,
          body: SafeArea(child: body),
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
