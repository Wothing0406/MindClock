import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import '../../../../data/services/method_channel_pet_share_gateway.dart';
import '../../../../domain/models/commitment_group_models.dart';
import '../../../../domain/services/community_repository.dart';
import '../../../../domain/services/pet_share_gateway.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mam_pet_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../services/pet_share_image_exporter.dart';
import 'commitment_group_sheet.dart';
import 'pet_share_card.dart';

class TodayPetCard extends StatefulWidget {
  const TodayPetCard({
    super.key,
    required this.repository,
    this.shareGateway,
  });

  final CommunityRepository repository;
  final PetShareGateway? shareGateway;

  @override
  State<TodayPetCard> createState() => _TodayPetCardState();
}

class _TodayPetCardState extends State<TodayPetCard> {
  final GlobalKey _shareBoundaryKey = GlobalKey();
  CommitmentGroupHub? _hub;
  bool _loading = true;
  bool _sharing = false;
  String? _errorVi;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TodayPetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _errorVi = null;
      });
    }
    try {
      final CommitmentGroupHub hub =
          await widget.repository.fetchCommitmentGroupHub();
      if (!mounted) return;
      setState(() {
        _hub = hub;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorVi = 'Chưa tải được pet nhóm.';
      });
    }
  }

  Future<void> _openHub() async {
    await showCommitmentGroupSheet(
        context: context, repository: widget.repository);
    if (mounted) await _load();
  }

  Future<void> _showSharePreview(CommitmentGroupDetail group) async {
    bool showGroupName = false;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final MindClockTheme mc = context.mc;
          return Dialog(
            backgroundColor: mc.paper,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(mc.radiusPaper)),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(mc.space16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text('Xem trước thẻ chia sẻ', style: mc.sectionTitleStyle),
                  SizedBox(height: mc.space12),
                  FittedBox(
                    child: RepaintBoundary(
                      key: _shareBoundaryKey,
                      child: PetShareCard(
                        group: group,
                        showGroupName: showGroupName,
                      ),
                    ),
                  ),
                  SizedBox(height: mc.space12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text('Hiện tên nhóm', style: mc.bodyStyle),
                      ),
                      Switch.adaptive(
                        value: showGroupName,
                        onChanged: (bool value) =>
                            setDialogState(() => showGroupName = value),
                      ),
                    ],
                  ),
                  Text(
                    'Thẻ không chứa mã nhóm, lịch học, giờ dậy hoặc tên thành viên.',
                    style: mc.captionStyle,
                  ),
                  SizedBox(height: mc.space12),
                  MindClockButton(
                    key: const ValueKey<String>('today-pet-share-confirm'),
                    label: _sharing ? 'Đang tạo ảnh...' : 'Chia sẻ ảnh',
                    icon: MindClockIconKind.sunrise,
                    onPressed: _sharing
                        ? null
                        : () async {
                            final String? feedback =
                                await _captureAndShare(group);
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                            if (mounted && feedback != null) {
                              setState(() => _errorVi = feedback);
                            }
                          },
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    label: 'Đóng',
                    variant: MindClockButtonVariant.subtle,
                    onPressed: _sharing
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _captureAndShare(CommitmentGroupDetail group) async {
    setState(() => _sharing = true);
    File? output;
    try {
      await WidgetsBinding.instance.endOfFrame;
      final RenderRepaintBoundary boundary = _shareBoundaryKey.currentContext!
          .findRenderObject()! as RenderRepaintBoundary;
      output = await const PetShareImageExporter().export(boundary);
      final PetShareResult result =
          await (widget.shareGateway ?? const MethodChannelPetShareGateway())
              .sharePng(
        filePath: output.path,
        text:
            '${group.pet.name} · ${group.pet.totalXp} EXP · Chuỗi ${group.pet.currentStreakDays} ngày trên MindClock',
      );
      return result.opened ? null : result.messageVi;
    } catch (error) {
      if (kDebugMode) debugPrint('T075 share capture failed: $error');
      return 'Chưa tạo được thẻ chia sẻ.';
    } finally {
      if (output != null && await output.exists()) await output.delete();
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    if (_loading) {
      return MindClockCard(
        key: const ValueKey<String>('today-pet-loading'),
        child: Text('Đang tải pet nhóm...', style: mc.bodyStrongStyle),
      );
    }
    if (_errorVi != null && _hub == null) {
      return MindClockCard(
        key: const ValueKey<String>('today-pet-error'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_errorVi!, style: mc.bodyStyle),
            SizedBox(height: mc.space8),
            MindClockButton(
              label: 'Thử lại',
              icon: MindClockIconKind.info,
              variant: MindClockButtonVariant.secondary,
              onPressed: _load,
            ),
          ],
        ),
      );
    }
    final CommitmentGroupDetail? group = _hub?.group;
    if (group == null) {
      return MindClockCard(
        key: const ValueKey<String>('today-pet-empty'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Pet nhóm', style: mc.sectionTitleStyle),
            SizedBox(height: mc.space4),
            Text('Tạo nhóm cam kết để cùng chăm một pet bằng việc học thật.',
                style: mc.captionStyle),
            SizedBox(height: mc.space12),
            MindClockButton(
              label: 'Mở nhóm cam kết',
              icon: MindClockIconKind.plus,
              variant: MindClockButtonVariant.secondary,
              onPressed: _openHub,
            ),
          ],
        ),
      );
    }
    final CommitmentPetSummary pet = group.pet;
    return MindClockCard(
      key: const ValueKey<String>('today-pet-card'),
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              MamPetView(
                stage: pet.stage,
                reaction: pet.todayCareCount > 0
                    ? MamPetReaction.happy
                    : MamPetReaction.idle,
                size: 92,
              ),
              SizedBox(width: mc.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(pet.name, style: mc.sectionTitleStyle),
                    Text('${pet.stageLabelVi} · Giai đoạn ${pet.stage}/4',
                        style: mc.captionStyle),
                    SizedBox(height: mc.space4),
                    Text('${pet.totalXp}/${pet.nextStageXp} EXP nhóm',
                        style: mc.bodyStrongStyle),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: mc.space8),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: <Widget>[
              MindClockStatusPill(label: 'Chuỗi ${pet.currentStreakDays} ngày'),
              MindClockStatusPill(
                label: 'Hôm nay ${pet.todayCareCount}/${group.members.length}',
                accentWarm: true,
              ),
            ],
          ),
          if (_errorVi != null) ...<Widget>[
            SizedBox(height: mc.space8),
            Text(_errorVi!, style: mc.captionStyle.copyWith(color: mc.error)),
          ],
          SizedBox(height: mc.space12),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: <Widget>[
              MindClockButton(
                key: const ValueKey<String>('today-pet-open-hub'),
                label: 'Xem nhóm',
                icon: MindClockIconKind.user,
                expand: false,
                onPressed: _openHub,
              ),
              MindClockButton(
                key: const ValueKey<String>('today-pet-share'),
                label: 'Chia sẻ',
                icon: MindClockIconKind.sunrise,
                variant: MindClockButtonVariant.secondary,
                expand: false,
                onPressed: () => _showSharePreview(group),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
