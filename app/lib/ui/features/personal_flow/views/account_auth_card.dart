import 'package:flutter/material.dart';

import '../../../../domain/models/auth_session.dart';
import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../view_models/personal_flow_view_model.dart';

/// Thẻ đăng nhập / đăng ký / đăng xuất và cảnh báo hết hạn token cho luồng cá nhân.
class AccountAuthCard extends StatefulWidget {
  const AccountAuthCard({
    super.key,
    required this.viewModel,
  });

  final PersonalFlowViewModel viewModel;

  @override
  State<AccountAuthCard> createState() => _AccountAuthCardState();
}

class _AccountAuthCardState extends State<AccountAuthCard> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final bool ok = _isSignUp
        ? await widget.viewModel.signUp(email: email, password: password)
        : await widget.viewModel.signIn(email: email, password: password);
    if (ok) {
      _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final AuthSession session = widget.viewModel.authSession;

    return MindClockCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: mc.space8,
            runSpacing: mc.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              Text('Tài khoản đồng bộ trực tuyến', style: mc.sectionTitleStyle),
              if (widget.viewModel.isDebugFixture)
                const MindClockStatusPill(
                  label: 'Fixture debug · Không phải dịch vụ thật',
                  accentWarm: true,
                ),
            ],
          ),
          SizedBox(height: mc.space8),
          if (session.status == AuthStatus.reauthRequired) ...<Widget>[
            MindClockNoticeBanner(
              message: session.statusMessageVi ??
                  'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại (báo thức local vẫn hoạt động).',
            ),
            SizedBox(height: mc.space12),
          ],
          if (session.isAuthenticated) ...<Widget>[
            Text(
              'Đang đăng nhập: ${session.email ?? session.uid}',
              key: const ValueKey<String>('auth-logged-in-email'),
              style: mc.bodyStrongStyle,
            ),
            SizedBox(height: mc.space4),
            Text(
              'Tiến độ và bản nháp chữ được tách riêng cho tài khoản này; đăng xuất không xóa chuông local.',
              style: mc.captionStyle,
            ),
            SizedBox(height: mc.space12),
            MindClockButton(
              key: const ValueKey<String>('auth-sign-out-button'),
              label: 'Đăng xuất (giữ báo thức local)',
              icon: MindClockIconKind.user,
              variant: MindClockButtonVariant.secondary,
              onPressed: widget.viewModel.isBusy
                  ? null
                  : () => widget.viewModel.signOut(),
            ),
          ] else ...<Widget>[
            Text(
              'Đăng nhập bằng email để đồng bộ câu hỏi, chấm bài và XP server. Khách local vẫn dùng báo thức không cần đăng nhập.',
              style: mc.captionStyle,
            ),
            SizedBox(height: mc.space12),
            TextField(
              key: const ValueKey<String>('auth-email-field'),
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: mc.space12),
            TextField(
              key: const ValueKey<String>('auth-password-field'),
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: mc.space12),
            Wrap(
              spacing: mc.space8,
              runSpacing: mc.space8,
              children: <Widget>[
                MindClockPressable(
                  key: const ValueKey<String>('auth-mode-toggle'),
                  onPressed: () => setState(() => _isSignUp = !_isSignUp),
                  semanticLabel: _isSignUp
                      ? 'Chuyển sang đăng nhập'
                      : 'Chuyển sang tạo tài khoản',
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: mc.space12,
                      vertical: mc.space8,
                    ),
                    decoration: BoxDecoration(
                      color: mc.paper,
                      borderRadius: BorderRadius.circular(mc.radiusChip),
                      border: Border.all(color: mc.outline),
                    ),
                    child: Text(
                      _isSignUp
                          ? 'Đã có tài khoản? Đăng nhập'
                          : 'Chưa có tài khoản? Tạo mới',
                      style: mc.chipLabelStyle,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: mc.space12),
            MindClockButton(
              key: const ValueKey<String>('auth-submit-button'),
              label: _isSignUp ? 'Tạo tài khoản online' : 'Đăng nhập online',
              icon: MindClockIconKind.user,
              onPressed: widget.viewModel.isBusy ? null : _submit,
            ),
          ],
          if (widget.viewModel.errorMessageVi != null &&
              !session.isAuthenticated) ...<Widget>[
            SizedBox(height: mc.space12),
            MindClockNoticeBanner(
              message: widget.viewModel.errorMessageVi!,
            ),
          ],
        ],
      ),
    );
  }
}
