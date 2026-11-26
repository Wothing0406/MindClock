import 'package:flutter/widgets.dart';

/// Hiển thị công thức Toán/Lý/Hóa Tiếng Việt rõ ràng (`T060`, `AC-04`).
///
/// Chuyển đổi biểu thức lũy thừa (`x^2`, `x^{n+1}`, `10^-6`), căn (`sqrt`, `\sqrt`),
/// phân số (`\frac{a}{b}` -> `a/b`), `%`, đạo hàm (`f'(x)`), `π`, `Δ`, `→`
/// thành text có chỉ số trên (`WidgetSpan` / ký tự chuẩn) dễ đọc, tương thích TalkBack.
class MathFormulaText extends StatelessWidget {
  const MathFormulaText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  static String normalizeReadableSymbols(String raw) {
    String out = raw;
    // \frac{a}{b} -> a/b
    out = out.replaceAllMapped(
      RegExp(r'\\frac\{([^{}]+)\}\{([^{}]+)\}'),
      (Match m) {
        String group(String value) =>
            RegExp(r'^[A-Za-z0-9.]+$').hasMatch(value) ? value : '($value)';
        return '${group(m.group(1)!)}/${group(m.group(2)!)}';
      },
    );
    out = out.replaceAllMapped(
      RegExp(r'\\(?:mathrm|text)\{([^{}]*)\}'),
      (Match m) => m.group(1)!,
    );
    out = out
        .replaceAll(r'\%', '%')
        .replaceAll(r'\left', '')
        .replaceAll(r'\right', '')
        .replaceAll(r'\,', ' ')
        .replaceAll(r'\;', ' ')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\neq', '≠');
    // \sqrt{...} or sqrt(...)
    out = out.replaceAllMapped(
      RegExp(r'\\sqrt\{([^{}]+)\}'),
      (Match m) => '√(${m.group(1)})',
    );
    out = out.replaceAllMapped(
      RegExp(r'\bsqrt\(([^()]+)\)'),
      (Match m) => '√(${m.group(1)})',
    );
    out = out
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\Delta', 'Δ')
        .replaceAll(r'\delta', 'δ')
        .replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β')
        .replaceAll(r'\gamma', 'γ')
        .replaceAll(r'\omega', 'ω')
        .replaceAll(r'\le', '≤')
        .replaceAll(r'\ge', '≥')
        .replaceAll(r'\ne', '≠')
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\cdot', '·')
        .replaceAll(r'\times', '×')
        .replaceAll('->', '→')
        .replaceAll('>=', '≥')
        .replaceAll('<=', '≤')
        .replaceAll('!=', '≠')
        .replaceAll(r'$', '');
    return out;
  }

  static List<InlineSpan> _buildSpans(String input, TextStyle baseStyle) {
    final String normalized = normalizeReadableSymbols(input);
    final List<InlineSpan> spans = <InlineSpan>[];
    final RegExp supPattern = RegExp(
      r'([\^_])(?:\{([^{}]+)\}|(-?\d+|[A-Za-z]))',
    );

    int cursor = 0;
    for (final RegExpMatch match in supPattern.allMatches(normalized)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: normalized.substring(cursor, match.start)));
      }
      final String exponent = match.group(2) ?? match.group(3) ?? '';
      final bool subscript = match.group(1) == '_';
      final double baseSize = baseStyle.fontSize ?? 15;
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.top,
          child: Transform.translate(
            offset: Offset(0, baseSize * (subscript ? 0.22 : -0.22)),
            child: Text(
              exponent,
              style: baseStyle.copyWith(
                fontSize: baseSize * 0.72,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
          ),
        ),
      );
      cursor = match.end;
    }

    if (cursor < normalized.length) {
      spans.add(TextSpan(text: normalized.substring(cursor)));
    }
    if (spans.isEmpty) {
      spans.add(TextSpan(text: normalized));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle effectiveStyle =
        style ?? DefaultTextStyle.of(context).style;
    return Semantics(
      label: normalizeReadableSymbols(text),
      child: Text.rich(
        TextSpan(
          style: effectiveStyle,
          children: _buildSpans(text, effectiveStyle),
        ),
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.clip,
      ),
    );
  }
}
