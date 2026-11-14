import 'package:flutter/widgets.dart';

import '../../../../domain/models/study_profile.dart';
import '../../../../domain/models/subject_catalog.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../view_models/guest_workspace_view_model.dart';

/// Tab Luyện tập rút gọn cho lát cắt P0 khách (chưa mở làm bài AI ở nhiệm vụ này).
class PracticePlaceholderScreen extends StatelessWidget {
  const PracticePlaceholderScreen({
    super.key,
    required this.viewModel,
    required this.onOpenProfileSetup,
  });

  final GuestWorkspaceViewModel viewModel;
  final VoidCallback onOpenProfileSetup;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final StudyProfile profile = viewModel.profile;

    return SingleChildScrollView(
      padding: EdgeInsets.all(mc.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(AppStrings.navPractice, style: mc.screenTitleStyle),
          SizedBox(height: mc.space12),
          MindClockCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Môn đã chọn theo hồ sơ khách',
                  style: mc.sectionTitleStyle,
                ),
                SizedBox(height: mc.space8),
                if (profile.selectedSubjectCodes.isEmpty)
                  Text(
                    'Bạn đang dùng chế độ Để sau / Chỉ báo thức. Khi thêm môn học, trạng thái bộ câu đã duyệt của từng môn sẽ hiện tại đây.',
                    style: mc.bodyStyle,
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: profile.selectedSubjectCodes.map((String code) {
                      final bool approved = SubjectCatalog.isApproved(code);
                      return Padding(
                        padding: EdgeInsets.only(bottom: mc.space8),
                        child: Text(
                          approved
                              ? '${SubjectCatalog.nameFor(code)}: đã có câu mẫu sẵn sàng cho lát cắt làm bài tiếp theo.'
                              : '${SubjectCatalog.nameFor(code)}: chưa có câu ôn duyệt (vẫn đặt được chuông thường / Chỉ báo thức).',
                          style: mc.bodyStyle,
                        ),
                      );
                    }).toList(growable: false),
                  ),
                SizedBox(height: mc.space12),
                MindClockButton(
                  key: const ValueKey<String>('practice-open-timetable'),
                  label: 'Chỉnh môn học & Thời khóa biểu',
                  icon: MindClockIconKind.edit,
                  variant: MindClockButtonVariant.secondary,
                  onPressed: onOpenProfileSetup,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
