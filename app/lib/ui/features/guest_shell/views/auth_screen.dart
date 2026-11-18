import 'package:flutter/material.dart';

import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../personal_flow/view_models/personal_flow_view_model.dart';

/// Màn hình Đăng ký / Đăng nhập tài khoản học sinh chuẩn MindClock theo `docs/07`.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.personalViewModel,
    required this.onAuthenticated,
    required this.onUseAlarmOnly,
    required this.onBackToWelcome,
  });

  final PersonalFlowViewModel personalViewModel;
  final ValueChanged<String?> onAuthenticated;
  final VoidCallback onUseAlarmOnly;
  final VoidCallback onBackToWelcome;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSignUp = true;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _confirmedAgeGroup = false;
  String? _localValidationError;

  @override
  void dispose() {
    _emailController.dispose();
    _aliasController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String alias = _aliasController.text.trim();

    setState(() => _localValidationError = null);

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() => _localValidationError = 'Vui lòng nhập địa chỉ email hợp lệ.');
      return;
    }
    if (password.length < 6) {
      setState(() => _localValidationError = 'Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }

    if (_isSignUp) {
      final String confirm = _confirmPasswordController.text;
      if (password != confirm) {
        setState(() => _localValidationError = 'Mật khẩu xác nhận không khớp.');
        return;
      }
      if (!_acceptedTerms) {
        setState(
          () => _localValidationError =
              'Vui lòng đồng ý điều khoản và chính sách dữ liệu trước khi tạo tài khoản.',
        );
        return;
      }
      if (!_confirmedAgeGroup) {
        setState(
          () => _localValidationError =
              'Vui lòng xác nhận bạn thuộc nhóm học sinh THPT hoặc đã có sự đồng ý của phụ huynh.',
        );
        return;
      }
      final bool ok = await widget.personalViewModel.signUp(
        email: email,
        password: password,
      );
      if (ok && mounted) {
        widget.onAuthenticated(alias.isNotEmpty ? alias : null);
      }
    } else {
      final bool ok = await widget.personalViewModel.signIn(
        email: email,
        password: password,
      );
      if (ok && mounted) {
        widget.onAuthenticated(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final String? serverError = widget.personalViewModel.errorMessageVi;
    final String? activeError = _localValidationError ?? serverError;
    final bool isBusy = widget.personalViewModel.isBusy;

    return DecoratedBox(
      decoration: BoxDecoration(color: mc.paper),
      child: SafeArea(
        child: SingleChildScrollView(
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
                  MindClockPressable(
                    key: const ValueKey<String>('auth-back-button'),
                    onPressed: widget.onBackToWelcome,
                    semanticLabel: 'Quay lại',
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: mc.space8,
                        vertical: mc.space4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          MindClockIcon(
                            MindClockIconKind.stop,
                            color: mc.inkMuted,
                            size: 16,
                          ),
                          SizedBox(width: mc.space4),
                          Text('Trang chủ', style: mc.captionStyle),
                        ],
                      ),
                    ),
                  ),
                  const MindClockStatusPill(label: 'Tài khoản học tập'),
                ],
              ),
              SizedBox(height: mc.space16),
              Text(
                _isSignUp ? 'Tạo tài khoản MindClock' : 'Đăng nhập MindClock',
                style: mc.screenTitleStyle,
              ),
              SizedBox(height: mc.space4),
              Text(
                _isSignUp
                    ? 'Đồng bộ kế hoạch học tập THPT, lưu kết quả làm bài sáng và kích hoạt trợ lý học tập AI.'
                    : 'Đăng nhập để khôi phục lộ trình học, lịch sử câu hỏi và tiếp tục chuỗi ngày.',
                style: mc.captionStyle,
              ),
              SizedBox(height: mc.space20),
              Container(
                decoration: BoxDecoration(
                  color: mc.surface,
                  borderRadius: BorderRadius.circular(mc.radiusControl),
                  border: Border.all(color: mc.outline),
                ),
                padding: EdgeInsets.all(mc.space4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: MindClockPressable(
                        key: const ValueKey<String>('auth-tab-signup'),
                        selected: _isSignUp,
                        semanticLabel: 'Tạo tài khoản mới',
                        onPressed: () {
                          if (!_isSignUp) {
                            setState(() {
                              _isSignUp = true;
                              _localValidationError = null;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: mc.space8),
                          decoration: BoxDecoration(
                            color: _isSignUp ? mc.primary : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(mc.radiusControl - 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Tạo tài khoản',
                            style: mc.bodyStrongStyle.copyWith(
                              color: _isSignUp ? mc.onPrimary : mc.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: MindClockPressable(
                        key: const ValueKey<String>('auth-tab-signin'),
                        selected: !_isSignUp,
                        semanticLabel: 'Đăng nhập',
                        onPressed: () {
                          if (_isSignUp) {
                            setState(() {
                              _isSignUp = false;
                              _localValidationError = null;
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: mc.space8),
                          decoration: BoxDecoration(
                            color: !_isSignUp ? mc.primary : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(mc.radiusControl - 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Đăng nhập',
                            style: mc.bodyStrongStyle.copyWith(
                              color: !_isSignUp ? mc.onPrimary : mc.inkMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space20),
              MindClockCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (_isSignUp) ...<Widget>[
                      Text('Biệt danh học tập', style: mc.captionStyle),
                      SizedBox(height: mc.space4),
                      TextField(
                        key: const ValueKey<String>('auth-alias-input'),
                        controller: _aliasController,
                        decoration: InputDecoration(
                          hintText: 'Ví dụ: Minh Khang, Mai Anh...',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(mc.radiusControl),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: mc.space12,
                            vertical: mc.space12,
                          ),
                        ),
                      ),
                      SizedBox(height: mc.space12),
                    ],
                    Text('Email', style: mc.captionStyle),
                    SizedBox(height: mc.space4),
                    TextField(
                      key: const ValueKey<String>('auth-email-input'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'name@example.com',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(mc.radiusControl),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: mc.space12,
                          vertical: mc.space12,
                        ),
                      ),
                    ),
                    SizedBox(height: mc.space12),
                    Text('Mật khẩu (tối thiểu 6 ký tự)', style: mc.captionStyle),
                    SizedBox(height: mc.space4),
                    TextField(
                      key: const ValueKey<String>('auth-password-input'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Nhập mật khẩu',
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(mc.radiusControl),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: mc.space12,
                          vertical: mc.space12,
                        ),
                        suffixIcon: MindClockPressable(
                          key: const ValueKey<String>('auth-toggle-password'),
                          semanticLabel: _obscurePassword
                              ? 'Hiện mật khẩu'
                              : 'Ẩn mật khẩu',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: mc.space12,
                              vertical: mc.space8,
                            ),
                            child: Text(
                              _obscurePassword ? 'Hiện' : 'Ẩn',
                              style: mc.chipLabelStyle.copyWith(
                                color: mc.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isSignUp) ...<Widget>[
                      SizedBox(height: mc.space12),
                      Text('Xác nhận mật khẩu', style: mc.captionStyle),
                      SizedBox(height: mc.space4),
                      TextField(
                        key: const ValueKey<String>(
                          'auth-confirm-password-input',
                        ),
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Nhập lại mật khẩu ở trên',
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(mc.radiusControl),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: mc.space12,
                            vertical: mc.space12,
                          ),
                        ),
                      ),
                      SizedBox(height: mc.space12),
                      _ConsentRow(
                        key: const ValueKey<String>('auth-consent-terms'),
                        checked: _acceptedTerms,
                        label:
                            'Tôi đồng ý điều khoản sử dụng và chính sách quyền riêng tư (v1; ảnh bài làm không lưu mặc định).',
                        onToggle: () => setState(() {
                          _acceptedTerms = !_acceptedTerms;
                          _localValidationError = null;
                        }),
                      ),
                      SizedBox(height: mc.space8),
                      _ConsentRow(
                        key: const ValueKey<String>('auth-consent-age'),
                        checked: _confirmedAgeGroup,
                        label:
                            'Tôi xác nhận thuộc nhóm học sinh THPT (15–18 tuổi) hoặc đã có sự đồng ý của phụ huynh.',
                        onToggle: () => setState(() {
                          _confirmedAgeGroup = !_confirmedAgeGroup;
                          _localValidationError = null;
                        }),
                      ),
                    ],
                    if (activeError != null) ...<Widget>[
                      SizedBox(height: mc.space12),
                      MindClockNoticeBanner(
                        key: const ValueKey<String>('auth-error-banner'),
                        message: activeError,
                        isWarm: true,
                      ),
                    ],
                    SizedBox(height: mc.space16),
                    MindClockButton(
                      key: const ValueKey<String>('auth-submit-btn'),
                      label: isBusy
                          ? 'Đang xử lý...'
                          : (_isSignUp
                              ? 'Tạo tài khoản & Tiếp tục'
                              : 'Đăng nhập vào hôm nay'),
                      icon: MindClockIconKind.user,
                      onPressed: isBusy ? null : _submit,
                    ),
                  ],
                ),
              ),
              SizedBox(height: mc.space20),
              const MindClockNoticeBanner(
                message:
                    'Báo thức và câu ôn tập buổi sáng luôn hoạt động độc lập, không phụ thuộc vào tình trạng mạng.',
                isWarm: false,
              ),
              SizedBox(height: mc.space16),
              MindClockButton(
                key: const ValueKey<String>('auth-offline-alarm-fallback'),
                label: 'Chỉ dùng báo thức trên máy',
                icon: MindClockIconKind.bell,
                variant: MindClockButtonVariant.subtle,
                onPressed: widget.onUseAlarmOnly,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
    super.key,
    required this.checked,
    required this.label,
    required this.onToggle,
  });

  final bool checked;
  final String label;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return MindClockPressable(
      selected: checked,
      semanticLabel: label,
      onPressed: onToggle,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(mc.space12),
        decoration: BoxDecoration(
          color: checked ? mc.primarySoft : mc.paper,
          borderRadius: BorderRadius.circular(mc.radiusControl),
          border: Border.all(color: checked ? mc.primary : mc.outline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: checked ? mc.primary : mc.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: checked ? mc.primary : mc.outline),
              ),
              alignment: Alignment.center,
              child: checked
                  ? MindClockIcon(
                      MindClockIconKind.check,
                      color: mc.onPrimary,
                      size: 14,
                    )
                  : null,
            ),
            SizedBox(width: mc.space8),
            Expanded(
              child: Text(
                label,
                style: mc.captionStyle.copyWith(color: mc.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
