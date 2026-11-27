import 'package:flutter/widgets.dart';

import '../../../../data/debug/debug_fixture_community_repository.dart';
import '../../../../data/services/method_channel_media_picker_gateway.dart';
import '../../../../domain/models/alarm_config.dart';
import '../../../../domain/models/community_models.dart';
import '../../../../domain/models/personal_flow_models.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/services/alarm_scheduler_service.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../../domain/services/media_picker_gateway.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_avatar_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../personal_flow/view_models/personal_flow_view_model.dart';
import '../../personal_flow/views/account_auth_card.dart';
import '../../personal_flow/views/profile_progress_card.dart';
import '../../community/views/commitment_group_sheet.dart';
import '../../study_focus/views/study_community_sheet.dart';
import '../view_models/guest_workspace_view_model.dart';
import '../widgets/weekly_leaderboard_sheet.dart';

/// Tab Tôi: Hồ sơ học sinh, cộng đồng bạn học, đồng bộ tài khoản & quyền báo thức OS.
class MeGuestScreen extends StatefulWidget {
  const MeGuestScreen({
    super.key,
    required this.viewModel,
    required this.onEditProfileAndTimetable,
    required this.onResetGuestData,
    this.personalViewModel,
    this.communityRepository,
    this.mediaPickerGateway,
    this.onDeleteAccount,
    this.onRoomJoined,
  });

  final GuestWorkspaceViewModel viewModel;
  final PersonalFlowViewModel? personalViewModel;
  final CommunityRepository? communityRepository;
  final MediaPickerGateway? mediaPickerGateway;
  final VoidCallback onEditProfileAndTimetable;
  final VoidCallback onResetGuestData;
  final Future<void> Function()? onDeleteAccount;
  final ValueChanged<StudyRoomDetail>? onRoomJoined;

  @override
  State<MeGuestScreen> createState() => _MeGuestScreenState();
}

class _MeGuestScreenState extends State<MeGuestScreen> {
  bool _confirmingDeleteAccount = false;
  bool _deletingAccount = false;
  bool _pickingAvatar = false;
  bool _syncingProfile = false;
  String? _avatarFeedbackVi;

  Future<void> _syncRealProfileNow() async {
    final PersonalFlowViewModel? pvm = personalViewModel;
    if (pvm == null || !pvm.authSession.isAuthenticated || _syncingProfile) {
      return;
    }
    setState(() {
      _syncingProfile = true;
      _avatarFeedbackVi = null;
    });
    try {
      await pvm.refreshProgressAndHistory();
      final StudyProfile? remoteProfile =
          await pvm.fetchRemoteProfileIfSignedIn();
      if (remoteProfile != null &&
          (remoteProfile.selectedSubjectCodes.isNotEmpty ||
              remoteProfile.alias.isNotEmpty)) {
        final StudyProfile merged = viewModel.profile.copyWith(
          alias: remoteProfile.alias.isNotEmpty
              ? remoteProfile.alias
              : viewModel.profile.alias,
          avatarId: remoteProfile.avatarId.isNotEmpty
              ? remoteProfile.avatarId
              : viewModel.profile.avatarId,
          gradeLevel: remoteProfile.gradeLevel ?? viewModel.profile.gradeLevel,
          selectedSubjectCodes: remoteProfile.selectedSubjectCodes.isNotEmpty
              ? remoteProfile.selectedSubjectCodes
              : viewModel.profile.selectedSubjectCodes,
          goalLabel: remoteProfile.goalLabel.isNotEmpty
              ? remoteProfile.goalLabel
              : viewModel.profile.goalLabel,
        );
        await viewModel.saveStudyProfile(merged);
      } else if (viewModel.profile.selectedSubjectCodes.isNotEmpty ||
          viewModel.profile.alias.isNotEmpty) {
        await pvm.syncProfileToServer(viewModel.profile);
      }
      final remoteTimetable = await pvm.fetchRemoteTimetableIfSignedIn();
      if (remoteTimetable != null &&
          viewModel.timetable.days.every((d) => d.entries.isEmpty)) {
        await viewModel.replaceEntireTimetable(remoteTimetable);
      }
      if (!mounted) return;
      setState(() {
        _avatarFeedbackVi = 'Đã đồng bộ hồ sơ & tiến độ.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _avatarFeedbackVi =
            'Chưa đồng bộ được lúc này. Dữ liệu trên thiết bị vẫn an toàn.';
      });
    } finally {
      if (mounted) setState(() => _syncingProfile = false);
    }
  }

  Future<void> _pickAvatarFromDevice() async {
    if (_pickingAvatar) return;
    setState(() {
      _pickingAvatar = true;
      _avatarFeedbackVi = null;
    });
    final MediaPickerGateway gateway =
        widget.mediaPickerGateway ?? MethodChannelMediaPickerGateway();
    final MediaPickResult res = await gateway.pickAvatarImage();
    if (!mounted) return;
    if (res.picked && res.localPath != null) {
      final StudyProfile next = viewModel.profile.copyWith(
        customAvatarPath: res.localPath,
      );
      await viewModel.saveStudyProfile(next);
      if (!mounted) return;
      setState(() {
        _pickingAvatar = false;
        _avatarFeedbackVi = 'Đã cập nhật ảnh đại diện từ máy.';
      });
      return;
    }
    setState(() {
      _pickingAvatar = false;
      if (!res.cancelled && res.errorMessageVi != null) {
        _avatarFeedbackVi = res.errorMessageVi;
      }
    });
  }

  Future<void> _clearCustomAvatar() async {
    final StudyProfile next = viewModel.profile.copyWith(
      clearCustomAvatarPath: true,
    );
    await viewModel.saveStudyProfile(next);
    if (!mounted) return;
    setState(() {
      _avatarFeedbackVi = 'Đã chuyển về avatar minh họa MindClock.';
    });
  }

  GuestWorkspaceViewModel get viewModel => widget.viewModel;
  PersonalFlowViewModel? get personalViewModel => widget.personalViewModel;
  VoidCallback get onEditProfileAndTimetable =>
      widget.onEditProfileAndTimetable;
  VoidCallback get onResetGuestData => widget.onResetGuestData;

  String _permissionLabel(OsPermissionState state) {
    switch (state) {
      case OsPermissionState.granted:
        return 'Đã cấp';
      case OsPermissionState.denied:
        return 'Chưa cấp';
      case OsPermissionState.unknown:
        return 'Chưa kiểm tra (chưa nối OS)';
    }
  }

  Color _parseHexColor(String hex, Color fallback) {
    final String clean = hex.replaceFirst('#', '').trim();
    if (clean.length == 6) {
      final int? v = int.tryParse('FF$clean', radix: 16);
      if (v != null) return Color(v);
    }
    return fallback;
  }

  MindClockIconKind _stampIcon(String kind) {
    switch (kind) {
      case 'sunrise':
        return MindClockIconKind.sunrise;
      case 'book':
        return MindClockIconKind.book;
      default:
        return MindClockIconKind.flame;
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final AlarmPermissionSnapshot perms = viewModel.permissionSnapshot;
    final StudyProfile profile = viewModel.profile;
    final bool isAuthed = personalViewModel?.authSession.isAuthenticated ?? false;
    final String? email = personalViewModel?.authSession.email;
    final int enabledAlarms =
        viewModel.alarms.where((AlarmConfig a) => a.enabled).length;
    final int weeklyPeriods = viewModel.timetable.days
        .fold<int>(0, (int sum, d) => sum + d.entries.length);
    final ProfileShowcase? showcase = personalViewModel?.profileShowcase;
    final ProgressSummary? progress = personalViewModel?.progressSummary;
    final int level = showcase?.level ?? progress?.level ?? 1;
    final int xp = showcase?.xp ?? progress?.xp ?? 0;
    final int streak = showcase?.streak ?? progress?.streak ?? 0;
    final int bestStreak = showcase?.bestStreak ?? progress?.bestStreak ?? 0;
    final String rankLabel =
        showcase?.seasonRank.labelVi ?? 'Đồng · Khởi hành';
    final Color rankColor = showcase != null
        ? _parseHexColor(showcase.seasonRank.frameColorHex, mc.sunrise)
        : mc.sunrise;
    final String titleVi =
        showcase?.equippedTitleVi ?? 'Bạn đồng hành MindClock';
    final int earlyDays = showcase?.earlyBirdDaysThisWeek ?? 0;
    final String topSubjName = showcase?.topSubject.subjectNameVi ??
        (profile.selectedSubjectCodes.isNotEmpty
            ? SubjectCatalog.nameFor(profile.selectedSubjectCodes.first)
            : 'Toán');
    final List<ProfileStamp> stamps = showcase?.stamps ??
        <ProfileStamp>[
          ProfileStamp(
            id: 'streak',
            titleVi: 'Chuỗi bền bỉ',
            valueVi: '$streak ngày',
            subtitleVi: 'Kỷ lục $bestStreak ngày',
            kind: 'flame',
          ),
          ProfileStamp(
            id: 'early_bird',
            titleVi: 'Dậy sớm tuần',
            valueVi: '$earlyDays/7 ngày',
            subtitleVi: 'Hoàn thành thử thách sáng',
            kind: 'sunrise',
          ),
          ProfileStamp(
            id: 'top_subject',
            titleVi: 'Sở trường',
            valueVi: 'Môn $topSubjName',
            subtitleVi: profile.gradeLevel ?? 'Lớp 11',
            kind: 'book',
          ),
        ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(mc.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AppStrings.navMe, style: mc.screenTitleStyle),
          SizedBox(height: mc.space12),
          MindClockCard(
            key: const ValueKey<String>('me-profile-summary-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Cover banner phong cách sổ tay bình minh + khung rank avatar (T085)
                Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      height: 82,
                      padding: EdgeInsets.all(mc.space12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[mc.primarySoft, mc.sunriseSoft],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(mc.radiusControl),
                        border: Border.all(color: mc.outline),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              'Hồ sơ học sinh',
                              style: mc.captionStyle.copyWith(
                                color: mc.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          SizedBox(width: mc.space8),
                          Flexible(
                            child: Wrap(
                              spacing: mc.space8,
                              runSpacing: mc.space4,
                              alignment: WrapAlignment.end,
                              children: <Widget>[
                                MindClockStatusPill(
                                  key: const ValueKey<String>(
                                      'me-season-rank-pill'),
                                  label: rankLabel,
                                  accentWarm: true,
                                ),
                                MindClockStatusPill(
                                  label: isAuthed
                                      ? 'Đã đồng bộ tài khoản'
                                      : 'Chưa đăng nhập',
                                  accentWarm: !isAuthed,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: mc.space12,
                      bottom: -24,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: mc.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: rankColor, width: 3.5),
                        ),
                        child: MindClockAvatarView(
                          avatarId: profile.avatarId,
                          customAvatarPath: profile.customAvatarPath,
                          size: 64,
                          selected: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      profile.alias.isNotEmpty
                          ? profile.alias
                          : 'Học sinh MindClock',
                      key: const ValueKey<String>('me-profile-alias'),
                      style: mc.sectionTitleStyle,
                    ),
                    MindClockStatusPill(
                      key: const ValueKey<String>('me-level-pill'),
                      label: 'Lv.$level · $xp EXP',
                    ),
                  ],
                ),
                SizedBox(height: mc.space4 / 2),
                Text(
                  isAuthed
                      ? (email ?? personalViewModel!.authSession.uid ?? 'Đã xác thực')
                      : 'Đăng nhập ở thẻ bên dưới để đồng bộ đa thiết bị',
                  key: const ValueKey<String>('me-profile-account'),
                  style: mc.captionStyle,
                ),
                SizedBox(height: mc.space8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: mc.space12,
                    vertical: mc.space8,
                  ),
                  decoration: BoxDecoration(
                    color: mc.sunriseSoft.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(mc.radiusControl),
                    border: Border.all(color: mc.sunrise),
                  ),
                  child: Wrap(
                    spacing: mc.space8,
                    runSpacing: mc.space4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      MindClockIcon(
                        MindClockIconKind.sunrise,
                        size: 16,
                        color: mc.ink,
                      ),
                      Text(
                        'Danh hiệu: $titleVi',
                        key: const ValueKey<String>('me-equipped-title'),
                        style: mc.bodyStrongStyle,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: mc.space8),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space4,
                  children: <Widget>[
                    MindClockStatusPill(
                      label: profile.gradeLevel ?? 'Lớp 11',
                      accentWarm: true,
                    ),
                    MindClockStatusPill(
                      label: '$weeklyPeriods tiết/tuần · $enabledAlarms chuông bật',
                    ),
                  ],
                ),
                SizedBox(height: mc.space12),
                // 3 ô Dấu ấn thành tích (Chuỗi, Dậy sớm tuần X/7, Sở trường môn)
                Text('Dấu ấn nổi bật', style: mc.bodyStrongStyle),
                SizedBox(height: mc.space8),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final double itemWidth = constraints.maxWidth >= 340
                        ? (constraints.maxWidth - mc.space8 * 2) / 3
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children: stamps
                          .map(
                            (ProfileStamp s) => SizedBox(
                              width: itemWidth,
                              child: Container(
                                key: ValueKey<String>('me-stamp-${s.id}'),
                                padding: EdgeInsets.all(mc.space8),
                                decoration: BoxDecoration(
                                  color: mc.paper,
                                  borderRadius:
                                      BorderRadius.circular(mc.radiusControl),
                                  border: Border.all(color: mc.outline),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Wrap(
                                      spacing: mc.space4,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: <Widget>[
                                        MindClockIcon(
                                          _stampIcon(s.kind),
                                          size: 14,
                                          color: mc.primary,
                                        ),
                                        Text(
                                          s.titleVi,
                                          style: mc.captionStyle,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: mc.space4),
                                    Text(s.valueVi, style: mc.bodyStrongStyle),
                                    Text(s.subtitleVi, style: mc.captionStyle),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
                if (showcase != null && showcase.groups.isNotEmpty) ...<Widget>[
                  SizedBox(height: mc.space12),
                  Text(
                    'Nhóm giữ chuỗi đang tham gia (${showcase.groups.length}/3)',
                    style: mc.bodyStrongStyle,
                  ),
                  SizedBox(height: mc.space8),
                  Wrap(
                    spacing: mc.space8,
                    runSpacing: mc.space8,
                    children: showcase.groups
                        .map(
                          (ProfileShowcaseGroupItem g) => Container(
                            key: ValueKey<String>('me-group-chip-${g.id}'),
                            padding: EdgeInsets.symmetric(
                              horizontal: mc.space12,
                              vertical: mc.space8,
                            ),
                            decoration: BoxDecoration(
                              color: mc.primarySoft,
                              borderRadius:
                                  BorderRadius.circular(mc.radiusControl),
                              border: Border.all(color: mc.outline),
                            ),
                            child: Text(
                              '${g.name} · Chuỗi ${g.streakDays} ngày (${g.memberCount}/${g.maxMembers})',
                              style: mc.captionStyle.copyWith(color: mc.ink),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ],
                SizedBox(height: mc.space12),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(mc.space12),
                  decoration: BoxDecoration(
                    color: mc.paper,
                    borderRadius: BorderRadius.circular(mc.radiusControl),
                    border: Border.all(color: mc.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Mục tiêu: ${profile.goalLabel.isNotEmpty ? profile.goalLabel : "Chưa đặt mục tiêu"}',
                        key: const ValueKey<String>('me-profile-goal'),
                        style: mc.bodyStrongStyle,
                      ),
                      SizedBox(height: mc.space8),
                      Text('Môn học đã chọn:', style: mc.captionStyle),
                      SizedBox(height: mc.space4),
                      if (profile.selectedSubjectCodes.isEmpty)
                        Text(
                          'Chưa chọn môn học. Bấm "Chỉnh sửa hồ sơ" để thiết lập.',
                          style: mc.captionStyle,
                        )
                      else
                        Wrap(
                          spacing: mc.space8,
                          runSpacing: mc.space8,
                          children: profile.selectedSubjectCodes
                              .map(
                                (String code) => MindClockStatusPill(
                                  label: SubjectCatalog.nameFor(code),
                                ),
                              )
                              .toList(growable: false),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: <Widget>[
                    MindClockButton(
                      key: const ValueKey<String>('me-edit-profile-top'),
                      label: 'Chỉnh sửa hồ sơ & TKB',
                      icon: MindClockIconKind.edit,
                      expand: false,
                      onPressed: onEditProfileAndTimetable,
                    ),
                    if (personalViewModel != null)
                      MindClockButton(
                        key: const ValueKey<String>(
                            'me-open-weekly-leaderboard-btn'),
                        label: 'BXH Học bá tuần',
                        icon: MindClockIconKind.sunrise,
                        variant: MindClockButtonVariant.secondary,
                        expand: false,
                        onPressed: () => showWeeklyLeaderboardSheet(
                          context: context,
                          viewModel: personalViewModel!,
                          initialSubjectCode:
                              profile.selectedSubjectCodes.isNotEmpty
                                  ? profile.selectedSubjectCodes.first
                                  : 'TOAN',
                        ),
                      ),
                    if (isAuthed)
                      MindClockButton(
                        key: const ValueKey<String>('me-sync-profile-now'),
                        label: _syncingProfile
                            ? 'Đang đồng bộ...'
                            : 'Đồng bộ hồ sơ ngay',
                        icon: MindClockIconKind.check,
                        variant: MindClockButtonVariant.secondary,
                        expand: false,
                        onPressed: _syncingProfile ? null : _syncRealProfileNow,
                      ),
                    MindClockButton(
                      key: const ValueKey<String>('me-open-commitment-group'),
                      label: 'Nhóm cam kết & Pet Mầm',
                      icon: MindClockIconKind.shield,
                      variant: MindClockButtonVariant.secondary,
                      expand: false,
                      onPressed: () => showCommitmentGroupSheet(
                        context: context,
                        repository: widget.communityRepository ??
                            DebugFixtureCommunityRepository(),
                      ),
                    ),
                    MindClockButton(
                      key: const ValueKey<String>('me-pick-avatar-btn'),
                      label: _pickingAvatar
                          ? 'Đang mở thư viện...'
                          : 'Đổi ảnh đại diện từ máy',
                      icon: MindClockIconKind.user,
                      variant: MindClockButtonVariant.subtle,
                      expand: false,
                      onPressed: _pickingAvatar ? null : _pickAvatarFromDevice,
                    ),
                    if (viewModel.profile.customAvatarPath != null)
                      MindClockButton(
                        key: const ValueKey<String>('me-clear-avatar-btn'),
                        label: 'Dùng avatar mặc định',
                        icon: MindClockIconKind.trash,
                        variant: MindClockButtonVariant.subtle,
                        expand: false,
                        onPressed: _clearCustomAvatar,
                      ),
                  ],
                ),
                if (_avatarFeedbackVi != null) ...<Widget>[
                  SizedBox(height: mc.space8),
                  Text(_avatarFeedbackVi!, style: mc.captionStyle),
                ],
              ],
            ),
          ),
          if (personalViewModel != null) ...<Widget>[
            SizedBox(height: mc.space16),
            AccountAuthCard(viewModel: personalViewModel!),
            SizedBox(height: mc.space16),
            ProfileProgressCard(viewModel: personalViewModel!),
          ],
          SizedBox(height: mc.space16),
          MindClockCard(
            key: const ValueKey<String>('me-community-card'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bạn học, Kết bạn & Hồ sơ công khai',
                  style: mc.sectionTitleStyle,
                ),
                SizedBox(height: mc.space4),
                Text(
                  'Tìm bạn cùng khối/môn, xem hồ sơ công khai, gửi lời mời kết bạn hoặc quét phòng học Meet. Giờ dậy, TKB chi tiết và email luôn ẩn.',
                  style: mc.captionStyle,
                ),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: <Widget>[
                    MindClockButton(
                      key: const ValueKey<String>('me-open-community-hub'),
                      label: 'Tìm bạn & Phòng học Meet',
                      icon: MindClockIconKind.user,
                      expand: false,
                      onPressed: () async {
                        final owner =
                            personalViewModel?.authSession.ownerScopeKey;
                        final CommunityRepository repo =
                            widget.communityRepository ??
                                DebugFixtureCommunityRepository();
                        final room = await showStudyCommunityHub(
                          context: context,
                          repository: repo,
                          currentProfile: viewModel.profile,
                        );
                        if (room != null &&
                            mounted &&
                            owner ==
                                personalViewModel?.authSession.ownerScopeKey) {
                          widget.onRoomJoined?.call(room);
                        }
                      },
                    ),
                    MindClockButton(
                      key: const ValueKey<String>('me-preview-public-profile'),
                      label: 'Xem thử hồ sơ công khai',
                      icon: MindClockIconKind.info,
                      variant: MindClockButtonVariant.secondary,
                      expand: false,
                      onPressed: () {
                        final CommunityRepository repo =
                            widget.communityRepository ??
                                DebugFixtureCommunityRepository();
                        showPublicStudentProfileDialog(
                          context: context,
                          profile: PublicStudentProfile(
                            userId: personalViewModel?.authSession.uid ?? 'self',
                            alias: viewModel.profile.alias.isNotEmpty
                                ? viewModel.profile.alias
                                : 'Học sinh MindClock',
                            avatarId: viewModel.profile.avatarId,
                            gradeLevel:
                                viewModel.profile.gradeLevel ?? 'Lớp 11',
                            selectedSubjects:
                                viewModel.profile.selectedSubjectCodes,
                            goalLabel: viewModel.profile.goalLabel,
                            studyLevel: 'exam_prep',
                            studyLevelLabelVi: 'Đang ôn thi',
                            friendStatus: 'self',
                          ),
                          repository: repo,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: mc.space16),
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Trạng thái dịch vụ báo thức',
                    style: mc.sectionTitleStyle),
                SizedBox(height: mc.space8),
                Text(
                  viewModel.isOsBridgeConnected
                      ? 'Báo thức đã sẵn sàng.'
                      : 'Đang sử dụng chế độ báo thức tiêu chuẩn trên máy.',
                  style: mc.bodyStrongStyle,
                ),
                SizedBox(height: mc.space8),
                Text(
                  'Quyền báo thức chính xác: ${_permissionLabel(perms.exactAlarm)}',
                  style: mc.captionStyle,
                ),
                Text(
                  'Quyền thông báo: ${_permissionLabel(perms.notifications)}',
                  style: mc.captionStyle,
                ),
                Text(
                  'Quyền màn hình khóa: ${_permissionLabel(perms.fullScreenIntent)}',
                  style: mc.captionStyle,
                ),
                SizedBox(height: mc.space12),
                if (!viewModel.isOsBridgeConnected)
                  const MindClockNoticeBanner(
                    message: AppStrings.alarmOsUnboundExplain,
                    isWarm: false,
                  )
                else if (viewModel.needsOsPermissions) ...<Widget>[
                  const MindClockNoticeBanner(
                    message: AppStrings.alarmPermissionMissingExplain,
                  ),
                  SizedBox(height: mc.space12),
                  ...viewModel.missingPermissionActions.map(
                    (AlarmPermissionAction action) => Padding(
                      padding: EdgeInsets.only(bottom: mc.space8),
                      child: MindClockButton(
                        key: ValueKey<String>('me-perm-${action.wireAction}'),
                        label: viewModel.labelForPermissionAction(action),
                        icon: MindClockIconKind.warning,
                        variant: MindClockButtonVariant.secondary,
                        onPressed: () =>
                            viewModel.openPermissionSettings(action),
                      ),
                    ),
                  ),
                ] else
                  const MindClockNoticeBanner(
                    message:
                        'Android đã cấp đủ quyền cốt lõi (Exact Alarm, Thông báo, Toàn màn hình khóa).',
                    isWarm: false,
                  ),
                if (viewModel.isOsBridgeConnected) ...<Widget>[
                  SizedBox(height: mc.space8),
                  Text(
                    AppStrings.batteryOptimizationNote,
                    style: mc.captionStyle,
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('me-perm-battery'),
                    label: viewModel.labelForPermissionAction(
                      AlarmPermissionAction.batteryOptimizationSettings,
                    ),
                    icon: MindClockIconKind.clock,
                    variant: MindClockButtonVariant.subtle,
                    onPressed: () => viewModel.openPermissionSettings(
                      AlarmPermissionAction.batteryOptimizationSettings,
                    ),
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('me-refresh-os-status'),
                    label: 'Kiểm tra lại quyền báo thức OS',
                    icon: MindClockIconKind.check,
                    variant: MindClockButtonVariant.subtle,
                    onPressed: viewModel.refreshOsStatus,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: mc.space16),
          MindClockButton(
            key: const ValueKey<String>('me-edit-profile'),
            label: 'Chỉnh hồ sơ & Thời khóa biểu 7 ngày',
            icon: MindClockIconKind.edit,
            variant: MindClockButtonVariant.secondary,
            onPressed: onEditProfileAndTimetable,
          ),
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('me-reset-local'),
            label: 'Thiết lập lại dữ liệu ứng dụng',
            icon: MindClockIconKind.trash,
            variant: MindClockButtonVariant.subtle,
            onPressed: onResetGuestData,
          ),
          if (personalViewModel != null &&
              personalViewModel!.authSession.isAuthenticated &&
              widget.onDeleteAccount != null) ...<Widget>[
            SizedBox(height: mc.space16),
            if (!_confirmingDeleteAccount)
              MindClockButton(
                key: const ValueKey<String>('me-delete-account-btn'),
                label: 'Xóa tài khoản & dữ liệu trực tuyến',
                icon: MindClockIconKind.trash,
                variant: MindClockButtonVariant.subtle,
                onPressed: _deletingAccount
                    ? null
                    : () => setState(() => _confirmingDeleteAccount = true),
              )
            else
              MindClockCard(
                key: const ValueKey<String>('me-delete-account-confirm-card'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Xác nhận xóa tài khoản trực tuyến?',
                      style: mc.sectionTitleStyle,
                    ),
                    SizedBox(height: mc.space8),
                    Text(
                      'Hành động này xóa tài khoản, hồ sơ và lịch học của bạn. Báo thức đã đặt trên máy vẫn được giữ nguyên.',
                      style: mc.captionStyle,
                    ),
                    SizedBox(height: mc.space12),
                    MindClockButton(
                      key: const ValueKey<String>('me-delete-account-confirm'),
                      label: _deletingAccount
                          ? 'Đang xóa tài khoản...'
                          : 'Xác nhận xóa tài khoản',
                      icon: MindClockIconKind.trash,
                      variant: MindClockButtonVariant.primary,
                      onPressed: _deletingAccount
                          ? null
                          : () async {
                              setState(() => _deletingAccount = true);
                              try {
                                await widget.onDeleteAccount!();
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _deletingAccount = false;
                                    _confirmingDeleteAccount = false;
                                  });
                                }
                              }
                            },
                    ),
                    SizedBox(height: mc.space8),
                    MindClockButton(
                      key: const ValueKey<String>('me-delete-account-cancel'),
                      label: 'Giữ lại tài khoản',
                      icon: MindClockIconKind.check,
                      variant: MindClockButtonVariant.subtle,
                      onPressed: _deletingAccount
                          ? null
                          : () =>
                              setState(() => _confirmingDeleteAccount = false),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
