import 'package:flutter/material.dart';

import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../view_models/personal_flow_view_model.dart';
import 'streak_detail_sheet.dart';

/// Tiến độ riêng tư, luôn đọc từ cùng VM/server với màn luyện tập.
class ProfileProgressCard extends StatefulWidget {
  const ProfileProgressCard({super.key, required this.viewModel});
  final PersonalFlowViewModel viewModel;

  @override
  State<ProfileProgressCard> createState() => _ProfileProgressCardState();
}

class _ProfileProgressCardState extends State<ProfileProgressCard> {
  String? _scope;
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_checkOwner);
    _checkOwner();
  }

  void _checkOwner() {
    final vm = widget.viewModel;
    final scope =
        vm.authSession.isAuthenticated ? vm.authSession.ownerScopeKey : 'guest';
    if (_scope == scope) return;
    _scope = scope;
    if (!vm.authSession.isAuthenticated || vm.isDebugFixture) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scope != scope) return;
      _refresh();
    });
  }

  Future<void> _refresh() async {
    await Future.wait([
      widget.viewModel.refreshProgressAndHistory(),
      widget.viewModel.loadXpHistory(refresh: true),
    ]);
  }

  @override
  void didUpdateWidget(covariant ProfileProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_checkOwner);
      widget.viewModel.addListener(_checkOwner);
      _scope = null;
      _checkOwner();
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_checkOwner);
    super.dispose();
  }

  String _date(DateTime utc) {
    final date = utc.toLocal();
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _reason(String reason) => switch (reason) {
        'challenge_correct' => 'Hoàn thành câu ôn',
        'photo_challenge_correct' => 'Hoàn thành câu ôn qua ảnh',
        'study_time_v0_1' => 'Hoàn thành phiên học',
        'daily_report' => 'Hoàn thành báo cáo ngày',
        _ => 'Điều chỉnh EXP từ máy chủ',
      };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final vm = widget.viewModel;
          final mc = context.mc;
          final progress = vm.progressSummary;
          return MindClockCard(
            key: const ValueKey('profile-progress-card'),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tiến độ học tập', style: mc.sectionTitleStyle),
              SizedBox(height: mc.space8),
              if (!vm.authSession.isAuthenticated)
                Text('Đăng nhập để xem cấp, EXP và lịch sử học tập.',
                    style: mc.bodyStyle)
              else if (vm.isDebugFixture)
                Text('Dữ liệu thử nghiệm · Chưa có EXP được máy chủ xác nhận.',
                    style: mc.bodyStyle)
              else ...[
                if (progress.isServerAuthoritative) ...[
                  Text(
                      progress.level == null
                          ? 'Cấp chưa được đồng bộ'
                          : 'Cấp ${progress.level}',
                      key: const ValueKey('profile-level'),
                      style: mc.sectionTitleStyle),
                  Text('${progress.xp} EXP tích lũy',
                      style: mc.bodyStrongStyle),
                  if (progress.levelFraction != null) ...[
                    SizedBox(height: mc.space8),
                    LinearProgressIndicator(
                      key: const ValueKey('profile-level-bar'),
                      value: progress.levelFraction,
                      color: mc.primary,
                      backgroundColor: mc.outline,
                      semanticsLabel: 'Tiến độ lên cấp',
                      semanticsValue:
                          '${(progress.levelFraction! * 100).round()}%',
                    ),
                  ],
                  if (progress.xpToNextLevel != null)
                    Text('Còn ${progress.xpToNextLevel} EXP đến cấp tiếp theo',
                        style: mc.captionStyle),
                  SizedBox(height: mc.space8),
                  Text(
                      'Chuỗi giữ nhịp: ${progress.streak} ngày (Kỷ lục ${progress.bestStreak} ngày) · ${progress.todayCompleted ? "Hôm nay đã giữ" : "Hôm nay chưa giữ"} · ${progress.completedSessions} lượt hoàn thành',
                      style: mc.bodyStyle),
                  SizedBox(height: mc.space8),
                  MindClockButton(
                    key: const ValueKey('profile-view-streak-detail'),
                    label: 'Xem chuỗi & Báo cáo ngày',
                    icon: MindClockIconKind.flame,
                    variant: MindClockButtonVariant.secondary,
                    onPressed: () => showStreakDetailSheet(
                      context: context,
                      viewModel: vm,
                    ),
                  ),
                  Text(
                      'Cấp ghi nhận hoạt động học; năng lực theo môn và rank thi đấu được tính riêng.',
                      style: mc.captionStyle),
                  if (vm.progressSyncedAt != null)
                    Text(
                        'Đồng bộ ${_date(vm.progressSyncedAt!)} · Giờ trên thiết bị',
                        style: mc.captionStyle),
                ] else
                  Text('Chưa tải được tiến độ từ máy chủ.',
                      style: mc.bodyStyle),
                if (vm.progressError != null)
                  Text(vm.progressError!,
                      style: mc.captionStyle.copyWith(color: mc.error)),
                SizedBox(height: mc.space12),
                MindClockButton(
                    key: const ValueKey('profile-refresh-progress'),
                    label: vm.isBusy || vm.xpHistoryBusy
                        ? 'Đang tải...'
                        : 'Cập nhật tiến độ',
                    onPressed: vm.isBusy || vm.xpHistoryBusy ? null : _refresh),
                SizedBox(height: mc.space16),
                Text('Lịch sử EXP', style: mc.bodyStrongStyle),
                Text('Thời gian hiển thị theo thiết bị.',
                    style: mc.captionStyle),
                if (vm.xpHistoryBusy && !vm.xpHistoryLoaded)
                  Text('Đang tải lịch sử...', style: mc.bodyStyle),
                if (vm.xpHistoryLoaded && vm.xpHistory.isEmpty)
                  Text('Chưa có EXP được ghi nhận.', style: mc.bodyStyle),
                for (final entry in vm.xpHistory)
                  Padding(
                      padding: EdgeInsets.symmetric(vertical: mc.space8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${entry.delta >= 0 ? '+' : ''}${entry.delta} EXP · ${_reason(entry.reason)}',
                              style: mc.bodyStrongStyle),
                          Text(_date(entry.createdAt), style: mc.captionStyle),
                        ],
                      )),
                if (vm.xpHistoryError != null) ...[
                  Text(vm.xpHistoryError!,
                      style: mc.captionStyle.copyWith(color: mc.error)),
                  MindClockButton(
                      key: const ValueKey('profile-retry-history'),
                      label: 'Thử tải lịch sử lại',
                      onPressed: vm.xpHistoryBusy
                          ? null
                          : () =>
                              vm.loadXpHistory(refresh: !vm.xpHistoryLoaded)),
                ],
                if (vm.xpHistoryHasMore)
                  MindClockButton(
                      key: const ValueKey('profile-more-history'),
                      label: vm.xpHistoryBusy ? 'Đang tải...' : 'Xem thêm EXP',
                      onPressed: vm.xpHistoryBusy ? null : vm.loadXpHistory),
              ],
            ]),
          );
        },
      );
}
