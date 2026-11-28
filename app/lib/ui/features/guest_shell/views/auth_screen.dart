import 'package:flutter/material.dart';

import '../../../core/theme/mindclock_theme.dart';
import '../../../core/widgets/mindclock_cards.dart';
import '../../../core/widgets/mindclock_icon.dart';
import '../../../core/widgets/mindclock_pressable.dart';
import '../../personal_flow/view_models/personal_flow_view_model.dart';

/// Quy chuẩn mật khẩu mạnh bắt buộc khi đăng ký tài khoản MindClock.
class StrongPasswordEvaluation {
  const StrongPasswordEvaluation({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  static const int minLength = 8;

  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  bool get isValid =>
      hasMinLength &&
      hasUppercase &&
      hasLowercase &&
      hasDigit &&
      hasSpecialChar;

  String? get firstErrorVi {
    if (!hasMinLength) return 'Mật khẩu phải có ít nhất $minLength ký tự.';
    if (!hasUppercase) return 'Mật khẩu phải có ít nhất 1 chữ cái in hoa (A–Z).';
    if (!hasLowercase) return 'Mật khẩu phải có ít nhất 1 chữ cái thường (a–z).';
    if (!hasDigit) return 'Mật khẩu phải có ít nhất 1 chữ số (0–9).';
    if (!hasSpecialChar) {
      return 'Mật khẩu phải có ít nhất 1 ký tự đặc biệt (VD: ! @ # \$ % ^ & *).';
    }
    return null;
  }

  static StrongPasswordEvaluation evaluate(String password) {
    return StrongPasswordEvaluation(
      hasMinLength: password.length >= minLength,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasDigit: RegExp(r'[0-9]').hasMatch(password),
      hasSpecialChar: RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(password),
    );
  }
}

/// Màn hình Đăng ký / Đăng nhập tài khoản học sinh chuẩn MindClock theo `docs/07`.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.personalViewModel,
    required this.onAuthenticated,
    this.onUseAlarmOnly,
    required this.onBackToWelcome,
    this.preferLoginTab = false,
  });

  final PersonalFlowViewModel personalViewModel;
  final ValueChanged<String?> onAuthenticated;
  final VoidCallback? onUseAlarmOnly;
  final VoidCallback onBackToWelcome;
  final bool preferLoginTab;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late bool _isSignUp;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _confirmedAgeGroup = false;
  String? _localValidationError;

  @override
  void initState() {
    super.initState();
    _isSignUp = !widget.preferLoginTab;
  }

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

    if (_isSignUp) {
      final StrongPasswordEvaluation pwdEval =
          StrongPasswordEvaluation.evaluate(password);
      if (!pwdEval.isValid) {
        setState(() => _localValidationError = pwdEval.firstErrorVi);
        return;
      }
      final String confirm = _confirmPasswordController.text;
      if (password != confirm) {
        setState(() => _localValidationError = 'Mật khẩu xác nhận không khớp.');
        return;
      }
      if (!_acceptedTerms) {
        setState(
          () => _localValidationError =
              'Vui lòng đọc và đồng ý Điều khoản sử dụng & Chính sách bảo mật trước khi tạo tài khoản.',
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
      if (password.length < 6) {
        setState(() => _localValidationError = 'Mật khẩu đăng nhập không hợp lệ.');
        return;
      }
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
                          Flexible(
                            child: Text('Trang chủ', style: mc.captionStyle),
                          ),
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
                    Text(
                      _isSignUp
                          ? 'Mật khẩu mạnh (tối thiểu 8 ký tự)'
                          : 'Mật khẩu',
                      style: mc.captionStyle,
                    ),
                    SizedBox(height: mc.space4),
                    TextField(
                      key: const ValueKey<String>('auth-password-input'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) {
                        if (_isSignUp) {
                          setState(() => _localValidationError = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: _isSignUp
                            ? 'VD: MindClock@2026'
                            : 'Nhập mật khẩu',
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
                      SizedBox(height: mc.space8),
                      _PasswordStrengthChecklist(
                        evaluation: StrongPasswordEvaluation.evaluate(
                          _passwordController.text,
                        ),
                      ),
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
                      MindClockButton(
                        key: const ValueKey<String>('auth-view-policy-btn'),
                        label: 'Đọc toàn văn Chính sách Bảo mật & Điều khoản (v2026-11)',
                        icon: MindClockIconKind.book,
                        variant: MindClockButtonVariant.secondary,
                        onPressed: () async {
                          final bool? agreed = await _showPolicyDialog(context);
                          if (agreed == true && mounted) {
                            setState(() {
                              _acceptedTerms = true;
                              _localValidationError = null;
                            });
                          }
                        },
                      ),
                      SizedBox(height: mc.space8),
                      _ConsentRow(
                        key: const ValueKey<String>('auth-consent-terms'),
                        checked: _acceptedTerms,
                        label:
                            'Tôi đã đọc và đồng ý Điều khoản sử dụng & Chính sách quyền riêng tư MindClock (v2026-11).',
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
                    'Đăng nhập để đồng bộ lịch học, báo thức và tiến độ ôn tập của bạn.',
                isWarm: false,
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

class _PasswordStrengthChecklist extends StatelessWidget {
  const _PasswordStrengthChecklist({required this.evaluation});

  final StrongPasswordEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    final List<({String label, bool ok})> rules = <({String label, bool ok})>[
      (label: 'Từ ${StrongPasswordEvaluation.minLength} ký tự trở lên', ok: evaluation.hasMinLength),
      (label: 'Chữ in hoa (A–Z)', ok: evaluation.hasUppercase),
      (label: 'Chữ thường (a–z)', ok: evaluation.hasLowercase),
      (label: 'Chữ số (0–9)', ok: evaluation.hasDigit),
      (label: 'Ký tự đặc biệt (!@#...)', ok: evaluation.hasSpecialChar),
    ];

    return Container(
      key: const ValueKey<String>('auth-password-rules'),
      width: double.infinity,
      padding: EdgeInsets.all(mc.space12),
      decoration: BoxDecoration(
        color: evaluation.isValid ? mc.primarySoft : mc.paper,
        borderRadius: BorderRadius.circular(mc.radiusControl),
        border: Border.all(
          color: evaluation.isValid ? mc.primary : mc.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rules.map((({String label, bool ok}) rule) {
          return Padding(
            padding: EdgeInsets.only(bottom: mc.space4),
            child: Row(
              children: <Widget>[
                MindClockIcon(
                  rule.ok ? MindClockIconKind.check : MindClockIconKind.lock,
                  size: 13,
                  color: rule.ok ? mc.primary : mc.inkMuted,
                ),
                SizedBox(width: mc.space8),
                Expanded(
                  child: Text(
                    rule.label,
                    style: mc.captionStyle.copyWith(
                      color: rule.ok ? mc.primary : mc.inkMuted,
                      fontWeight: rule.ok ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

Future<bool?> _showPolicyDialog(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.mc.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(context.mc.radiusPaper),
      ),
    ),
    builder: (BuildContext sheetContext) {
      final MindClockTheme mc = sheetContext.mc;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(mc.space20),
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.78,
            child: Column(
              key: const ValueKey<String>('auth-policy-dialog'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Chính sách Bảo mật & Điều khoản MindClock (v2026-11)',
                  style: mc.sectionTitleStyle,
                ),
                SizedBox(height: mc.space4),
                Text(
                  'Vui lòng đọc kỹ trước khi xác nhận tạo tài khoản.',
                  style: mc.captionStyle,
                ),
                SizedBox(height: mc.space12),
                const Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _PolicySection(
                          title: '1. Dữ liệu tài khoản & Quyền riêng tư',
                          body:
                              'Email chỉ dùng để xác thực và khôi phục tài khoản; hệ thống không yêu cầu số điện thoại, họ tên pháp lý hay địa chỉ trường/nhà. Mật khẩu được bảo mật qua Firebase Auth và không lưu dưới dạng văn bản thuần.',
                        ),
                        _PolicySection(
                          title: '2. Ảnh bài làm, Camera & Micro',
                          body:
                              'Camera và micro tắt mặc định. Ảnh bài làm bạn chụp được xử lý tạm thời trong bộ nhớ để chấm/gợi mở và không lưu vĩnh viễn mặc định trên hệ thống. Ứng dụng không quay video nền để chấm điểm biểu cảm.',
                        ),
                        _PolicySection(
                          title: '3. Cộng đồng, Kết bạn & Phòng học',
                          body:
                              'Hồ sơ công khai chỉ hiển thị biệt danh, avatar, lớp, môn học và mục tiêu học. Giờ báo thức, lịch ngủ, thời khóa biểu chi tiết và email được giữ riêng tư tuyệt đối. Bạn luôn có quyền chặn, báo cáo hoặc rời phòng bất kỳ lúc nào.',
                        ),
                        _PolicySection(
                          title: '4. Quyền rút đồng ý & Xóa tài khoản',
                          body:
                              'Trong mục Tôi → Tài khoản & dữ liệu, bạn có thể xuất hoặc xóa vĩnh viễn dữ liệu tài khoản bất kỳ lúc nào.',
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: mc.space12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: MindClockButton(
                        key: const ValueKey<String>('auth-policy-close-btn'),
                        label: 'Đóng',
                        variant: MindClockButtonVariant.secondary,
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                      ),
                    ),
                    SizedBox(width: mc.space8),
                    Expanded(
                      child: MindClockButton(
                        key: const ValueKey<String>('auth-policy-accept-btn'),
                        label: 'Tôi đã đọc & Đồng ý',
                        icon: MindClockIconKind.check,
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Padding(
      padding: EdgeInsets.only(bottom: mc.space12),
      child: Container(
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
            Text(title, style: mc.bodyStrongStyle),
            SizedBox(height: mc.space4),
            Text(body, style: mc.bodyStyle),
          ],
        ),
      ),
    );
  }
}
