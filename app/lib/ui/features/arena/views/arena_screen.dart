import 'package:flutter/material.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/game/solo_combat_engine.dart';
import '../../../../domain/game/solo_training_question_bank.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../guest_shell/view_models/guest_workspace_view_model.dart';
import '../view_models/solo_arena_view_model.dart';
import 'arena_stage_widget.dart';

/// Màn hình Đấu trường G1 (Hub 3 mode + Luyện đơn cục bộ với Máy tập).
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({
    super.key,
    required this.guestViewModel,
    required this.arenaViewModel,
  });

  final GuestWorkspaceViewModel guestViewModel;
  final SoloArenaViewModel arenaViewModel;

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _reasoningController = TextEditingController();
  bool _showRulesCard = false;
  final Set<int> _expandedSummaryRounds = <int>{};

  @override
  void initState() {
    super.initState();
    widget.arenaViewModel.addListener(_onArenaChanged);
  }

  @override
  void dispose() {
    widget.arenaViewModel.removeListener(_onArenaChanged);
    _answerController.dispose();
    _reasoningController.dispose();
    super.dispose();
  }

  void _onArenaChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _clearInputs() {
    _answerController.clear();
    _reasoningController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final SoloArenaViewModel vm = widget.arenaViewModel;
    switch (vm.section) {
      case ArenaSection.hub:
        return _buildHub(context, vm);
      case ArenaSection.setup:
        return _buildSetup(context, vm);
      case ArenaSection.battle:
        return _buildBattle(context, vm);
      case ArenaSection.summary:
        return _buildSummary(context, vm);
    }
  }

  Widget _buildHub(BuildContext context, SoloArenaViewModel vm) {
    final MindClockTheme mc = context.mc;
    return SingleChildScrollView(
      key: const ValueKey<String>('arena-hub-scroll'),
      padding: EdgeInsets.all(mc.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text('Đấu trường', style: mc.screenTitleStyle),
              const MindClockStatusPill(label: 'G1 · Luyện đơn cục bộ'),
            ],
          ),
          SizedBox(height: mc.space8),
          Text(
            'Luyện chiêu, nắm luật Qi và làm quen nhịp giải câu có bước trình bày trước khi mở giao hữu.',
            style: mc.bodyStyle,
          ),
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('arena-toggle-rules'),
            label: _showRulesCard ? 'Ẩn luật chơi v0.1' : 'Xem Luật chơi (solo-three-v0.1)',
            icon: MindClockIconKind.info,
            variant: MindClockButtonVariant.subtle,
            onPressed: () => setState(() => _showRulesCard = !_showRulesCard),
          ),
          if (_showRulesCard) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Luật chơi ($combatRuleVersion)', style: mc.sectionTitleStyle),
                  SizedBox(height: mc.space8),
                  Text(
                    '• Mỗi bên bắt đầu với $maxHp HP, $maxArmor Giáp, 0 Chắn, 0 Qi; tối đa $maxCombatRounds round.\n'
                    '• Chỉ câu trả lời đúng rõ (kèm bước trình bày) mới kích hoạt hành động và cộng +1 Qi sau round (tối đa $maxQi Qi; round 3 bí mật +1 Qi thêm).\n'
                    '• Sát thương trừ đồng thời: Chắn → Giáp → HP. Hồi phục sau khi chịu đòn; về 0 HP không hồi cứu.\n'
                    '• Luyện đơn chạy cục bộ với Máy tập theo seed, không cộng RP/MMR hay xếp hạng.',
                    style: mc.captionStyle.copyWith(color: mc.ink),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: mc.space16),

          // Cửa 1: Luyện đơn (G1 — mở)
          MindClockCard(
            highlighted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text('Luyện đơn', style: mc.sectionTitleStyle),
                    const MindClockStatusPill(label: 'Sẵn sàng · Offline'),
                  ],
                ),
                SizedBox(height: mc.space8),
                Text(
                  'Đấu tập cùng Máy tập mô phỏng theo luật công khai (có seed & phát lại). Không tính RP hay bảng xếp hạng.',
                  style: mc.bodyStyle,
                ),
                SizedBox(height: mc.space12),
                MindClockButton(
                  key: const ValueKey<String>('arena-enter-solo'),
                  label: 'Vào Luyện đơn',
                  icon: MindClockIconKind.arena,
                  onPressed: () => vm.openSoloSetup(
                    profile: widget.guestViewModel.profile,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: mc.space12),

          // Cửa 2: Đấu đơn 1v1 (G2 — chưa mở UI hai máy)
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text('Đấu đơn 1v1', style: mc.sectionTitleStyle),
                    const MindClockStatusPill(label: 'Sắp mở · G2', accentWarm: true),
                  ],
                ),
                SizedBox(height: mc.space8),
                Text(
                  'Giao hữu 1v1 cùng người thật có mạng, cùng câu/rubric/deadline do máy chủ xác nhận. Không dựng đối thủ online giả ở bản G1.',
                  style: mc.captionStyle.copyWith(color: mc.ink),
                ),
                SizedBox(height: mc.space8),
                const MindClockButton(
                  key: ValueKey<String>('arena-enter-1v1-locked'),
                  label: 'Chờ hoàn tất cổng G2 (hai máy thật)',
                  icon: MindClockIconKind.lock,
                  variant: MindClockButtonVariant.subtle,
                  onPressed: null,
                ),
              ],
            ),
          ),
          SizedBox(height: mc.space12),

          // Cửa 3: Đấu đội 2v2 (G3 — chưa mở)
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text('Đấu đội 2v2', style: mc.sectionTitleStyle),
                    const MindClockStatusPill(label: 'Chưa mở · G3', accentWarm: true),
                  ],
                ),
                SizedBox(height: mc.space8),
                Text(
                  'Hai bạn lập đội đấu giao hữu 2v2. Chỉ mở sau khi hoàn tất playtest 1v1 ở G2.',
                  style: mc.captionStyle.copyWith(color: mc.ink),
                ),
                SizedBox(height: mc.space8),
                const MindClockButton(
                  key: ValueKey<String>('arena-enter-2v2-locked'),
                  label: 'Mở sau cổng giao hữu 1v1',
                  icon: MindClockIconKind.lock,
                  variant: MindClockButtonVariant.subtle,
                  onPressed: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetup(BuildContext context, SoloArenaViewModel vm) {
    final MindClockTheme mc = context.mc;
    final StudyProfile profile = widget.guestViewModel.profile;

    return SingleChildScrollView(
      key: const ValueKey<String>('arena-setup-scroll'),
      padding: EdgeInsets.all(mc.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text('Thiết lập Luyện đơn', style: mc.screenTitleStyle),
              MindClockButton(
                key: const ValueKey<String>('arena-setup-back'),
                label: 'Về Đấu trường',
                variant: MindClockButtonVariant.subtle,
                expand: false,
                onPressed: vm.backToHub,
              ),
            ],
          ),
          SizedBox(height: mc.space8),
          const MindClockNoticeBanner(
            message:
                'Chế độ Luyện đơn dùng bộ câu đã duyệt lưu trên máy (chạy được khi offline). Đối thủ là Máy tập theo luật — không tính RP hay xếp hạng.',
            isWarm: false,
          ),
          if (vm.setupErrorVi != null) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockNoticeBanner(message: vm.setupErrorVi!),
          ],
          SizedBox(height: mc.space16),

          // 1. Chọn môn
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('1. Chọn môn luyện tập', style: mc.sectionTitleStyle),
                SizedBox(height: mc.space4),
                Text(
                  'Môn có câu duyệt sẵn trên máy: Toán, Vật lí, Tiếng Anh, Sinh học.',
                  style: mc.captionStyle,
                ),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: SubjectCatalog.allSubjects.map((SubjectInfo subj) {
                    final bool selected = vm.selectedSubjectCode == subj.code;
                    final bool cached =
                        SoloTrainingQuestionBank.hasApprovedCacheFor(subj.code);
                    return MindClockPressable(
                      key: ValueKey<String>('arena-subject-${subj.code}'),
                      selected: selected,
                      semanticLabel:
                          'Môn ${subj.nameVi}, ${cached ? "có câu duyệt" : "chưa có câu duyệt"}',
                      onPressed: () => vm.selectSubject(subj.code),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: mc.space12,
                          vertical: mc.space8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? mc.primary
                              : (cached ? mc.primarySoft : mc.paper),
                          borderRadius: BorderRadius.circular(mc.radiusChip),
                          border: Border.all(
                            color: selected
                                ? mc.primary
                                : (cached ? mc.primary : mc.outline),
                          ),
                        ),
                        child: Text(
                          cached ? subj.nameVi : '${subj.nameVi} (chưa có câu)',
                          style: mc.chipLabelStyle.copyWith(
                            color: selected ? mc.onPrimary : mc.ink,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          SizedBox(height: mc.space16),

          // 2. Chọn tướng của bạn
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('2. Chọn tướng của bạn (3 tướng gốc)', style: mc.sectionTitleStyle),
                SizedBox(height: mc.space12),
                ...ChampionId.values.map((ChampionId id) {
                  final ChampionSpec spec = CombatCatalog.getSpec(id);
                  final bool selected = vm.playerChampion == id;
                  return Padding(
                    padding: EdgeInsets.only(bottom: mc.space8),
                    child: MindClockPressable(
                      key: ValueKey<String>('arena-champion-${id.code}'),
                      selected: selected,
                      semanticLabel: 'Chọn tướng ${spec.nameVi}, ${spec.roleVi}',
                      onPressed: () => vm.selectPlayerChampion(id),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(mc.space12),
                        decoration: BoxDecoration(
                          color: selected ? mc.primarySoft : mc.paper,
                          borderRadius: BorderRadius.circular(mc.radiusControl),
                          border: Border.all(
                            color: selected ? mc.primary : mc.outline,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: mc.space8,
                              runSpacing: mc.space4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: <Widget>[
                                Text(spec.nameVi, style: mc.bodyStrongStyle),
                                MindClockStatusPill(
                                  label: spec.roleVi,
                                  accentWarm: !selected,
                                ),
                              ],
                            ),
                            SizedBox(height: mc.space4),
                            Text(
                              'Nội tại (${spec.passiveNameVi}): ${spec.passiveDescriptionVi}',
                              style: mc.captionStyle.copyWith(color: mc.ink),
                            ),
                            SizedBox(height: mc.space4),
                            Text(
                              'Chiêu 1 (${spec.skill1.qiCost} Qi): ${spec.skill1.nameVi} · ${spec.skill1.damage} ST'
                              '${spec.skill1.addWard > 0 ? " +${spec.skill1.addWard} chắn" : ""}'
                              '${spec.skill1.healArmor > 0 ? " +${spec.skill1.healArmor} giáp" : ""}',
                              style: mc.captionStyle,
                            ),
                            Text(
                              'Chiêu 2 (${spec.skill2.qiCost} Qi): ${spec.skill2.nameVi} · ${spec.skill2.damage} ST'
                              '${spec.skill2.healHp > 0 ? " +${spec.skill2.healHp} HP" : ""}'
                              '${spec.skill2.healArmor > 0 ? " +${spec.skill2.healArmor} giáp" : ""}'
                              '${spec.skill2.forbidRound6 ? " (cấm round 6)" : ""}',
                              style: mc.captionStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: mc.space16),

          // 3. Máy tập, độ khó, seed & trợ năng
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('3. Máy tập, luật & trợ năng', style: mc.sectionTitleStyle),
                SizedBox(height: mc.space8),
                Text('Độ khó Máy tập (deterministic theo seed):', style: mc.bodyStrongStyle),
                SizedBox(height: mc.space8),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: BotDifficulty.values.map((BotDifficulty diff) {
                    final bool selected = vm.botDifficulty == diff;
                    return MindClockPressable(
                      key: ValueKey<String>('arena-difficulty-${diff.code}'),
                      selected: selected,
                      semanticLabel: 'Độ khó Máy tập ${diff.labelVi}',
                      onPressed: () => vm.selectDifficulty(diff),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: mc.space12,
                          vertical: mc.space8,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? mc.primary : mc.paper,
                          borderRadius: BorderRadius.circular(mc.radiusChip),
                          border: Border.all(
                            color: selected ? mc.primary : mc.outline,
                          ),
                        ),
                        child: Text(
                          diff.labelVi,
                          style: mc.chipLabelStyle.copyWith(
                            color: selected ? mc.onPrimary : mc.ink,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: mc.space4),
                Text(vm.botDifficulty.descriptionVi, style: mc.captionStyle),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    Text(
                      'Tướng Máy tập: ${CombatCatalog.getSpec(vm.botChampion).nameVi}',
                      style: mc.bodyStrongStyle,
                    ),
                    ...ChampionId.values.map((ChampionId id) {
                      final bool selected = vm.botChampion == id;
                      return MindClockPressable(
                        key: ValueKey<String>('arena-bot-champion-${id.code}'),
                        selected: selected,
                        semanticLabel:
                            'Chọn tướng Máy tập ${CombatCatalog.getSpec(id).nameVi}',
                        onPressed: () => vm.selectBotChampion(id),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: mc.space8,
                            vertical: mc.space4,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? mc.sunriseSoft : mc.paper,
                            borderRadius: BorderRadius.circular(mc.radiusChip),
                            border: Border.all(
                              color: selected ? mc.sunrise : mc.outline,
                            ),
                          ),
                          child: Text(
                            CombatCatalog.getSpec(id).nameVi,
                            style: mc.chipLabelStyle,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    MindClockStatusPill(
                      key: const ValueKey<String>('arena-seed-pill'),
                      label: 'Seed phát lại: #${vm.seed}',
                    ),
                    MindClockButton(
                      key: const ValueKey<String>('arena-reroll-seed'),
                      label: 'Đổi seed',
                      variant: MindClockButtonVariant.subtle,
                      expand: false,
                      onPressed: vm.nextPresetSeed,
                    ),
                  ],
                ),
                SizedBox(height: mc.space12),
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space8,
                  children: <Widget>[
                    _ToggleChip(
                      key: const ValueKey<String>('arena-toggle-no-timer'),
                      label: vm.noTimeLimit
                          ? 'Không giới hạn thời gian: Bật'
                          : 'Không giới hạn thời gian: Tắt',
                      active: vm.noTimeLimit,
                      onTap: vm.toggleNoTimeLimit,
                    ),
                    _ToggleChip(
                      key: const ValueKey<String>('arena-toggle-reduce-motion'),
                      label: vm.reduceMotionOverride
                          ? 'Giảm chuyển động: Bật'
                          : 'Giảm chuyển động: Theo máy',
                      active: vm.reduceMotionOverride,
                      onTap: vm.toggleReduceMotion,
                    ),
                    _ToggleChip(
                      key: const ValueKey<String>('arena-toggle-sound'),
                      label: vm.soundEnabled ? 'Âm thanh game: Bật' : 'Âm thanh game: Tắt',
                      active: vm.soundEnabled,
                      onTap: vm.toggleSound,
                    ),
                    _ToggleChip(
                      key: const ValueKey<String>('arena-toggle-asset-fallback'),
                      label: vm.simulateAssetFallback
                          ? 'Fallback lỗi asset: Đang bật'
                          : 'Fallback lỗi asset: Bình thường',
                      active: vm.simulateAssetFallback,
                      onTap: vm.toggleSimulateAssetFallback,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: mc.space16),
          MindClockButton(
            key: const ValueKey<String>('arena-start-solo-match'),
            label: 'Bắt đầu Luyện đơn',
            icon: MindClockIconKind.play,
            onPressed: () {
              _clearInputs();
              vm.startSoloMatch(playerName: profile.alias);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBattle(BuildContext context, SoloArenaViewModel vm) {
    final MindClockTheme mc = context.mc;
    final SoloApprovedQuestion? q = vm.currentQuestion;
    final bool isCompactStage = vm.phase == SoloBattlePhase.answering ||
        vm.phase == SoloBattlePhase.gradedUncertain ||
        vm.phase == SoloBattlePhase.gradedIncorrect;

    return SingleChildScrollView(
      key: const ValueKey<String>('arena-battle-scroll'),
      padding: EdgeInsets.all(mc.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header gọn: Lượt luyện, Round, Seed, nút Bỏ qua/Tắt âm/Thoát
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text(
                    'Lượt luyện · Round ${vm.currentRound}/$maxCombatRounds',
                    key: const ValueKey<String>('arena-round-header'),
                    style: mc.sectionTitleStyle,
                  ),
                  if (vm.isCurrentRoundSecret)
                    const MindClockStatusPill(
                      label: 'Round bí mật (+1 Qi)',
                      accentWarm: true,
                    ),
                ],
              ),
              MindClockButton(
                key: const ValueKey<String>('arena-exit-battle'),
                label: 'Thoát luyện',
                variant: MindClockButtonVariant.subtle,
                expand: false,
                onPressed: vm.backToHub,
              ),
            ],
          ),
          SizedBox(height: mc.space8),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space4,
            children: <Widget>[
              _ToggleChip(
                key: const ValueKey<String>('arena-battle-skip-fx'),
                label: vm.skipEffects ? 'Bỏ qua hiệu ứng: Bật' : 'Bỏ qua hiệu ứng',
                active: vm.skipEffects,
                onTap: vm.toggleSkipEffects,
              ),
              _ToggleChip(
                key: const ValueKey<String>('arena-battle-sound'),
                label: vm.soundEnabled ? 'Âm: Bật' : 'Âm: Tắt',
                active: vm.soundEnabled,
                onTap: vm.toggleSound,
              ),
              MindClockStatusPill(label: 'Seed #${vm.seed} · 0 RP'),
            ],
          ),
          SizedBox(height: mc.space12),

          // Sân đấu: thu gọn khi đang giải câu để câu/ô trình bày luôn lớn hơn sân
          ArenaStageWidget(
            playerState: vm.playerState,
            botState: vm.botState,
            compact: isCompactStage,
            reduceMotion: vm.reduceMotionOverride,
            skipEffects: vm.skipEffects,
            soundEnabled: vm.soundEnabled,
            assetFallbackMode: vm.simulateAssetFallback,
            lastResolution: vm.phase == SoloBattlePhase.roundFeedback
                ? vm.lastResolution
                : null,
          ),
          SizedBox(height: mc.space12),

          // Khu vực chính ưu tiên: Đề bài + Ô nhập chữ & bước trình bày
          if (q != null)
            MindClockCard(
              highlighted: vm.phase == SoloBattlePhase.answering,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: mc.space8,
                    runSpacing: mc.space4,
                    children: <Widget>[
                      MindClockStatusPill(
                        label: SubjectCatalog.nameFor(q.subjectCode),
                      ),
                      MindClockStatusPill(
                        label: '${q.gradeBand} · Câu duyệt rev ${q.revision}',
                      ),
                      if (vm.noTimeLimit)
                        const MindClockStatusPill(
                          label: 'Không giới hạn thời gian',
                        ),
                    ],
                  ),
                  SizedBox(height: mc.space12),
                  Text(
                    q.prompt,
                    key: const ValueKey<String>('arena-question-prompt'),
                    style: mc.sectionTitleStyle,
                  ),
                  SizedBox(height: mc.space8),
                  Text(
                    'Yêu cầu trình bày: ${q.reasoningPromptVi}',
                    style: mc.bodyStyle.copyWith(color: mc.inkMuted),
                  ),
                  if (vm.phase == SoloBattlePhase.answering) ...<Widget>[
                    SizedBox(height: mc.space16),
                    Text('Đáp án của bạn', style: mc.bodyStrongStyle),
                    SizedBox(height: mc.space4),
                    TextField(
                      key: const ValueKey<String>('arena-answer-input'),
                      controller: _answerController,
                      decoration: InputDecoration(
                        hintText: 'Nhập đáp án (ví dụ: 8, 0,5, 2 A, has lived...)',
                        filled: true,
                        fillColor: mc.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(mc.radiusControl),
                          borderSide: BorderSide(color: mc.outline),
                        ),
                      ),
                    ),
                    SizedBox(height: mc.space12),
                    Text(
                      'Bước trình bày (bắt buộc để kích hoạt chiêu)',
                      style: mc.bodyStrongStyle,
                    ),
                    SizedBox(height: mc.space4),
                    TextField(
                      key: const ValueKey<String>('arena-reasoning-input'),
                      controller: _reasoningController,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Viết ngắn gọn 1–2 bước biến đổi hoặc công thức bạn áp dụng...',
                        filled: true,
                        fillColor: mc.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(mc.radiusControl),
                          borderSide: BorderSide(color: mc.outline),
                        ),
                      ),
                    ),
                    SizedBox(height: mc.space16),
                    MindClockButton(
                      key: const ValueKey<String>('arena-submit-answer'),
                      label: 'Nộp bài & Chấm',
                      icon: MindClockIconKind.check,
                      onPressed: () {
                        vm.submitAnswer(
                          answerText: _answerController.text,
                          reasoningText: _reasoningController.text,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

          // Phản hồi sau nộp theo 3 trạng thái
          if (vm.phase == SoloBattlePhase.gradedUncertain &&
              vm.lastGrading != null) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const MindClockStatusPill(
                    key: ValueKey<String>('arena-grade-pill-uncertain'),
                    label: 'Kết quả: Chưa chắc (không phạt)',
                    accentWarm: true,
                  ),
                  SizedBox(height: mc.space8),
                  Text(vm.lastGrading!.feedbackVi, style: mc.bodyStyle),
                  SizedBox(height: mc.space12),
                  MindClockButton(
                    key: const ValueKey<String>('arena-uncertain-retry'),
                    label: 'Sửa lại chữ trình bày',
                    icon: MindClockIconKind.edit,
                    onPressed: vm.editSubmissionAgain,
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('arena-uncertain-swap'),
                    label: 'Đổi câu khác (không mất HP/lượt)',
                    icon: MindClockIconKind.book,
                    variant: MindClockButtonVariant.secondary,
                    onPressed: () {
                      _clearInputs();
                      vm.swapQuestionOnUncertain();
                    },
                  ),
                ],
              ),
            ),
          ],

          if (vm.phase == SoloBattlePhase.gradedIncorrect &&
              vm.lastGrading != null) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const MindClockStatusPill(
                    key: ValueKey<String>('arena-grade-pill-incorrect'),
                    label: 'Kết quả: Chưa đúng',
                    accentWarm: true,
                  ),
                  SizedBox(height: mc.space8),
                  Text(vm.lastGrading!.feedbackVi, style: mc.bodyStyle),
                  if (vm.lastGrading!.oneStepHintVi != null) ...<Widget>[
                    SizedBox(height: mc.space8),
                    MindClockNoticeBanner(
                      message: 'Gợi ý 1 bước: ${vm.lastGrading!.oneStepHintVi!}',
                    ),
                  ],
                  SizedBox(height: mc.space12),
                  MindClockButton(
                    key: const ValueKey<String>('arena-incorrect-retry'),
                    label: 'Sửa bài & thử lại',
                    icon: MindClockIconKind.edit,
                    onPressed: vm.editSubmissionAgain,
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('arena-incorrect-continue'),
                    label: 'Tiếp tục lượt (không ra đòn)',
                    icon: MindClockIconKind.play,
                    variant: MindClockButtonVariant.secondary,
                    onPressed: vm.continueTurnAfterIncorrect,
                  ),
                  if (vm.lastGrading!.canRevealRubric) ...<Widget>[
                    SizedBox(height: mc.space8),
                    MindClockButton(
                      key: const ValueKey<String>('arena-toggle-rubric'),
                      label: vm.showRubricReveal ? 'Ẩn cách chấm' : 'Xem cách chấm',
                      icon: MindClockIconKind.info,
                      variant: MindClockButtonVariant.subtle,
                      onPressed: vm.toggleRubricReveal,
                    ),
                  ],
                  if (vm.showRubricReveal && q != null) _buildRubricBox(mc, q),
                ],
              ),
            ),
          ],

          // Cửa sổ chọn hành động (chỉ mở khi đúng rõ)
          if (vm.phase == SoloBattlePhase.choosingAction &&
              vm.lastGrading != null) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockCard(
              highlighted: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: mc.space8,
                    runSpacing: mc.space8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      const MindClockStatusPill(
                        key: ValueKey<String>('arena-grade-pill-correct'),
                        label: 'Kết quả: Đúng rõ',
                      ),
                      Text(
                        'Chọn đòn đánh hoặc chiêu (Qi hiện có: ${vm.playerState.qi}/$maxQi)',
                        style: mc.bodyStrongStyle,
                      ),
                    ],
                  ),
                  SizedBox(height: mc.space8),
                  Text(vm.lastGrading!.feedbackVi, style: mc.captionStyle),
                  SizedBox(height: mc.space12),
                  ...vm.actionOptions.map((SoloActionAvailability opt) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: mc.space8),
                      child: MindClockPressable(
                        key: ValueKey<String>('arena-action-${opt.actionType.code}'),
                        semanticLabel: opt.enabled
                            ? '${opt.titleVi}, ${opt.effectSummaryVi}'
                            : '${opt.titleVi} không khả dụng: ${opt.disabledReasonVi ?? ""}',
                        onPressed: opt.enabled
                            ? () => vm.chooseAction(opt.actionType)
                            : null,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(mc.space12),
                          decoration: BoxDecoration(
                            color: opt.enabled ? mc.surface : mc.paper,
                            borderRadius: BorderRadius.circular(mc.radiusControl),
                            border: Border.all(
                              color: opt.enabled ? mc.primary : mc.outline,
                              width: opt.enabled ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Wrap(
                                spacing: mc.space8,
                                runSpacing: mc.space4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: <Widget>[
                                  Text(
                                    opt.titleVi,
                                    style: mc.bodyStrongStyle.copyWith(
                                      color: opt.enabled ? mc.ink : mc.inkMuted,
                                    ),
                                  ),
                                  MindClockStatusPill(
                                    label: '${opt.qiCost} Qi',
                                    accentWarm: !opt.enabled,
                                  ),
                                ],
                              ),
                              SizedBox(height: mc.space4),
                              Text(opt.effectSummaryVi, style: mc.captionStyle),
                              if (!opt.enabled && opt.disabledReasonVi != null) ...<Widget>[
                                SizedBox(height: mc.space4),
                                Text(
                                  'Lý do khóa: ${opt.disabledReasonVi!}',
                                  key: ValueKey<String>(
                                    'arena-action-reason-${opt.actionType.code}',
                                  ),
                                  style: mc.captionStyle.copyWith(color: mc.error),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  MindClockButton(
                    key: const ValueKey<String>('arena-toggle-rubric'),
                    label: vm.showRubricReveal ? 'Ẩn cách chấm' : 'Xem cách chấm',
                    icon: MindClockIconKind.info,
                    variant: MindClockButtonVariant.subtle,
                    onPressed: vm.toggleRubricReveal,
                  ),
                  if (vm.showRubricReveal && q != null) _buildRubricBox(mc, q),
                ],
              ),
            ),
          ],

          // Phản hồi sau khi settle round
          if (vm.phase == SoloBattlePhase.roundFeedback &&
              vm.lastResolution != null) ...<Widget>[
            SizedBox(height: mc.space12),
            _buildRoundFeedbackCard(context, vm, q),
          ],
          SizedBox(height: mc.space24),
        ],
      ),
    );
  }

  Widget _buildRoundFeedbackCard(
    BuildContext context,
    SoloArenaViewModel vm,
    SoloApprovedQuestion? q,
  ) {
    final MindClockTheme mc = context.mc;
    final SoloRoundResolution res = vm.lastResolution!;
    final pDelta = res.settle.playerADelta;
    final bDelta = res.settle.playerBDelta;

    return MindClockCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Kết quả Round ${res.settle.roundNo}',
            key: const ValueKey<String>('arena-round-feedback-title'),
            style: mc.sectionTitleStyle,
          ),
          SizedBox(height: mc.space8),
          Text(
            'Bạn gây ${pDelta.rawDamageDealt} sát thương'
            '${pDelta.hpHealed > 0 ? " · hồi +${pDelta.hpHealed} HP" : ""}'
            '${pDelta.armorHealed > 0 ? " · hồi +${pDelta.armorHealed} Giáp" : ""}'
            '${pDelta.wardAddedInRound > 0 ? " · tạo +${pDelta.wardAddedInRound} Chắn" : ""}'
            ' · nhận +${pDelta.qiGained} Qi.',
            style: mc.bodyStyle,
          ),
          SizedBox(height: mc.space4),
          Text(
            '${res.botDecision.summaryVi} Bạn chịu ${pDelta.damageTaken} ST '
            '(Chắn ${pDelta.wardAbsorbed}, Giáp ${pDelta.armorDamageTaken}, HP ${pDelta.hpDamageTaken}).',
            style: mc.captionStyle.copyWith(color: mc.ink),
          ),
          if (pDelta.passiveTriggered && pDelta.passiveEffectVi != null) ...<Widget>[
            SizedBox(height: mc.space8),
            MindClockNoticeBanner(
              message: 'Nội tại của bạn kích hoạt: ${pDelta.passiveEffectVi!}',
              isWarm: false,
            ),
          ],
          if (bDelta.passiveTriggered && bDelta.passiveEffectVi != null) ...<Widget>[
            SizedBox(height: mc.space8),
            MindClockNoticeBanner(
              message: 'Nội tại Máy tập kích hoạt: ${bDelta.passiveEffectVi!}',
            ),
          ],
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('arena-next-round'),
            label: vm.matchFinished || vm.currentRound >= maxCombatRounds
                ? 'Xem tổng kết lượt luyện'
                : 'Sang Round ${vm.currentRound + 1}',
            icon: MindClockIconKind.play,
            onPressed: () {
              _clearInputs();
              vm.advanceAfterFeedback();
            },
          ),
          if (q != null) ...<Widget>[
            SizedBox(height: mc.space8),
            MindClockButton(
              key: const ValueKey<String>('arena-feedback-rubric'),
              label: vm.showRubricReveal ? 'Ẩn cách chấm' : 'Xem cách chấm',
              icon: MindClockIconKind.info,
              variant: MindClockButtonVariant.subtle,
              onPressed: vm.toggleRubricReveal,
            ),
            if (vm.showRubricReveal) _buildRubricBox(mc, q),
          ],
        ],
      ),
    );
  }

  Widget _buildRubricBox(MindClockTheme mc, SoloApprovedQuestion q) {
    return Padding(
      padding: EdgeInsets.only(top: mc.space8),
      child: Container(
        key: const ValueKey<String>('arena-rubric-reveal-box'),
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
              'Cách chấm (Rubric rev ${q.rubricRevision})',
              style: mc.bodyStrongStyle,
            ),
            SizedBox(height: mc.space4),
            ...q.gradingRubricStepsVi.map(
              (String step) => Padding(
                padding: EdgeInsets.only(bottom: mc.space4),
                child: Text('• $step', style: mc.captionStyle.copyWith(color: mc.ink)),
              ),
            ),
            Text(
              'Lời giải ngắn: ${q.explanationAfterRevealVi}',
              style: mc.captionStyle.copyWith(color: mc.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, SoloArenaViewModel vm) {
    final MindClockTheme mc = context.mc;
    final ChampionSpec playerSpec = CombatCatalog.getSpec(vm.playerChampion);
    final ChampionSpec botSpec = CombatCatalog.getSpec(vm.botChampion);

    return SingleChildScrollView(
      key: const ValueKey<String>('arena-summary-scroll'),
      padding: EdgeInsets.all(mc.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const MindClockStatusPill(
            key: ValueKey<String>('arena-summary-local-pill'),
            label: 'Lượt luyện cục bộ · 0 RP / Không xếp hạng',
          ),
          SizedBox(height: mc.space8),
          Text(
            vm.summaryOutcomeTitleVi(),
            key: const ValueKey<String>('arena-summary-outcome'),
            style: mc.screenTitleStyle,
          ),
          SizedBox(height: mc.space4),
          Text(vm.summaryFinishReasonVi(), style: mc.bodyStyle),
          SizedBox(height: mc.space12),

          MindClockCard(
            highlighted: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Thông số kết thúc ($combatRuleVersion)', style: mc.sectionTitleStyle),
                SizedBox(height: mc.space8),
                Text(
                  '• Bạn (${playerSpec.nameVi}): HP ${vm.playerState.hp}/$maxHp · Giáp ${vm.playerState.armor}/$maxArmor · Qi ${vm.playerState.qi}/$maxQi',
                  style: mc.bodyStrongStyle,
                ),
                SizedBox(height: mc.space4),
                Text(
                  '• Máy tập (${botSpec.nameVi}): HP ${vm.botState.hp}/$maxHp · Giáp ${vm.botState.armor}/$maxArmor · Qi ${vm.botState.qi}/$maxQi',
                  style: mc.bodyStyle,
                ),
                SizedBox(height: mc.space8),
                Text(
                  'Môn: ${SubjectCatalog.nameFor(vm.selectedSubjectCode)} · '
                  'Độ khó: ${vm.botDifficulty.labelVi} · Seed phát lại: #${vm.seed}',
                  style: mc.captionStyle,
                ),
              ],
            ),
          ),
          SizedBox(height: mc.space16),

          Text('Nhật ký từng round & phát lại (Replay)', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          ...vm.history.map((SoloRoundHistoryItem item) {
            final bool expanded = _expandedSummaryRounds.contains(item.roundNo);
            return Padding(
              padding: EdgeInsets.only(bottom: mc.space8),
              child: MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text('Round ${item.roundNo}', style: mc.bodyStrongStyle),
                        MindClockStatusPill(
                          label: item.playerGrade.labelVi,
                          accentWarm: item.playerGrade != SoloGradeStatus.correct,
                        ),
                      ],
                    ),
                    SizedBox(height: mc.space4),
                    Text(item.question.prompt, style: mc.captionStyle.copyWith(color: mc.ink)),
                    SizedBox(height: mc.space4),
                    Text(
                      'Bạn: gây ${item.resolution.settle.playerADelta.rawDamageDealt} ST, còn ${item.resolution.settle.playerADelta.newHp} HP · '
                      'Máy tập: gây ${item.resolution.settle.playerBDelta.rawDamageDealt} ST, còn ${item.resolution.settle.playerBDelta.newHp} HP',
                      style: mc.captionStyle,
                    ),
                    SizedBox(height: mc.space8),
                    MindClockButton(
                      key: ValueKey<String>('arena-summary-rubric-${item.roundNo}'),
                      label: expanded ? 'Ẩn cách chấm' : 'Xem cách chấm',
                      variant: MindClockButtonVariant.subtle,
                      expand: false,
                      onPressed: () {
                        setState(() {
                          if (expanded) {
                            _expandedSummaryRounds.remove(item.roundNo);
                          } else {
                            _expandedSummaryRounds.add(item.roundNo);
                          }
                        });
                      },
                    ),
                    if (expanded) _buildRubricBox(mc, item.question),
                  ],
                ),
              ),
            );
          }),

          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('arena-replay-same-seed'),
            label: 'Luyện lại cùng seed (#${vm.seed})',
            icon: MindClockIconKind.play,
            onPressed: () {
              _clearInputs();
              _expandedSummaryRounds.clear();
              vm.replayWithSameSeed(playerName: widget.guestViewModel.profile.alias);
            },
          ),
          SizedBox(height: mc.space8),
          MindClockButton(
            key: const ValueKey<String>('arena-back-to-setup'),
            label: 'Đổi môn / đổi tướng',
            icon: MindClockIconKind.edit,
            variant: MindClockButtonVariant.secondary,
            onPressed: () {
              _clearInputs();
              _expandedSummaryRounds.clear();
              vm.openSoloSetup(profile: widget.guestViewModel.profile);
            },
          ),
          SizedBox(height: mc.space8),
          MindClockButton(
            key: const ValueKey<String>('arena-back-to-hub'),
            label: 'Về Đấu trường',
            variant: MindClockButtonVariant.subtle,
            onPressed: () {
              _clearInputs();
              _expandedSummaryRounds.clear();
              vm.backToHub();
            },
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return MindClockPressable(
      onPressed: onTap,
      selected: active,
      semanticLabel: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: mc.space12,
          vertical: mc.space8,
        ),
        decoration: BoxDecoration(
          color: active ? mc.primarySoft : mc.paper,
          borderRadius: BorderRadius.circular(mc.radiusChip),
          border: Border.all(color: active ? mc.primary : mc.outline),
        ),
        child: Text(
          label,
          style: mc.chipLabelStyle.copyWith(color: mc.ink),
        ),
      ),
    );
  }
}
