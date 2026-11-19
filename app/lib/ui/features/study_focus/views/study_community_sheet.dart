import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/community_models.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_avatar_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';

/// Avatar 2D cử động liên tục (chớp mắt, gật nhẹ, nhép miệng khi trả lời) gắn nhãn MindClock AI rõ ràng.
class MindClockAiAnimatedAvatar extends StatefulWidget {
  const MindClockAiAnimatedAvatar({
    super.key,
    this.size = 64,
    this.isThinking = false,
    this.isSpeaking = false,
    this.animate = true,
    this.statusLabelVi = 'Đang đồng hành cùng bạn',
  });

  final double size;
  final bool isThinking;
  final bool isSpeaking;
  final bool animate;
  final String statusLabelVi;

  @override
  State<MindClockAiAnimatedAvatar> createState() =>
      _MindClockAiAnimatedAvatarState();
}

class _MindClockAiAnimatedAvatarState extends State<MindClockAiAnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  void _syncAnimationState() {
    final bool shouldAnimate =
        widget.animate && !MediaQuery.disableAnimationsOf(context);
    if (!shouldAnimate) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant MindClockAiAnimatedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      _syncAnimationState();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);

    Widget buildFace(double t) {
      final double phase = reduceMotion ? 0 : t;
      // Chớp mắt tự nhiên ở khoảng t = 0.86..0.94
      final bool isBlinking = !reduceMotion && phase > 0.86 && phase < 0.94;
      final double bobY =
          reduceMotion ? 0 : math.sin(phase * 2 * math.pi) * 2.2;
      final double mouthOpen = widget.isSpeaking && !reduceMotion
          ? (0.35 + 0.65 * math.sin(phase * 12 * math.pi).abs())
          : (widget.isThinking ? 0.25 : 0.1);

      return Transform.translate(
        offset: Offset(0, bobY),
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: _AiAvatar2dPainter(
              bgColor: mc.primary,
              faceColor: mc.surface,
              featureColor: mc.night,
              accentColor: mc.sunrise,
              borderColor: mc.sunrise,
              isBlinking: isBlinking,
              isThinking: widget.isThinking,
              mouthOpenFactor: mouthOpen,
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        reduceMotion
            ? buildFace(0)
            : AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => buildFace(_controller.value),
              ),
        SizedBox(height: mc.space4),
        const MindClockStatusPill(
          key: ValueKey<String>('ai-2d-avatar-badge'),
          label: 'MindClock AI',
        ),
        SizedBox(height: mc.space4),
        Text(
          widget.statusLabelVi,
          textAlign: TextAlign.center,
          style: mc.captionStyle.copyWith(color: mc.nightText),
        ),
      ],
    );
  }
}

class _AiAvatar2dPainter extends CustomPainter {
  _AiAvatar2dPainter({
    required this.bgColor,
    required this.faceColor,
    required this.featureColor,
    required this.accentColor,
    required this.borderColor,
    required this.isBlinking,
    required this.isThinking,
    required this.mouthOpenFactor,
  });

  final Color bgColor;
  final Color faceColor;
  final Color featureColor;
  final Color accentColor;
  final Color borderColor;
  final bool isBlinking;
  final bool isThinking;
  final double mouthOpenFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide / 2 - 2;

    canvas.drawCircle(center, r, Paint()..color = bgColor);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    // Mặt 2D bo tròn thân thiện
    final Rect headRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + r * 0.04),
      width: r * 1.24,
      height: r * 1.12,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(r * 0.45)),
      Paint()..color = faceColor,
    );

    // Ăng-ten/tia sáng trí tuệ
    canvas.drawLine(
      Offset(center.dx, center.dy - r * 0.52),
      Offset(center.dx, center.dy - r * 0.78),
      Paint()
        ..color = accentColor
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(center.dx, center.dy - r * 0.82),
      r * 0.1,
      Paint()..color = accentColor,
    );

    final double eyeY = center.dy - r * 0.06;
    final double eyeDx = r * 0.25;
    final Paint eyePaint = Paint()
      ..color = featureColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    if (isBlinking) {
      canvas.drawLine(
        Offset(center.dx - eyeDx - r * 0.08, eyeY),
        Offset(center.dx - eyeDx + r * 0.08, eyeY),
        eyePaint,
      );
      canvas.drawLine(
        Offset(center.dx + eyeDx - r * 0.08, eyeY),
        Offset(center.dx + eyeDx + r * 0.08, eyeY),
        eyePaint,
      );
    } else {
      canvas.drawCircle(Offset(center.dx - eyeDx, eyeY), r * 0.09, eyePaint);
      canvas.drawCircle(Offset(center.dx + eyeDx, eyeY), r * 0.09, eyePaint);
    }

    // Chân mày biểu thị trạng thái suy nghĩ nhẹ
    final double browOffset = isThinking ? -r * 0.05 : 0;
    canvas.drawLine(
      Offset(center.dx - eyeDx - r * 0.1, eyeY - r * 0.18 + browOffset),
      Offset(center.dx - eyeDx + r * 0.1, eyeY - r * 0.2),
      eyePaint..strokeWidth = 1.6,
    );
    canvas.drawLine(
      Offset(center.dx + eyeDx - r * 0.1, eyeY - r * 0.2),
      Offset(center.dx + eyeDx + r * 0.1, eyeY - r * 0.18 + browOffset),
      eyePaint..strokeWidth = 1.6,
    );

    // Miệng mỉm cười hoặc mở theo nhịp nói
    final Rect mouthRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + r * 0.24),
      width: r * 0.34,
      height: r * (0.1 + 0.18 * mouthOpenFactor),
    );
    if (mouthOpenFactor > 0.2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(mouthRect, Radius.circular(r * 0.1)),
        Paint()..color = featureColor,
      );
    } else {
      final Path smile = Path()
        ..moveTo(center.dx - r * 0.16, center.dy + r * 0.22)
        ..quadraticBezierTo(
          center.dx,
          center.dy + r * 0.34,
          center.dx + r * 0.16,
          center.dy + r * 0.22,
        );
      canvas.drawPath(
        smile,
        Paint()
          ..color = featureColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AiAvatar2dPainter oldDelegate) {
    return oldDelegate.isBlinking != isBlinking ||
        oldDelegate.isThinking != isThinking ||
        (oldDelegate.mouthOpenFactor - mouthOpenFactor).abs() > 0.05;
  }
}

/// Modal xem Hồ sơ học sinh công khai (Avatar + Lớp + Môn học + Mục tiêu + Kết bạn/Chặn).
Future<void> showPublicStudentProfileDialog({
  required BuildContext context,
  required PublicStudentProfile profile,
  required CommunityRepository repository,
  VoidCallback? onUpdated,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.mc.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.mc.radiusPaper),
      ),
    ),
    builder: (BuildContext sheetContext) {
      return _PublicProfileSheetBody(
        initialProfile: profile,
        repository: repository,
        onUpdated: onUpdated,
      );
    },
  );
}

class _PublicProfileSheetBody extends StatefulWidget {
  const _PublicProfileSheetBody({
    required this.initialProfile,
    required this.repository,
    this.onUpdated,
  });

  final PublicStudentProfile initialProfile;
  final CommunityRepository repository;
  final VoidCallback? onUpdated;

  @override
  State<_PublicProfileSheetBody> createState() =>
      _PublicProfileSheetBodyState();
}

class _PublicProfileSheetBodyState extends State<_PublicProfileSheetBody> {
  late PublicStudentProfile _profile;
  bool _busy = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _profile = widget.initialProfile;
  }

  Future<void> _sendFriend() async {
    setState(() => _busy = true);
    try {
      await widget.repository.sendFriendRequest(
        _profile.userId,
        messageVi: 'Chào bạn, cùng học nhóm trên MindClock nhé!',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _profile = _profile.copyWith(friendStatus: 'outgoing_pending');
        _statusMessage = 'Đã gửi lời mời kết bạn.';
      });
      widget.onUpdated?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusMessage = 'Không gửi được lời mời lúc này.';
      });
    }
  }

  Future<void> _acceptFriend() async {
    final String? reqId = _profile.pendingRequestId;
    if (reqId == null || reqId.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.repository.respondFriendRequest(reqId, 'accept');
      if (!mounted) return;
      setState(() {
        _busy = false;
        _profile = _profile.copyWith(friendStatus: 'friends');
        _statusMessage = 'Hai bạn đã trở thành bạn học!';
      });
      widget.onUpdated?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusMessage = 'Không chấp nhận được lời mời lúc này.';
      });
    }
  }

  Future<void> _blockUser() async {
    setState(() => _busy = true);
    try {
      await widget.repository.blockUser(_profile.userId, reason: 'user_action');
      if (!mounted) return;
      widget.onUpdated?.call();
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _statusMessage = 'Chưa chặn được người dùng.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(mc.space20),
        child: Column(
          key: ValueKey<String>('public-profile-sheet-${_profile.userId}'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                MindClockAvatarView(
                  avatarId: _profile.avatarId,
                  size: 56,
                  selected: true,
                ),
                SizedBox(width: mc.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(_profile.alias, style: mc.sectionTitleStyle),
                      SizedBox(height: mc.space4),
                      Text(
                        '${_profile.gradeLevel} · ${_profile.studyLevelLabelVi}',
                        style: mc.captionStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
                  Text('Môn đang học:', style: mc.bodyStrongStyle),
                  SizedBox(height: mc.space4),
                  Text(_profile.subjectSummaryVi, style: mc.bodyStyle),
                  if (_profile.goalLabel.isNotEmpty) ...<Widget>[
                    SizedBox(height: mc.space8),
                    Text('Mục tiêu:', style: mc.bodyStrongStyle),
                    SizedBox(height: mc.space4),
                    Text(_profile.goalLabel, style: mc.bodyStyle),
                  ],
                  SizedBox(height: mc.space8),
                  Text(
                    'Quyền riêng tư: Giờ dậy, TKB chi tiết và email luôn ẩn.',
                    style: mc.captionStyle,
                  ),
                ],
              ),
            ),
            if (_statusMessage != null) ...<Widget>[
              SizedBox(height: mc.space12),
              MindClockNoticeBanner(message: _statusMessage!, isWarm: false),
            ],
            SizedBox(height: mc.space16),
            if (_profile.friendStatus == 'friends')
              const MindClockStatusPill(label: 'Đã kết bạn')
            else if (_profile.friendStatus == 'outgoing_pending')
              const MindClockStatusPill(
                label: 'Đã gửi lời mời kết bạn',
                accentWarm: true,
              )
            else if (_profile.friendStatus == 'incoming_pending')
              MindClockButton(
                key: ValueKey<String>('profile-accept-${_profile.userId}'),
                label: 'Chấp nhận lời mời kết bạn',
                icon: MindClockIconKind.check,
                onPressed: _busy ? null : _acceptFriend,
              )
            else if (_profile.friendStatus != 'self')
              MindClockButton(
                key: ValueKey<String>('profile-add-friend-${_profile.userId}'),
                label: 'Kết bạn ôn thi',
                icon: MindClockIconKind.user,
                onPressed: _busy ? null : _sendFriend,
              ),
            if (_profile.friendStatus != 'self') ...<Widget>[
              SizedBox(height: mc.space8),
              MindClockButton(
                key: ValueKey<String>('profile-block-${_profile.userId}'),
                label: 'Chặn người dùng này',
                variant: MindClockButtonVariant.subtle,
                onPressed: _busy ? null : _blockUser,
              ),
            ],
            SizedBox(height: mc.space8),
            MindClockButton(
              label: 'Đóng',
              variant: MindClockButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Giao diện Phòng học nhiều người kiểu Google Meet (lưới thẻ Avatar/Cam + Mic/Cam toggle + AI 2D cử động).
class MeetStudyRoomGrid extends StatelessWidget {
  const MeetStudyRoomGrid({
    super.key,
    required this.room,
    required this.repository,
    required this.onToggleMic,
    required this.onToggleCam,
    required this.onToggleAi,
    required this.onLeaveRoom,
    this.animateAi = true,
    this.onRefreshNeeded,
  });

  final StudyRoomDetail room;
  final CommunityRepository repository;
  final VoidCallback onToggleMic;
  final VoidCallback onToggleCam;
  final VoidCallback onToggleAi;
  final VoidCallback onLeaveRoom;
  final bool animateAi;
  final VoidCallback? onRefreshNeeded;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final StudyRoomMemberTile selfTile = room.members.firstWhere(
      (StudyRoomMemberTile m) => m.isSelf,
      orElse: () => const StudyRoomMemberTile(
        userId: 'self',
        alias: 'Bạn',
        isSelf: true,
      ),
    );

    return Container(
      key: const ValueKey<String>('meet-study-room-panel'),
      width: double.infinity,
      padding: EdgeInsets.all(mc.space16),
      decoration: BoxDecoration(
        color: mc.night,
        borderRadius: BorderRadius.circular(mc.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text(
                'Phòng Meet: ${room.summary.title}',
                style: mc.sectionTitleStyle.copyWith(color: mc.nightText),
              ),
              MindClockStatusPill(
                label:
                    '${room.summary.visibility == 'public' ? 'Công khai' : 'Chỉ mời'} · Mã ${room.summary.roomCode}',
              ),
            ],
          ),
          SizedBox(height: mc.space4),
          Text(
            '${room.summary.subjectNameVi} · ${room.summary.gradeLevel} · ${room.members.length}/${room.summary.maxMembers} thành viên',
            style: mc.captionStyle.copyWith(color: mc.sunrise),
          ),
          SizedBox(height: mc.space12),
          LayoutBuilder(
            builder: (BuildContext ctx, BoxConstraints constraints) {
              final double scale = MediaQuery.textScalerOf(ctx).scale(1.0);
              final int cols =
                  (constraints.maxWidth < 290 || scale >= 1.6) ? 1 : 2;
              final double cardWidth = cols == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - mc.space8) / 2;

              final List<Widget> tiles = <Widget>[
                ...room.members.map((StudyRoomMemberTile member) {
                  return SizedBox(
                    width: cardWidth,
                    child: MindClockPressable(
                      key: ValueKey<String>('meet-tile-${member.userId}'),
                      semanticLabel: 'Xem hồ sơ ${member.alias}',
                      onPressed: () {
                        if (member.isSelf) return;
                        showPublicStudentProfileDialog(
                          context: context,
                          profile: PublicStudentProfile(
                            userId: member.userId,
                            alias: member.alias,
                            avatarId: member.avatarId,
                            gradeLevel: member.gradeLevel,
                            selectedSubjects: <String>[room.summary.subjectCode],
                          ),
                          repository: repository,
                          onUpdated: onRefreshNeeded,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(mc.space12),
                        decoration: BoxDecoration(
                          color: mc.nightSurface,
                          borderRadius:
                              BorderRadius.circular(mc.radiusControl),
                          border: Border.all(
                            color: member.camEnabled ? mc.sunrise : mc.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            MindClockAvatarView(
                              avatarId: member.avatarId,
                              size: 54,
                              selected: member.camEnabled,
                            ),
                            SizedBox(height: mc.space8),
                            Text(
                              member.isSelf ? '${member.alias} (Bạn)' : member.alias,
                              textAlign: TextAlign.center,
                              style: mc.bodyStrongStyle
                                  .copyWith(color: mc.nightText),
                            ),
                            SizedBox(height: mc.space4),
                            Text(
                              member.camEnabled ? 'Camera: Đang bật' : member.statusNote,
                              textAlign: TextAlign.center,
                              style: mc.captionStyle.copyWith(
                                color: member.camEnabled
                                    ? mc.sunrise
                                    : mc.nightText,
                              ),
                            ),
                            SizedBox(height: mc.space4),
                            Wrap(
                              spacing: mc.space4,
                              runSpacing: mc.space4,
                              alignment: WrapAlignment.center,
                              children: <Widget>[
                                _MeetBadge(
                                  label: member.micEnabled ? 'Mic Bật' : 'Mic Tắt',
                                  active: member.micEnabled,
                                ),
                                _MeetBadge(
                                  label: member.camEnabled ? 'Cam Bật' : 'Cam Tắt',
                                  active: member.camEnabled,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (room.summary.aiCompanionEnabled)
                  SizedBox(
                    width: cardWidth,
                    child: Container(
                      key: const ValueKey<String>('meet-tile-mindclock-ai'),
                      padding: EdgeInsets.all(mc.space12),
                      decoration: BoxDecoration(
                        color: mc.nightSurface,
                        borderRadius: BorderRadius.circular(mc.radiusControl),
                        border: Border.all(color: mc.sunrise, width: 1.5),
                      ),
                      child: Center(
                        child: MindClockAiAnimatedAvatar(
                          size: 56,
                          animate: animateAi,
                          statusLabelVi: 'Sẵn sàng gợi mở khi bạn hỏi',
                        ),
                      ),
                    ),
                  ),
              ];

              return Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                children: tiles,
              );
            },
          ),
          SizedBox(height: mc.space12),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: <Widget>[
              MindClockButton(
                key: const ValueKey<String>('meet-toggle-mic'),
                label: selfTile.micEnabled ? 'Tắt Mic' : 'Bật Mic',
                icon: selfTile.micEnabled
                    ? MindClockIconKind.volumeOn
                    : MindClockIconKind.volumeOff,
                variant: MindClockButtonVariant.secondary,
                expand: false,
                onPressed: onToggleMic,
              ),
              MindClockButton(
                key: const ValueKey<String>('meet-toggle-cam'),
                label: selfTile.camEnabled ? 'Tắt Cam' : 'Bật Cam',
                icon: MindClockIconKind.user,
                variant: MindClockButtonVariant.secondary,
                expand: false,
                onPressed: onToggleCam,
              ),
              MindClockButton(
                key: const ValueKey<String>('meet-toggle-ai'),
                label: room.summary.aiCompanionEnabled
                    ? 'Ẩn MindClock AI'
                    : 'Mời MindClock AI',
                icon: MindClockIconKind.info,
                variant: MindClockButtonVariant.subtle,
                expand: false,
                onPressed: onToggleAi,
              ),
              MindClockButton(
                key: const ValueKey<String>('meet-leave-room'),
                label: 'Rời phòng',
                icon: MindClockIconKind.stop,
                expand: false,
                onPressed: onLeaveRoom,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeetBadge extends StatelessWidget {
  const _MeetBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: mc.space8, vertical: 2),
      decoration: BoxDecoration(
        color: active ? mc.primary : mc.night,
        borderRadius: BorderRadius.circular(mc.radiusChip),
        border: Border.all(color: active ? mc.sunrise : mc.outline),
      ),
      child: Text(
        label,
        style: mc.captionStyle.copyWith(
          color: mc.nightText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// BottomSheet Gói B: Quét phòng Meet công khai, AI ghép nhóm theo trình độ, Tìm bạn & Hồ sơ công khai.
Future<StudyRoomDetail?> showStudyCommunityHub({
  required BuildContext context,
  required CommunityRepository repository,
  required StudyProfile currentProfile,
}) {
  return showModalBottomSheet<StudyRoomDetail>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.mc.paper,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.mc.radiusPaper),
      ),
    ),
    builder: (BuildContext sheetContext) {
      return _StudyCommunityHubBody(
        repository: repository,
        currentProfile: currentProfile,
      );
    },
  );
}

class _StudyCommunityHubBody extends StatefulWidget {
  const _StudyCommunityHubBody({
    required this.repository,
    required this.currentProfile,
  });

  final CommunityRepository repository;
  final StudyProfile currentProfile;

  @override
  State<_StudyCommunityHubBody> createState() => _StudyCommunityHubBodyState();
}

class _StudyCommunityHubBodyState extends State<_StudyCommunityHubBody> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _roomTitleController = TextEditingController();

  int _tabIndex = 0; // 0: Quét phòng & AI ghép nhóm, 1: Tìm bạn & Kết bạn
  bool _loading = true;
  bool _showCreateRoomForm = false;
  bool _newRoomPublic = true;
  bool _newRoomAiEnabled = true;

  List<PublicStudyRoomSummary> _publicRooms = <PublicStudyRoomSummary>[];
  List<PublicStudentProfile> _searchResults = <PublicStudentProfile>[];
  List<PublicStudentProfile> _friends = <PublicStudentProfile>[];
  List<FriendRequestItem> _incomingRequests = <FriendRequestItem>[];
  StudyAiMatchResult? _aiMatch;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _roomTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final List<PublicStudyRoomSummary> rooms =
          await widget.repository.listPublicRooms();
      final List<PublicStudentProfile> users =
          await widget.repository.searchUsers(query: _searchController.text);
      final List<PublicStudentProfile> friends =
          await widget.repository.fetchFriends();
      final ({List<FriendRequestItem> incoming, List<FriendRequestItem> outgoing})
          reqs = await widget.repository.fetchFriendRequests();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _publicRooms = rooms;
        _searchResults = users;
        _friends = friends;
        _incomingRequests = reqs.incoming;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMessage = 'Chưa tải được dữ liệu cộng đồng. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _runAiMatch() async {
    setState(() => _loading = true);
    try {
      final String subj =
          widget.currentProfile.selectedSubjectCodes.isNotEmpty
              ? widget.currentProfile.selectedSubjectCodes.first
              : 'math';
      final StudyAiMatchResult res = await widget.repository.aiMatchGroups(
        gradeLevel: widget.currentProfile.gradeLevel,
        subjectCode: subj,
        targetLevel: 'exam_prep',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _aiMatch = res;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMessage = 'Chưa chạy được AI ghép nhóm lúc này.';
      });
    }
  }

  Future<void> _createAndEnterRoom() async {
    final String title = _roomTitleController.text.trim();
    if (title.isEmpty) {
      setState(() => _statusMessage = 'Nhập tên phòng học trước khi tạo.');
      return;
    }
    setState(() => _loading = true);
    try {
      final String subj =
          widget.currentProfile.selectedSubjectCodes.isNotEmpty
              ? widget.currentProfile.selectedSubjectCodes.first
              : 'math';
      final StudyRoomDetail detail = await widget.repository.createRoom(
        title: title,
        subjectCode: subj,
        gradeLevel: widget.currentProfile.gradeLevel ?? 'Lớp 11',
        targetLevel: 'exam_prep',
        visibility: _newRoomPublic ? 'public' : 'invite_only',
        maxMembers: 6,
        aiCompanionEnabled: _newRoomAiEnabled,
      );
      if (!mounted) return;
      Navigator.of(context).pop(detail);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMessage = 'Không tạo được phòng học lúc này.';
      });
    }
  }

  Future<void> _joinAndEnterRoom(String roomId) async {
    setState(() => _loading = true);
    try {
      final StudyRoomDetail detail = await widget.repository.joinRoom(roomId);
      if (!mounted) return;
      Navigator.of(context).pop(detail);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMessage = 'Không tham gia được phòng lúc này.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.88,
        child: Column(
          key: const ValueKey<String>('study-community-hub-sheet'),
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(mc.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          'Cộng đồng, Bạn học & Phòng Meet',
                          style: mc.sectionTitleStyle,
                        ),
                        if (widget.repository.isDebugFixture)
                          const MindClockStatusPill(
                            label: 'Dữ liệu mẫu offline',
                          ),
                      ],
                    ),
                    SizedBox(height: mc.space12),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children: <Widget>[
                        MindClockButton(
                          key: const ValueKey<String>('community-tab-rooms'),
                          label: 'Phòng công khai & AI ghép nhóm',
                          variant: _tabIndex == 0
                              ? MindClockButtonVariant.primary
                              : MindClockButtonVariant.secondary,
                          expand: false,
                          onPressed: () => setState(() => _tabIndex = 0),
                        ),
                        MindClockButton(
                          key: const ValueKey<String>('community-tab-friends'),
                          label:
                              'Tìm bạn & Kết bạn (${_incomingRequests.length})',
                          variant: _tabIndex == 1
                              ? MindClockButtonVariant.primary
                              : MindClockButtonVariant.secondary,
                          expand: false,
                          onPressed: () => setState(() => _tabIndex = 1),
                        ),
                      ],
                    ),
                    if (_statusMessage != null) ...<Widget>[
                      SizedBox(height: mc.space12),
                      MindClockNoticeBanner(message: _statusMessage!),
                    ],
                    SizedBox(height: mc.space12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      (_tabIndex == 0
                          ? _buildRoomsTab(mc)
                          : _buildFriendsTab(mc)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: mc.space16,
                vertical: mc.space8,
              ),
              child: MindClockButton(
                key: const ValueKey<String>('community-close-btn'),
                label: 'Đóng',
                variant: MindClockButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsTab(MindClockTheme mc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: mc.space8,
          runSpacing: mc.space8,
          children: <Widget>[
            MindClockButton(
              key: const ValueKey<String>('community-ai-match-btn'),
              label: 'AI ghép nhóm theo trình độ',
              icon: MindClockIconKind.sunrise,
              expand: false,
              onPressed: _runAiMatch,
            ),
            MindClockButton(
              key: const ValueKey<String>('community-create-room-toggle'),
              label: _showCreateRoomForm ? 'Ẩn form tạo phòng' : 'Tạo phòng học',
              icon: MindClockIconKind.plus,
              variant: MindClockButtonVariant.secondary,
              expand: false,
              onPressed: () =>
                  setState(() => _showCreateRoomForm = !_showCreateRoomForm),
            ),
          ],
        ),
        if (_showCreateRoomForm) ...<Widget>[
          SizedBox(height: mc.space12),
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Tạo phòng học nhóm mới', style: mc.bodyStrongStyle),
                SizedBox(height: mc.space8),
                TextField(
                  key: const ValueKey<String>('community-room-title-input'),
                  controller: _roomTitleController,
                  decoration: InputDecoration(
                    labelText: 'Tên phòng học',
                    hintText: 'VD: Giải đề Toán 11 tối nay',
                    filled: true,
                    fillColor: mc.paper,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(mc.radiusControl),
                    ),
                  ),
                ),
                SizedBox(height: mc.space8),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: <Widget>[
                    MindClockPressable(
                      key: const ValueKey<String>('community-vis-public'),
                      selected: _newRoomPublic,
                      semanticLabel: 'Phòng công khai',
                      onPressed: () => setState(() => _newRoomPublic = true),
                      child: MindClockStatusPill(
                        label: 'Công khai (Ai cũng quét thấy)',
                        accentWarm: !_newRoomPublic,
                      ),
                    ),
                    MindClockPressable(
                      key: const ValueKey<String>('community-vis-private'),
                      selected: !_newRoomPublic,
                      semanticLabel: 'Phòng chỉ mời',
                      onPressed: () => setState(() => _newRoomPublic = false),
                      child: MindClockStatusPill(
                        label: 'Chỉ mời (Riêng tư)',
                        accentWarm: _newRoomPublic,
                      ),
                    ),
                    MindClockPressable(
                      key: const ValueKey<String>('community-ai-toggle'),
                      selected: _newRoomAiEnabled,
                      semanticLabel: 'Thêm MindClock AI vào phòng',
                      onPressed: () => setState(
                        () => _newRoomAiEnabled = !_newRoomAiEnabled,
                      ),
                      child: MindClockStatusPill(
                        label: _newRoomAiEnabled
                            ? 'Có MindClock AI 2D'
                            : 'Không dùng AI',
                        accentWarm: !_newRoomAiEnabled,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: mc.space12),
                MindClockButton(
                  key: const ValueKey<String>('community-create-room-submit'),
                  label: 'Mở phòng Meet ngay',
                  icon: MindClockIconKind.play,
                  onPressed: _createAndEnterRoom,
                ),
              ],
            ),
          ),
        ],
        if (_aiMatch != null) ...<Widget>[
          SizedBox(height: mc.space16),
          Text(
            'Gợi ý phù hợp trình độ của bạn (AI Matching)',
            key: const ValueKey<String>('community-ai-match-heading'),
            style: mc.bodyStrongStyle,
          ),
          SizedBox(height: mc.space8),
          ..._aiMatch!.recommendedRooms.map(
            (PublicStudyRoomSummary r) => _RoomTile(
              room: r,
              isHighlighted: true,
              keyPrefix: 'community-ai-join-',
              onJoin: () => _joinAndEnterRoom(r.roomId),
            ),
          ),
        ],
        SizedBox(height: mc.space16),
        Text('Phòng học công khai đang mở', style: mc.bodyStrongStyle),
        SizedBox(height: mc.space8),
        if (_publicRooms.isEmpty)
          const MindClockNoticeBanner(
            message: 'Chưa có phòng công khai nào. Bạn có thể tạo phòng mới!',
            isWarm: false,
          )
        else
          ..._publicRooms.map(
            (PublicStudyRoomSummary r) => _RoomTile(
              room: r,
              isHighlighted: false,
              onJoin: () => _joinAndEnterRoom(r.roomId),
            ),
          ),
      ],
    );
  }

  Widget _buildFriendsTab(MindClockTheme mc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                key: const ValueKey<String>('community-friend-search-input'),
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Tìm bạn học theo biệt danh',
                  filled: true,
                  fillColor: mc.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(mc.radiusControl),
                  ),
                ),
              ),
            ),
            SizedBox(width: mc.space8),
            MindClockButton(
              key: const ValueKey<String>('community-friend-search-btn'),
              label: 'Tìm',
              expand: false,
              onPressed: _loadAll,
            ),
          ],
        ),
        if (_incomingRequests.isNotEmpty) ...<Widget>[
          SizedBox(height: mc.space16),
          Text('Lời mời kết bạn gửi tới bạn', style: mc.bodyStrongStyle),
          SizedBox(height: mc.space8),
          ..._incomingRequests.map((FriendRequestItem req) {
            return Padding(
              padding: EdgeInsets.only(bottom: mc.space8),
              child: MindClockCard(
                highlighted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _PeerHeaderRow(peer: req.peer),
                    if (req.messageVi.isNotEmpty) ...<Widget>[
                      SizedBox(height: mc.space4),
                      Text(req.messageVi, style: mc.captionStyle),
                    ],
                    SizedBox(height: mc.space8),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children: <Widget>[
                        MindClockButton(
                          key: ValueKey<String>(
                            'community-accept-${req.requestId}',
                          ),
                          label: 'Chấp nhận',
                          icon: MindClockIconKind.check,
                          expand: false,
                          onPressed: () async {
                            await widget.repository
                                .respondFriendRequest(req.requestId, 'accept');
                            await _loadAll();
                          },
                        ),
                        MindClockButton(
                          label: 'Từ chối',
                          variant: MindClockButtonVariant.secondary,
                          expand: false,
                          onPressed: () async {
                            await widget.repository
                                .respondFriendRequest(req.requestId, 'decline');
                            await _loadAll();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
        if (_friends.isNotEmpty) ...<Widget>[
          SizedBox(height: mc.space16),
          Text('Bạn học của bạn (${_friends.length})', style: mc.bodyStrongStyle),
          SizedBox(height: mc.space8),
          ..._friends.map(
            (PublicStudentProfile p) => _PeerCard(
              peer: p,
              onTapProfile: () => showPublicStudentProfileDialog(
                context: context,
                profile: p,
                repository: widget.repository,
                onUpdated: _loadAll,
              ),
            ),
          ),
        ],
        SizedBox(height: mc.space16),
        Text('Khám phá bạn học cùng THPT', style: mc.bodyStrongStyle),
        SizedBox(height: mc.space8),
        ..._searchResults.map(
          (PublicStudentProfile p) => _PeerCard(
            peer: p,
            onTapProfile: () => showPublicStudentProfileDialog(
              context: context,
              profile: p,
              repository: widget.repository,
              onUpdated: _loadAll,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.isHighlighted,
    required this.onJoin,
    this.keyPrefix = 'community-join-',
  });

  final PublicStudyRoomSummary room;
  final bool isHighlighted;
  final VoidCallback onJoin;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Padding(
      padding: EdgeInsets.only(bottom: mc.space8),
      child: MindClockCard(
        highlighted: isHighlighted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: mc.space8,
              runSpacing: mc.space4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                Text(room.title, style: mc.bodyStrongStyle),
                MindClockStatusPill(
                  label: '${room.memberCount}/${room.maxMembers} người',
                ),
              ],
            ),
            SizedBox(height: mc.space4),
            Text(
              '${SubjectCatalog.nameFor(room.subjectCode)} · ${room.gradeLevel} · ${room.targetLevelLabelVi} · Chủ phòng: ${room.ownerAlias}',
              style: mc.captionStyle,
            ),
            if (room.matchReasonVi != null) ...<Widget>[
              SizedBox(height: mc.space4),
              Text(
                'AI gợi ý: ${room.matchReasonVi}',
                style: mc.captionStyle.copyWith(
                  color: mc.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            SizedBox(height: mc.space8),
            MindClockButton(
              key: ValueKey<String>('$keyPrefix${room.roomId}'),
              label: 'Vào phòng học Meet',
              icon: MindClockIconKind.play,
              expand: false,
              onPressed: onJoin,
            ),
          ],
        ),
      ),
    );
  }
}

class _PeerHeaderRow extends StatelessWidget {
  const _PeerHeaderRow({required this.peer});

  final PublicStudentProfile peer;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Row(
      children: <Widget>[
        MindClockAvatarView(
          avatarId: peer.avatarId,
          size: 40,
        ),
        SizedBox(width: mc.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(peer.alias, style: mc.bodyStrongStyle),
              Text(
                '${peer.gradeLevel} · ${peer.studyLevelLabelVi}',
                style: mc.captionStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PeerCard extends StatelessWidget {
  const _PeerCard({
    required this.peer,
    required this.onTapProfile,
  });

  final PublicStudentProfile peer;
  final VoidCallback onTapProfile;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Padding(
      padding: EdgeInsets.only(bottom: mc.space8),
      child: MindClockCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _PeerHeaderRow(peer: peer),
            SizedBox(height: mc.space4),
            Text('Môn: ${peer.subjectSummaryVi}', style: mc.captionStyle),
            if (peer.matchReasonVi != null) ...<Widget>[
              SizedBox(height: mc.space4),
              Text(
                peer.matchReasonVi!,
                style: mc.captionStyle.copyWith(color: mc.primary),
              ),
            ],
            SizedBox(height: mc.space8),
            MindClockButton(
              key: ValueKey<String>('community-profile-${peer.userId}'),
              label: 'Xem Profile & Kết bạn',
              variant: MindClockButtonVariant.secondary,
              expand: false,
              onPressed: onTapProfile,
            ),
          ],
        ),
      ),
    );
  }
}
