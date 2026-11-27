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
      Text('Bộ thẻ chiến đấu · Giải đúng để kích hoạt',
          style: mc.bodyStrongStyle),
      SizedBox(height: mc.space4),
      Container(
        key: const ValueKey<String>('arena-skill-hand-dock'),
        width: double.infinity,
        padding: EdgeInsets.all(mc.space4),
        decoration: BoxDecoration(
          color: mc.night.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(mc.radiusCard),
          border: Border.all(color: mc.nightSurface),
        ),
        child: SingleChildScrollView(
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
                        padding: EdgeInsets.all(mc.space8),
                        decoration: BoxDecoration(
                            color: opt.enabled
                                ? mc.nightSurface
                                : mc.nightSurface.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(mc.radiusCard),
                            border: Border.all(
                              color: opt.enabled ? mc.sunrise : mc.outline,
                              width: opt.enabled ? 1.8 : 1.0,
                            )),
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
                                  height: 64,
                                  width: 120,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox(height: 64)),
                              Text(opt.titleVi,
                                  style: mc.bodyStrongStyle
                                      .copyWith(color: mc.nightText)),
                              Text('${opt.qiCost} khí lực',
                                  style: mc.captionStyle
                                      .copyWith(color: mc.sunrise)),
                              Text(opt.effectSummaryVi,
                                  style: mc.captionStyle
                                      .copyWith(color: mc.nightText)),
                              SizedBox(height: mc.space4),
                              Text(
                                  opt.enabled
                                      ? 'Chạm ra đòn'
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
      ),
      SizedBox(height: mc.space8),
      Text('Nội tại · ${spec.passiveNameVi}: ${spec.passiveDescriptionVi}',
          style: mc.captionStyle),
    ]);
  }
}
