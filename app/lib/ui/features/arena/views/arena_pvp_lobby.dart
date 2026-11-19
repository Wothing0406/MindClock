import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/game/combat_catalog.dart';
import '../../../../domain/game/pvp_models.dart';
import '../../../../domain/game/solo_combat_engine.dart';
import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/math_formula_text.dart';
import '../../../core/widgets/math_input_keypad.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../view_models/pvp_arena_view_model.dart';
import 'arena_sprite_stage.dart';
import 'arena_stage_widget.dart';

/// Màn giao hữu PvP 1v1 kết nối backend `/v1/pvp/*` (`T061 AC-03`).
class ArenaPvpLobby extends StatefulWidget {
  const ArenaPvpLobby({
    super.key,
    required this.viewModel,
    required this.profile,
    required this.userId,
    required this.onBackToHub,
  });

  final PvpArenaViewModel viewModel;
  final StudyProfile profile;
  final String userId;
  final VoidCallback onBackToHub;

  @override
  State<ArenaPvpLobby> createState() => _ArenaPvpLobbyState();
}

class _ArenaPvpLobbyState extends State<ArenaPvpLobby> {
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _reasoningController = TextEditingController();
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    final String subj = widget.profile.selectedSubjectCodes.isNotEmpty
        ? widget.profile.selectedSubjectCodes.first
        : 'math';
    final String grade = (widget.profile.gradeLevel ?? '').trim().isNotEmpty
        ? widget.profile.gradeLevel!.trim()
        : 'Lớp 11';
    widget.viewModel.configureSubjectAndGrade(
      subjectCode: subj,
      gradeBand: grade,
    );
    if (widget.viewModel.enableAutoPolling) {
      _countdownTicker = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (mounted && widget.viewModel.stage == PvpUiStage.inMatch) {
            setState(() {});
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    _answerController.dispose();
    _reasoningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (BuildContext context, _) {
        final PvpArenaViewModel vm = widget.viewModel;
        return SingleChildScrollView(
          key: const ValueKey<String>('arena-pvp-scroll'),
          padding: EdgeInsets.all(mc.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: mc.space8,
                runSpacing: mc.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Text('Đấu đơn 1v1 (Giao hữu)', style: mc.screenTitleStyle),
                  MindClockStatusPill(
                    label: vm.isDebugFixture
                        ? 'Đấu tập offline · 0 RP'
                        : '0 RP · Công bằng',
                    accentWarm: vm.isDebugFixture,
                  ),
                ],
              ),
              SizedBox(height: mc.space8),
              MindClockButton(
                key: const ValueKey<String>('arena-pvp-back'),
                label: 'Quay lại Đấu trường',
                variant: MindClockButtonVariant.subtle,
                expand: false,
                onPressed: () {
                  if (vm.stage == PvpUiStage.queuing) {
                    vm.cancelQueue();
                  }
                  widget.onBackToHub();
                },
              ),
              if (vm.statusMessageVi != null) ...<Widget>[
                SizedBox(height: mc.space12),
                MindClockNoticeBanner(
                    message: vm.statusMessageVi!, isWarm: false),
              ],
              if (vm.errorVi != null) ...<Widget>[
                SizedBox(height: mc.space12),
                MindClockNoticeBanner(
                  key: const ValueKey<String>('arena-pvp-error'),
                  message: vm.errorVi!,
                ),
              ],
              SizedBox(height: mc.space16),
              if (vm.stage == PvpUiStage.idle) _buildIdleSetup(mc, vm),
              if (vm.stage == PvpUiStage.queuing) _buildQueuing(mc, vm),
              if (vm.stage == PvpUiStage.inMatch && vm.snapshot != null)
                _buildInMatch(mc, vm, vm.snapshot!),
              if (vm.stage == PvpUiStage.completed && vm.snapshot != null)
                _buildCompleted(mc, vm, vm.snapshot!),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdleSetup(MindClockTheme mc, PvpArenaViewModel vm) {
    final List<String> subjects = widget.profile.selectedSubjectCodes.isNotEmpty
        ? widget.profile.selectedSubjectCodes
        : const <String>['math', 'physics', 'english'];

    return MindClockCard(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Cùng câu hỏi, cùng rubric, server chốt HP/Qi & 0 điểm rank.',
            style: mc.bodyStyle,
          ),
          SizedBox(height: mc.space12),
          Text('Chọn môn ghép trận (${vm.gradeBand})',
              style: mc.bodyStrongStyle),
          SizedBox(height: mc.space8),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: subjects.map((String code) {
              final bool selected = vm.subjectCode == code;
              return ChoiceChip(
                key: ValueKey<String>('pvp-subject-$code'),
                label: Text(SubjectCatalog.nameFor(code)),
                selected: selected,
                onSelected: (_) => vm.configureSubjectAndGrade(
                  subjectCode: code,
                  gradeBand: vm.gradeBand,
                ),
              );
            }).toList(growable: false),
          ),
          SizedBox(height: mc.space12),
          Text('Chọn tướng ra trận', style: mc.bodyStrongStyle),
          SizedBox(height: mc.space8),
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            children: ChampionId.values.map((ChampionId id) {
              final ChampionSpec spec = CombatCatalog.getSpec(id);
              return ChoiceChip(
                key: ValueKey<String>('pvp-champ-${id.code}'),
                label: Text(spec.nameVi),
                selected: vm.champion == id,
                onSelected: (_) => vm.selectChampion(id),
              );
            }).toList(growable: false),
          ),
          SizedBox(height: mc.space16),
          MindClockButton(
            key: const ValueKey<String>('pvp-find-match-btn'),
            label: vm.isBusy ? 'Đang tìm đối thủ...' : 'Tìm trận 1v1',
            icon: MindClockIconKind.arena,
            onPressed: vm.isBusy ? null : vm.startMatchmake,
          ),
        ],
      ),
    );
  }

  Widget _buildQueuing(MindClockTheme mc, PvpArenaViewModel vm) {
    return MindClockCard(
      key: const ValueKey<String>('pvp-queuing-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Đang chờ ghép đối thủ...', style: mc.sectionTitleStyle),
          SizedBox(height: mc.space8),
          Text(
            'Môn ${SubjectCatalog.nameFor(vm.subjectCode)} · ${vm.gradeBand} · Tướng ${CombatCatalog.getSpec(vm.champion).nameVi}',
            style: mc.bodyStyle,
          ),
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('pvp-poll-now-btn'),
            label: 'Kiểm tra trạng thái ghép trận',
            icon: MindClockIconKind.play,
            onPressed: vm.isBusy ? null : vm.pollOnce,
          ),
          SizedBox(height: mc.space8),
          MindClockButton(
            key: const ValueKey<String>('pvp-cancel-queue-btn'),
            label: 'Hủy tìm trận',
            icon: MindClockIconKind.stop,
            variant: MindClockButtonVariant.subtle,
            onPressed: vm.cancelQueue,
          ),
        ],
      ),
    );
  }

  Widget _buildInMatch(
    MindClockTheme mc,
    PvpArenaViewModel vm,
    PvpMatchSnapshot snap,
  ) {
    final PvpPlayerSnapshot me = snap.players.firstWhere(
      (PvpPlayerSnapshot p) => p.userId == widget.userId,
      orElse: () => snap.players.isNotEmpty
          ? snap.players.first
          : const PvpPlayerSnapshot(
              userId: 'self',
              alias: 'Bạn',
              championId: ChampionId.haNhan,
              hp: 100,
              armor: 50,
              ward: 0,
              qi: 0,
              skill1Used: false,
              skill2Used: false,
              isAlive: true,
            ),
    );
    final PvpPlayerSnapshot opp = snap.players.firstWhere(
      (PvpPlayerSnapshot p) => p.userId != me.userId,
      orElse: () => const PvpPlayerSnapshot(
        userId: 'opp',
        alias: 'Đối thủ',
        championId: ChampionId.tuyetDinh,
        hp: 100,
        armor: 50,
        ward: 0,
        qi: 0,
        skill1Used: false,
        skill2Used: false,
        isAlive: true,
      ),
    );

    final SoloCombatantState meState = SoloCombatantState(
      actorId: me.userId,
      displayName: me.alias,
      championId: me.championId,
      isBot: false,
      hp: me.hp,
      armor: me.armor,
      ward: me.ward,
      qi: me.qi,
      skill1Used: me.skill1Used,
      skill2Used: me.skill2Used,
    );
    final SoloCombatantState oppState = SoloCombatantState(
      actorId: opp.userId,
      displayName: opp.alias,
      championId: opp.championId,
      isBot: false,
      hp: opp.hp,
      armor: opp.armor,
      ward: opp.ward,
      qi: opp.qi,
      skill1Used: opp.skill1Used,
      skill2Used: opp.skill2Used,
    );

    final PvpRoundInfo? round = snap.currentRoundInfo;
    final bool disableMotion = MediaQuery.disableAnimationsOf(context);
    final ChampionSpec mySpec = CombatCatalog.getSpec(me.championId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ArenaStageWidget(
          playerState: meState,
          botState: oppState,
          compact: false,
          reduceMotion: disableMotion,
          skipEffects: false,
          soundEnabled: false,
          assetFallbackMode: false,
        ),
        SizedBox(height: mc.space12),
        ArenaQiGuideStrip(currentQi: me.qi, maxQi: maxQi),
        SizedBox(height: mc.space12),
        if (round != null) ...<Widget>[
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: mc.space8,
                  runSpacing: mc.space4,
                  children: <Widget>[
                    MindClockStatusPill(
                      label: 'Round ${round.roundNo}/$maxCombatRounds',
                    ),
                    MindClockStatusPill(
                      label: switch (round.state) {
                        'action_window' => 'Mở chọn chiêu',
                        'void' => 'Round hủy (uncertain)',
                        'settled' => 'Đã xử lý',
                        _ => 'Đang trả lời',
                      },
                      accentWarm: round.state == 'void',
                    ),
                    if (round.state == 'answering' &&
                        round.deadlineAtIso.trim().isNotEmpty)
                      Builder(
                        builder: (BuildContext context) {
                          final DateTime? dl =
                              DateTime.tryParse(round.deadlineAtIso);
                          final int remain = dl == null
                              ? 75
                              : dl
                                  .toUtc()
                                  .difference(DateTime.now().toUtc())
                                  .inSeconds
                                  .clamp(0, 999);
                          return MindClockStatusPill(
                            key: const ValueKey<String>('pvp-round-countdown'),
                            label: 'Còn ${remain}s',
                            accentWarm: remain <= 10,
                          );
                        },
                      ),
                  ],
                ),
                SizedBox(height: mc.space12),
                MathFormulaText(
                  round.prompt,
                  key: const ValueKey<String>('pvp-round-prompt'),
                  style: mc.sectionTitleStyle,
                ),
                SizedBox(height: mc.space8),
                Text(round.reasoningPromptVi, style: mc.captionStyle),
                if (round.state == 'answering' &&
                    !round.mySubmission.submitted) ...<Widget>[
                  SizedBox(height: mc.space12),
                  TextField(
                    key: const ValueKey<String>('pvp-answer-input'),
                    controller: _answerController,
                    decoration: const InputDecoration(
                      labelText: 'Đáp án của bạn',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: mc.space8),
                  MathInputKeypad(
                    controller: _answerController,
                    compact: true,
                  ),
                  SizedBox(height: mc.space12),
                  TextField(
                    key: const ValueKey<String>('pvp-reasoning-input'),
                    controller: _reasoningController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Bước trình bày ngắn (bắt buộc)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: mc.space12),
                  MindClockButton(
                    key: const ValueKey<String>('pvp-submit-answer-btn'),
                    label: 'Nộp đáp án Round ${round.roundNo}',
                    icon: MindClockIconKind.check,
                    onPressed: vm.isBusy
                        ? null
                        : () {
                            vm.submitAnswer(
                              answerText: _answerController.text,
                              reasoningText: _reasoningController.text,
                            );
                          },
                  ),
                ] else if (round.state == 'action_window') ...<Widget>[
                  SizedBox(height: mc.space12),
                  Text(
                    'Chọn chiêu (Qi hiện có: ${me.qi}/$maxQi)',
                    style: mc.bodyStrongStyle,
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('pvp-action-basic'),
                    label: 'Đánh thường (28 ST · 0 Qi · Tích +1 Qi)',
                    icon: MindClockIconKind.arena,
                    onPressed: vm.isBusy
                        ? null
                        : () => vm.chooseAction(CombatActionType.basic),
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('pvp-action-skill_1'),
                    label:
                        'Chiêu 1 · ${mySpec.skill1.nameVi} (${mySpec.skill1.qiCost} Qi${me.skill1Used ? " · Đã dùng" : ""})',
                    icon: MindClockIconKind.sunrise,
                    variant: MindClockButtonVariant.secondary,
                    onPressed: (vm.isBusy ||
                            me.skill1Used ||
                            me.qi < mySpec.skill1.qiCost)
                        ? null
                        : () => vm.chooseAction(CombatActionType.skill1),
                  ),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey<String>('pvp-action-skill_2'),
                    label:
                        'Chiêu 2 · ${mySpec.skill2.nameVi} (${mySpec.skill2.qiCost} Qi${me.skill2Used ? " · Đã dùng" : ""})',
                    icon: MindClockIconKind.shield,
                    variant: MindClockButtonVariant.secondary,
                    onPressed: (vm.isBusy ||
                            me.skill2Used ||
                            me.qi < mySpec.skill2.qiCost)
                        ? null
                        : () => vm.chooseAction(CombatActionType.skill2),
                  ),
                ],
                SizedBox(height: mc.space12),
                MindClockButton(
                  key: const ValueKey<String>('pvp-sync-match-btn'),
                  label: 'Đồng bộ trạng thái trận đấu',
                  icon: MindClockIconKind.clock,
                  variant: MindClockButtonVariant.subtle,
                  onPressed: vm.isBusy ? null : vm.pollOnce,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompleted(
    MindClockTheme mc,
    PvpArenaViewModel vm,
    PvpMatchSnapshot snap,
  ) {
    final bool iWon = snap.winnerUserId == widget.userId;
    return MindClockCard(
      key: const ValueKey<String>('pvp-completed-card'),
      highlighted: iWon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            snap.status == 'void'
                ? 'Trận hủy an toàn (Void)'
                : (iWon ? 'Chiến thắng giao hữu!' : 'Hoàn thành trận giao hữu'),
            style: mc.sectionTitleStyle,
          ),
          SizedBox(height: mc.space8),
          Text(
            'Lý do: ${snap.finishReason ?? "Đã kết thúc"} · 0 RP (Giao hữu học tập)',
            style: mc.bodyStyle,
          ),
          SizedBox(height: mc.space12),
          MindClockButton(
            key: const ValueKey<String>('pvp-back-lobby-btn'),
            label: 'Đấu trận mới',
            icon: MindClockIconKind.play,
            onPressed: () {
              _answerController.clear();
              _reasoningController.clear();
              vm.leaveFinishedMatch();
            },
          ),
        ],
      ),
    );
  }
}
