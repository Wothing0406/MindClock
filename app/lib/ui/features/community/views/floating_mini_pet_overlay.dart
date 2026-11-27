import 'package:flutter/material.dart';

import '../../../../domain/models/commitment_group_models.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mam_pet_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import 'commitment_group_screen.dart';

/// Bong bóng Pet Streak nổi nhỏ gọn trên giao diện, kéo thả được và mở nhanh Nhóm.
class FloatingMiniPetOverlay extends StatefulWidget {
  const FloatingMiniPetOverlay({
    super.key,
    required this.repository,
    this.onOpenGroupScreen,
  });

  final CommunityRepository repository;
  final VoidCallback? onOpenGroupScreen;

  @override
  State<FloatingMiniPetOverlay> createState() => _FloatingMiniPetOverlayState();
}

class _FloatingMiniPetOverlayState extends State<FloatingMiniPetOverlay> {
  CommitmentGroupHub? _hub;
  bool _collapsed = false;
  double _right = 14;
  double _bottom = 14;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final CommitmentGroupHub hub =
          await widget.repository.fetchCommitmentGroupHub();
      if (!mounted) return;
      setState(() => _hub = hub);
    } catch (_) {
      // Bỏ qua lỗi mạng nền, widget vẫn cho phép chạm mở Nhóm.
    }
  }

  void _openQuickPopup() {
    final CommitmentGroupDetail? group = _hub?.group;
    final CommitmentPetSummary? pet = group?.pet;
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final MindClockTheme mc = context.mc;
        return AlertDialog(
          backgroundColor: mc.surface,
          contentPadding: EdgeInsets.all(mc.space16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MamPetView(
                stage: pet?.stage ?? 1,
                reaction: pet?.allMembersDoneToday == true
                    ? MamPetReaction.celebrate
                    : MamPetReaction.idle,
                size: 84,
              ),
              SizedBox(height: mc.space8),
              Text(
                group?.name ?? 'Chưa vào nhóm giữ chuỗi',
                style: mc.sectionTitleStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: mc.space4),
              Text(
                pet != null
                    ? '${pet.milestoneLabelVi} · Hôm nay ${pet.todayCareCount}/${group!.members.length} người'
                    : 'Tạo nhóm hoặc nhập mã để cùng bạn bè giữ chuỗi mỗi ngày.',
                style: mc.captionStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: mc.space12),
              MindClockButton(
                key: const ValueKey<String>('mini-pet-open-group-btn'),
                label: group != null ? 'Mở không gian Nhóm' : 'Tạo / Vào nhóm',
                icon: MindClockIconKind.user,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  if (widget.onOpenGroupScreen != null) {
                    widget.onOpenGroupScreen!();
                  } else {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute<void>(
                            builder: (_) => CommitmentGroupScreen(
                              repository: widget.repository,
                            ),
                          ),
                        )
                        .then((_) => _load());
                  }
                },
              ),
              SizedBox(height: mc.space8),
              MindClockButton(
                key: const ValueKey<String>('mini-pet-collapse-btn'),
                label: 'Thu gọn vào mép',
                variant: MindClockButtonVariant.subtle,
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  setState(() => _collapsed = true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final CommitmentGroupDetail? group = _hub?.group;
    final CommitmentPetSummary? pet = group?.pet;

    if (_collapsed) {
      return Positioned(
        right: 0,
        bottom: _bottom,
        child: MindClockPressable(
          key: const ValueKey<String>('mini-pet-collapsed-tab'),
          semanticLabel: 'Hiện lại Pet nhóm',
          onPressed: () => setState(() => _collapsed = false),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: mc.space8,
              vertical: mc.space8,
            ),
            decoration: BoxDecoration(
              color: mc.surface,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(mc.radiusControl),
              ),
              border: Border.all(color: mc.primary),
            ),
            child: MindClockIcon(
              MindClockIconKind.flame,
              color: mc.primary,
              size: 18,
            ),
          ),
        ),
      );
    }

    return Positioned(
      right: _right,
      bottom: _bottom,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints _) {
          final Size screen = MediaQuery.sizeOf(context);
          return GestureDetector(
            key: const ValueKey<String>('floating-mini-pet'),
            onPanUpdate: (DragUpdateDetails details) {
              setState(() {
                _right = (_right - details.delta.dx)
                    .clamp(8.0, (screen.width - 140).clamp(8.0, 400.0));
                _bottom = (_bottom - details.delta.dy)
                    .clamp(8.0, (screen.height - 200).clamp(8.0, 500.0));
              });
            },
            onTap: _openQuickPopup,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: mc.space8,
                vertical: mc.space4,
              ),
              decoration: BoxDecoration(
                color: mc.surface,
                borderRadius: BorderRadius.circular(mc.radiusPaper),
                border: Border.all(
                  color: pet?.allMembersDoneToday == true
                      ? mc.sunrise
                      : mc.primary,
                  width: 1.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: mc.ink.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  MamPetView(
                    stage: pet?.stage ?? 1,
                    reaction: pet?.allMembersDoneToday == true
                        ? MamPetReaction.happy
                        : MamPetReaction.idle,
                    size: 38,
                  ),
                  SizedBox(width: mc.space4),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        pet != null ? pet.milestoneLabelVi : 'Nhóm',
                        style: mc.captionStyle.copyWith(
                          color: mc.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        pet != null
                            ? '${pet.todayCareCount}/${group!.members.length}'
                            : 'Tạo / Vào',
                        style: mc.captionStyle.copyWith(
                          color: mc.inkMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
