import 'package:flutter/widgets.dart';

import '../../../../domain/models/commitment_group_models.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mam_pet_view.dart';

class PetShareCard extends StatelessWidget {
  const PetShareCard({
    super.key,
    required this.group,
    this.showGroupName = false,
  });

  final CommitmentGroupDetail group;
  final bool showGroupName;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final CommitmentPetSummary pet = group.pet;
    return Container(
      width: 320,
      height: 320,
      padding: EdgeInsets.all(mc.space20),
      decoration: BoxDecoration(
        color: mc.primarySoft,
        borderRadius: BorderRadius.circular(mc.radiusPaper),
        border: Border.all(color: mc.primary, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MamPetView(
            stage: pet.stage,
            reaction: MamPetReaction.celebrate,
            size: 104,
          ),
          SizedBox(height: mc.space8),
          Text(pet.name,
              style: mc.screenTitleStyle, textAlign: TextAlign.center),
          Text(
            '${pet.stageLabelVi} · ${pet.totalXp} EXP nhóm',
            style: mc.bodyStrongStyle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: mc.space8),
          Text(
            pet.currentStreakDays > 0
                ? '${pet.milestoneLabelVi} · ${pet.currentStreakDays} ngày đồng hành'
                : 'Chuỗi chăm nhóm ${pet.currentStreakDays} ngày',
            style: mc.bodyStyle,
            textAlign: TextAlign.center,
          ),
          if (showGroupName) ...<Widget>[
            SizedBox(height: mc.space4),
            Text(group.name,
                style: mc.captionStyle, textAlign: TextAlign.center),
          ],
          SizedBox(height: mc.space8),
          Text('MindClock',
              style: mc.chipLabelStyle.copyWith(color: mc.primary)),
        ],
      ),
    );
  }
}
