import 'package:flutter/material.dart';

/// Hệ thống token giao diện MindClock (khớp 1:1 `docs/55 §4`).
///
/// Toàn bộ mã màu, khoảng cách, bo góc và cỡ chữ chỉ được khai báo tại đây;
/// widget không chứa hằng màu `Color(0x...)` hay `Duration` tùy biến rải rác.
@immutable
class MindClockTheme extends ThemeExtension<MindClockTheme> {
  const MindClockTheme({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.inkMuted,
    required this.night,
    required this.nightSurface,
    required this.nightText,
    required this.primary,
    required this.primarySoft,
    required this.sunrise,
    required this.sunriseSoft,
    required this.error,
    required this.outline,
    required this.onPrimary,
  });

  static const MindClockTheme light = MindClockTheme(
    paper: Color(0xFFF7F7F2),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1B2741),
    inkMuted: Color(0xFF526078),
    night: Color(0xFF101A30),
    nightSurface: Color(0xFF1C2944),
    nightText: Color(0xFFF7FAFF),
    primary: Color(0xFF126F73),
    primarySoft: Color(0xFFE7F2EF),
    sunrise: Color(0xFFF4B95F),
    sunriseSoft: Color(0xFFFCE6BC),
    error: Color(0xFFB23A48),
    outline: Color(0xFFD7DFE5),
    onPrimary: Color(0xFFFFFFFF),
  );

  final Color paper;
  final Color surface;
  final Color ink;
  final Color inkMuted;
  final Color night;
  final Color nightSurface;
  final Color nightText;
  final Color primary;
  final Color primarySoft;
  final Color sunrise;
  final Color sunriseSoft;
  final Color error;
  final Color outline;
  final Color onPrimary;

  // Lưới 4 dp theo `docs/55 §4`
  double get space4 => 4;
  double get space8 => 8;
  double get space12 => 12;
  double get space16 => 16;
  double get space20 => 20;
  double get space24 => 24;
  double get space32 => 32;

  // Bo góc 3 cấp (`docs/27`, `docs/55 §4`)
  double get radiusChip => 8;
  double get radiusControl => 14;
  double get radiusCard => 16;
  double get radiusPaper => 24;

  // Kích thước chạm tối thiểu
  double get minTouchTarget => 48;

  // Chuyển động (`docs/27 §5`, `docs/55 §4`)
  Duration get pressDuration => const Duration(milliseconds: 120);
  Duration get transitionDuration => const Duration(milliseconds: 220);

  TextStyle get alarmHeroStyle => TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: nightText,
      );

  TextStyle get screenTitleStyle => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
        color: ink,
      );

  TextStyle get sectionTitleStyle => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: ink,
      );

  TextStyle get bodyStyle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: ink,
      );

  TextStyle get bodyStrongStyle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: ink,
      );

  TextStyle get captionStyle => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: inkMuted,
      );

  TextStyle get chipLabelStyle => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: ink,
      );

  static ThemeData buildThemeData() {
    return ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: light.paper,
      canvasColor: light.paper,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      extensions: const <ThemeExtension<dynamic>>[light],
    );
  }

  static MindClockTheme of(BuildContext context) {
    final MindClockTheme? ext = Theme.of(context).extension<MindClockTheme>();
    assert(ext != null, 'MindClockTheme chua duoc gan trong ThemeData.extensions');
    return ext ?? light;
  }

  @override
  MindClockTheme copyWith({
    Color? paper,
    Color? surface,
    Color? ink,
    Color? inkMuted,
    Color? night,
    Color? nightSurface,
    Color? nightText,
    Color? primary,
    Color? primarySoft,
    Color? sunrise,
    Color? sunriseSoft,
    Color? error,
    Color? outline,
    Color? onPrimary,
  }) {
    return MindClockTheme(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      night: night ?? this.night,
      nightSurface: nightSurface ?? this.nightSurface,
      nightText: nightText ?? this.nightText,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      sunrise: sunrise ?? this.sunrise,
      sunriseSoft: sunriseSoft ?? this.sunriseSoft,
      error: error ?? this.error,
      outline: outline ?? this.outline,
      onPrimary: onPrimary ?? this.onPrimary,
    );
  }

  @override
  MindClockTheme lerp(ThemeExtension<MindClockTheme>? other, double t) {
    if (other is! MindClockTheme) return this;
    return MindClockTheme(
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      night: Color.lerp(night, other.night, t)!,
      nightSurface: Color.lerp(nightSurface, other.nightSurface, t)!,
      nightText: Color.lerp(nightText, other.nightText, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      sunrise: Color.lerp(sunrise, other.sunrise, t)!,
      sunriseSoft: Color.lerp(sunriseSoft, other.sunriseSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
    );
  }
}

extension MindClockThemeX on BuildContext {
  MindClockTheme get mc => MindClockTheme.of(this);
}
