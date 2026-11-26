import 'package:flutter/widgets.dart';
import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/game/solo_combat_engine.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_pressable.dart';

/// Bộ ba lá chiêu dùng chính điều kiện của combat engine; không tự tính thưởng.
class ArenaSkillHand extends StatelessWidget {
  const ArenaSkillHand(
      {super.key,
      required this.champion,
      required this.options,
      required this.onAction,
      this.keyPrefix = 'arena-action'});
  final ChampionId champion;
  final List<SoloActionAvailability> options;
  final ValueChanged<CombatActionType> onAction;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final mc = context.mc;
    final spec = CombatCatalog.getSpec(champion);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Bộ chiêu · Giải đúng để ra đòn', style: mc.bodyStrongStyle),
      SizedBox(height: mc.space8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final opt in options)
            Padding(
              padding: EdgeInsets.only(right: mc.space8),
              child: SizedBox(
                  width: 148,
                  child: MindClockPressable(
                    key: ValueKey<String>('$keyPrefix-${opt.actionType.code}'),
                    semanticLabel:
                        '${opt.titleVi}. ${opt.effectSummaryVi}. ${opt.disabledReasonVi ?? "Sẵn sàng"}',
                    onPressed:
                        opt.enabled ? () => onAction(opt.actionType) : null,
                    child: Container(
                      padding: EdgeInsets.all(mc.space12),
                      decoration: BoxDecoration(
                          color: mc.nightSurface,
                          borderRadius: BorderRadius.circular(mc.radiusCard),
                          border: Border.all(
                              color: opt.enabled ? mc.sunrise : mc.outline)),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                                spec
                                    .framesForAction(switch (opt.actionType) {
                                      CombatActionType.basic => 'basic',
                                      CombatActionType.skill1 => 'skill1',
                                      CombatActionType.skill2 => 'skill2',
                                    })
                                    .first,
                                height: 72,
                                width: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox(height: 72)),
                            Text(opt.titleVi,
                                style: mc.bodyStrongStyle
                                    .copyWith(color: mc.nightText)),
                            Text('${opt.qiCost} khí lực',
                                style: mc.captionStyle
                                    .copyWith(color: mc.sunrise)),
                            Text(opt.effectSummaryVi,
                                style: mc.captionStyle
                                    .copyWith(color: mc.nightText)),
                            SizedBox(height: mc.space8),
                            Text(
                                opt.enabled
                                    ? 'Dùng chiêu'
                                    : opt.disabledReasonVi ?? 'Chưa mở chiêu',
                                key: ValueKey<String>(
                                    'arena-action-reason-${opt.actionType.code}'),
                                style: mc.captionStyle
                                    .copyWith(color: mc.nightText)),
                          ]),
                    ),
                  )),
            ),
        ]),
      ),
      SizedBox(height: mc.space8),
      Text('Nội tại · ${spec.passiveNameVi}: ${spec.passiveDescriptionVi}',
          style: mc.captionStyle),
    ]);
  }
}
