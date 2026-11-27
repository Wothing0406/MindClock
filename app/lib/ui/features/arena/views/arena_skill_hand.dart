import 'package:flutter/widgets.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/game/solo_combat_engine.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';

/// Thanh kỹ năng gọn: icon kỹ năng (`assets/arena/skill_*.png`) + nhãn ngắn
/// (`Đánh thường`, `Chiêu 1`, `Chiêu 2`, `Chiêu 3`), nội tại tự kích hoạt theo luật tướng.
class ArenaSkillHand extends StatelessWidget {
  const ArenaSkillHand({
    super.key,
    required this.champion,
    required this.options,
    required this.onAction,
    this.keyPrefix = 'arena-action',
    this.qi,
    this.passiveTriggerCount = 0,
    this.onDodge,
    this.dodgeActive = false,
    this.autoCastSpecial,
    this.onToggleAutoCast,
  });

  final ChampionId champion;
  final List<SoloActionAvailability> options;
  final ValueChanged<CombatActionType> onAction;
  final String keyPrefix;
  final int? qi;
  final int passiveTriggerCount;
  final VoidCallback? onDodge;
  final bool dodgeActive;
  final bool? autoCastSpecial;
  final VoidCallback? onToggleAutoCast;

  static String shortLabel(CombatActionType t) => switch (t) {
        CombatActionType.basic => 'Đánh thường',
        CombatActionType.skill1 => 'Chiêu 1',
        CombatActionType.skill2 => 'Chiêu 2',
      };

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final ChampionSpec spec = CombatCatalog.getSpec(champion);
    return Container(
      key: const ValueKey<String>('arena-skill-hand-dock'),
      width: double.infinity,
      padding: EdgeInsets.all(mc.space8),
      decoration: BoxDecoration(
        color: mc.night.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(mc.radiusCard),
        border: Border.all(color: mc.nightSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            alignment: WrapAlignment.center,
            children: <Widget>[
              for (final SoloActionAvailability opt in options)
                _SkillButton(
                  key: ValueKey<String>('$keyPrefix-${opt.actionType.code}'),
                  semanticLabel:
                      '${opt.titleVi}. ${opt.effectSummaryVi}. ${opt.disabledReasonVi ?? "Sẵn sàng"}',
                  iconAsset: spec.assetForAction(opt.actionType),
                  label: shortLabel(opt.actionType),
                  status: opt.enabled
                      ? (opt.qiCost > 0 ? '${opt.qiCost} Qi' : 'Sẵn sàng')
                      : 'Khóa',
                  statusKey: 'arena-action-reason-${opt.actionType.code}',
                  enabled: opt.enabled,
                  highlight: opt.actionType == CombatActionType.skill2,
                  onPressed:
                      opt.enabled ? () => onAction(opt.actionType) : null,
                ),
              if (onDodge != null)
                _SkillButton(
                  key: const ValueKey<String>('arena-dodge-skill-btn'),
                  semanticLabel:
                      'Chiêu 3 Né đòn: lách sang làn an toàn để giảm sát thương',
                  label: 'Chiêu 3',
                  status: dodgeActive ? 'Đang né' : 'Né đòn',
                  enabled: true,
                  highlight: dodgeActive,
                  onPressed: onDodge,
                  iconKind: MindClockIconKind.shield,
                ),
              if (onToggleAutoCast != null)
                _SkillButton(
                  key: const ValueKey<String>('arena-autocast-toggle'),
                  semanticLabel: autoCastSpecial == true
                      ? 'Tự tung chiêu khi đủ khí lực: đang bật'
                      : 'Tự tung chiêu khi đủ khí lực: đang tắt',
                  label: 'Tự tung',
                  status: autoCastSpecial == true ? 'Bật' : 'Tắt',
                  enabled: true,
                  highlight: autoCastSpecial == true,
                  onPressed: onToggleAutoCast,
                  iconKind: MindClockIconKind.flame,
                ),
            ],
          ),
          SizedBox(height: mc.space8),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  passiveTriggerCount > 0
                      ? 'Nội tại ${spec.passiveNameVi}: tự kích hoạt ($passiveTriggerCount lần)'
                      : 'Nội tại ${spec.passiveNameVi}: tự kích hoạt theo luật tướng',
                  key: const ValueKey<String>('arena-passive-auto-badge'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: mc.captionStyle.copyWith(color: mc.nightText),
                ),
              ),
              if (qi != null) ...<Widget>[
                SizedBox(width: mc.space8),
                Text(
                  'Qi $qi/$maxQi',
                  key: const ValueKey<String>('arena-qi-meter'),
                  style: mc.chipLabelStyle.copyWith(color: mc.sunrise),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillButton extends StatelessWidget {
  const _SkillButton({
    super.key,
    required this.semanticLabel,
    required this.label,
    required this.status,
    required this.enabled,
    required this.highlight,
    required this.onPressed,
    this.iconAsset,
    this.statusKey,
    this.iconKind,
  });

  final String semanticLabel;
  final String label;
  final String status;
  final bool enabled;
  final bool highlight;
  final VoidCallback? onPressed;
  final String? iconAsset;
  final String? statusKey;
  final MindClockIconKind? iconKind;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final Color border =
        !enabled ? mc.outline : (highlight ? mc.sunrise : mc.primary);
    return MindClockPressable(
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: mc.nightSurface,
                borderRadius: BorderRadius.circular(mc.radiusControl),
                border: Border.all(color: border, width: enabled ? 2 : 1),
              ),
              child: Opacity(
                opacity: enabled ? 1 : 0.38,
                child: iconAsset != null
                    ? Image.asset(
                        iconAsset!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Text(
                          label.substring(0, 1),
                          style: mc.bodyStrongStyle
                              .copyWith(color: mc.nightText),
                        ),
                      )
                    : MindClockIcon(
                        iconKind ?? MindClockIconKind.arena,
                        color: highlight ? mc.sunrise : mc.nightText,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: mc.chipLabelStyle.copyWith(color: mc.nightText),
            ),
            Text(
              status,
              key: statusKey == null ? null : ValueKey<String>(statusKey!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: mc.captionStyle.copyWith(
                color: enabled ? mc.sunrise : mc.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
