import 'package:flutter/material.dart';

import '../../../../domain/models/personal_flow_models.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_avatar_view.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../personal_flow/view_models/personal_flow_view_model.dart';

/// Bảng xếp hạng Học bá tuần theo môn học (T085 - opt-in công khai, không lộ giờ dậy/TKB).
Future<void> showWeeklyLeaderboardSheet({
  required BuildContext context,
  required PersonalFlowViewModel viewModel,
  String initialSubjectCode = 'TOAN',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.mc.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.mc.radiusCard),
      ),
    ),
    builder: (BuildContext ctx) => _WeeklyLeaderboardSheetBody(
      viewModel: viewModel,
      initialSubjectCode: initialSubjectCode,
    ),
  );
}

class _WeeklyLeaderboardSheetBody extends StatefulWidget {
  const _WeeklyLeaderboardSheetBody({
    required this.viewModel,
    required this.initialSubjectCode,
  });

  final PersonalFlowViewModel viewModel;
  final String initialSubjectCode;

  @override
  State<_WeeklyLeaderboardSheetBody> createState() =>
      _WeeklyLeaderboardSheetBodyState();
}

class _WeeklyLeaderboardSheetBodyState
    extends State<_WeeklyLeaderboardSheetBody> {
  static const List<String> _subjects = <String>[
    'TOAN',
    'NGU_VAN',
    'TIENG_ANH',
    'VAT_LY',
    'HOA_HOC',
  ];

  late String _selectedSubject;
  bool _togglingOptIn = false;

  @override
  void initState() {
    super.initState();
    _selectedSubject = _subjects.contains(widget.initialSubjectCode)
        ? widget.initialSubjectCode
        : 'TOAN';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.viewModel.loadWeeklyLeaderboard(subjectCode: _selectedSubject);
      }
    });
  }

  Future<void> _selectSubject(String code) async {
    setState(() => _selectedSubject = code);
    await widget.viewModel.loadWeeklyLeaderboard(subjectCode: code);
  }

  Future<void> _toggleOptIn(bool nextVal) async {
    if (_togglingOptIn) return;
    setState(() => _togglingOptIn = true);
    await widget.viewModel.setWeeklyLeaderboardOptIn(
      nextVal,
      subjectCode: _selectedSubject,
    );
    if (mounted) setState(() => _togglingOptIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(mc.space16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.82,
          ),
          child: ListenableBuilder(
            listenable: widget.viewModel,
            builder: (BuildContext context, _) {
              final WeeklySubjectLeaderboard? board =
                  widget.viewModel.weeklyLeaderboard;
              final bool loading = widget.viewModel.leaderboardBusy;
              final bool optedIn = board?.currentUserOptedIn ??
                  widget.viewModel.profileShowcase?.leaderboardOptIn ??
                  false;

              return SingleChildScrollView(
                key: const ValueKey<String>('weekly-leaderboard-sheet'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          'BXH Học bá tuần theo môn',
                          style: mc.sectionTitleStyle,
                        ),
                        MindClockStatusPill(
                          label: board?.weekWindowVi ?? '7 ngày gần nhất',
                        ),
                      ],
                    ),
                    SizedBox(height: mc.space4),
                    Text(
                      'Xếp hạng dựa trên điểm tuần & tỷ lệ đúng môn (tự nguyện công khai, tuyệt đối ẩn giờ dậy và TKB).',
                      style: mc.captionStyle,
                    ),
                    SizedBox(height: mc.space12),
                    Container(
                      padding: EdgeInsets.all(mc.space12),
                      decoration: BoxDecoration(
                        color: mc.paper,
                        borderRadius: BorderRadius.circular(mc.radiusControl),
                        border: Border.all(color: mc.outline),
                      ),
                      child: Wrap(
                        spacing: mc.space8,
                        runSpacing: mc.space8,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          Text(
                            optedIn
                                ? 'Đang tham gia bảng công khai'
                                : 'Đang ẩn khỏi bảng công khai',
                            style: mc.bodyStrongStyle,
                          ),
                          MindClockButton(
                            key: const ValueKey<String>(
                                'weekly-leaderboard-optin-btn'),
                            label: _togglingOptIn
                                ? 'Đang cập nhật...'
                                : (optedIn
                                    ? 'Ẩn tên của tôi'
                                    : 'Tham gia BXH tuần'),
                            icon: optedIn
                                ? MindClockIconKind.lock
                                : MindClockIconKind.check,
                            variant: optedIn
                                ? MindClockButtonVariant.subtle
                                : MindClockButtonVariant.secondary,
                            expand: false,
                            onPressed: _togglingOptIn
                                ? null
                                : () => _toggleOptIn(!optedIn),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: mc.space12),
                    Wrap(
                      spacing: mc.space8,
                      runSpacing: mc.space8,
                      children: _subjects
                          .map(
                            (String code) => ChoiceChip(
                              key: ValueKey<String>(
                                  'weekly-lb-subject-$code'),
                              label: Text(SubjectCatalog.nameFor(code)),
                              selected: _selectedSubject == code,
                              selectedColor: mc.primarySoft,
                              onSelected: (_) => _selectSubject(code),
                            ),
                          )
                          .toList(growable: false),
                    ),
                    SizedBox(height: mc.space12),
                    if (!widget.viewModel.authSession.isAuthenticated)
                      const MindClockNoticeBanner(
                        message:
                            'Đăng nhập tài khoản để đồng bộ BXH Học bá tuần trên máy chủ.',
                        isWarm: false,
                      )
                    else if (loading && board == null)
                      Center(
                        child: Padding(
                          padding: EdgeInsets.all(mc.space20),
                          child: CircularProgressIndicator(color: mc.primary),
                        ),
                      )
                    else if (board == null || board.entries.isEmpty)
                      MindClockNoticeBanner(
                        message:
                            'Tuần này chưa có học sinh công khai ở môn ${SubjectCatalog.nameFor(_selectedSubject)}. Bạn có thể bấm "Tham gia BXH tuần" để mở đầu!',
                        isWarm: false,
                      )
                    else
                      ...board.entries.map(
                        (WeeklyLeaderboardEntry item) => Container(
                          margin: EdgeInsets.only(bottom: mc.space8),
                          padding: EdgeInsets.all(mc.space12),
                          decoration: BoxDecoration(
                            color: item.isCurrentUser
                                ? mc.primarySoft
                                : mc.paper,
                            borderRadius:
                                BorderRadius.circular(mc.radiusControl),
                            border: Border.all(
                              color: item.isCurrentUser
                                  ? mc.primary
                                  : mc.outline,
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: item.rank <= 3
                                      ? mc.sunriseSoft
                                      : mc.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: item.rank <= 3
                                        ? mc.sunrise
                                        : mc.outline,
                                  ),
                                ),
                                child: Text(
                                  '#${item.rank}',
                                  style: mc.bodyStrongStyle,
                                ),
                              ),
                              SizedBox(width: mc.space12),
                              MindClockAvatarView(
                                avatarId: item.avatarId,
                                size: 40,
                                selected: item.isCurrentUser,
                              ),
                              SizedBox(width: mc.space12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Wrap(
                                      spacing: mc.space8,
                                      runSpacing: mc.space4,
                                      children: <Widget>[
                                        Text(
                                          item.alias,
                                          style: mc.bodyStrongStyle,
                                        ),
                                        MindClockStatusPill(
                                          label: item.seasonRank.labelVi,
                                          accentWarm: item.rank == 1,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: mc.space4 / 2),
                                    Text(
                                      '${item.gradeLevel} · ${item.equippedTitleVi} · Đúng ${item.accuracyPct}%',
                                      style: mc.captionStyle,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: mc.space8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: <Widget>[
                                  Text(
                                    '${item.weeklyScore} đ',
                                    style: mc.bodyStrongStyle,
                                  ),
                                  Text(
                                    '${item.earlyBirdDaysThisWeek}/7 sáng',
                                    style: mc.captionStyle,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    SizedBox(height: mc.space8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: MindClockButton(
                        label: 'Đóng',
                        variant: MindClockButtonVariant.subtle,
                        expand: false,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
