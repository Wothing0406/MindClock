/// Chuẩn hóa đáp án Toán - Khoa học Tự nhiên cho MindClock Flutter client (T040).
///
/// Hỗ trợ:
/// - Số thập phân: `0,5` <-> `0.5`, `3,14` <-> `3.14`
/// - Phân số & LaTeX: `3/4` <-> `0.75`, `\\frac{1}{2}` <-> `0.5`
/// - Biến số: `x = 8`, `v = 10 m/s`, `I = 2A`
/// - Đơn vị: `2A`, `2 A`, `10 m/s`, `2.5 kg`
library;

class ParsedAnswer {
  const ParsedAnswer({
    required this.raw,
    required this.cleaned,
    this.variable,
    this.numericValue,
    this.unit,
    this.isNumeric = false,
  });

  final String raw;
  final String cleaned;
  final String? variable;
  final double? numericValue;
  final String? unit;
  final bool isNumeric;
}

const Map<String, String> _unitSynonyms = <String, String>{
  'a': 'a', 'ampe': 'a', 'ampere': 'a', 'ma': 'ma', 'ka': 'ka',
  'v': 'v', 'von': 'v', 'volt': 'v', 'mv': 'mv', 'kv': 'kv',
  'ôm': 'ohm', 'om': 'ohm', 'ohm': 'ohm', 'ω': 'ohm',
  'm': 'm', 'met': 'm', 'mét': 'm', 'cm': 'cm', 'mm': 'mm', 'km': 'km',
  'kg': 'kg', 'kilogam': 'kg', 'kí': 'kg', 'g': 'g', 'mg': 'mg', 'tấn': 'tan',
  's': 's', 'giây': 's', 'p': 'min', 'phút': 'min', 'h': 'h', 'giờ': 'h',
  'm/s': 'm/s', 'km/h': 'km/h', 'm/s^2': 'm/s^2', 'm/s2': 'm/s^2',
  'n': 'n', 'j': 'j', 'kj': 'kj', 'cal': 'cal', 'kcal': 'kcal',
  'w': 'w', 'kw': 'kw', 'pa': 'pa', 'atm': 'atm', 'bar': 'bar',
  '°c': 'c', 'độ c': 'c', 'c': 'c', 'k': 'k',
  'mol': 'mol', 'mol/l': 'mol/l', 'hz': 'hz', 'rad': 'rad', '%': '%',
};

String _canonicalizeUnit(String rawUnit) {
  final String lower = rawUnit.trim().toLowerCase();
  return _unitSynonyms[lower] ?? lower;
}

ParsedAnswer parseAnswer(dynamic text) {
  if (text == null) return const ParsedAnswer(raw: '', cleaned: '');
  final String rawStr = text.toString().trim();
  if (rawStr.isEmpty) return const ParsedAnswer(raw: '', cleaned: '');

  String cleaned = rawStr.toLowerCase().trim();

  // 1. Phân số LaTeX: \frac{a}{b} -> a/b
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\d?frac\{([+-]?\d+)\}\{([+-]?\d+)\}'),
    (Match m) => '${m[1]}/${m[2]}',
  );

  // 2. Biến số phương trình: x = 8, v = 10, i = 2a
  String? variable;
  final Match? eqMatch = RegExp(r"^([a-z0-9_'\(\)]+)\s*=\s*(.+)$").firstMatch(cleaned);
  if (eqMatch != null) {
    final String candVar = eqMatch.group(1)!.trim();
    if (candVar.length <= 8) {
      variable = candVar;
      cleaned = eqMatch.group(2)!.trim();
    }
  }

  // 3. Chuẩn hóa dấu phẩy số thập phân: 0,5 -> 0.5
  final String normText = cleaned.replaceAllMapped(
    RegExp(r'(\d+),(\d+)'),
    (Match m) => '${m[1]}.${m[2]}',
  );

  // 4. Phân số: a/b [đơn vị]
  final Match? fracMatch = RegExp(
    r'^([+-]?\d+)\s*/\s*([+-]?\d+)(?:\s+([a-z0-9_°/%\^]+))?$',
  ).firstMatch(normText);
  if (fracMatch != null) {
    final int? num = int.tryParse(fracMatch.group(1) ?? '');
    final int? den = int.tryParse(fracMatch.group(2) ?? '');
    final String? uStr = fracMatch.group(3);
    if (num != null && den != null && den != 0) {
      final double val = num / den;
      final String? unit = uStr != null ? _canonicalizeUnit(uStr) : null;
      return ParsedAnswer(
        raw: rawStr,
        cleaned: cleaned,
        variable: variable,
        numericValue: val,
        unit: unit,
        isNumeric: true,
      );
    }
  }

  // 5. Số thập phân / nguyên kèm đơn vị: 2a, 10 m/s, 2.5 kg
  final Match? numMatch = RegExp(
    r'^([+-]?(?:\d+\.?\d*|\.\d+))(?:\s*([a-z°%][a-z0-9_°/%\^]*))?$',
  ).firstMatch(normText);
  if (numMatch != null) {
    final double? val = double.tryParse(numMatch.group(1) ?? '');
    final String? uStr = numMatch.group(2);
    if (val != null) {
      final String? unit = uStr != null ? _canonicalizeUnit(uStr) : null;
      return ParsedAnswer(
        raw: rawStr,
        cleaned: cleaned,
        variable: variable,
        numericValue: val,
        unit: unit,
        isNumeric: true,
      );
    }
  }

  return ParsedAnswer(
    raw: rawStr,
    cleaned: cleaned,
    variable: variable,
    numericValue: null,
    unit: null,
    isNumeric: false,
  );
}

bool isAnswerAccepted(
  dynamic submittedAnswer,
  List<dynamic> acceptedAnswers, {
  double epsilon = 1e-5,
}) {
  if (submittedAnswer == null) return false;
  final ParsedAnswer sub = parseAnswer(submittedAnswer);
  if (sub.cleaned.isEmpty) return false;

  // 1. So chuỗi trực tiếp
  for (final dynamic rawAcc in acceptedAnswers) {
    if (rawAcc == null) continue;
    if (sub.cleaned == rawAcc.toString().trim().toLowerCase()) {
      return true;
    }
  }

  // 2. So số học và đơn vị
  for (final dynamic rawAcc in acceptedAnswers) {
    if (rawAcc == null) continue;
    final ParsedAnswer acc = parseAnswer(rawAcc);

    if (sub.isNumeric && acc.isNumeric) {
      final double subVal = sub.numericValue!;
      final double accVal = acc.numericValue!;

      if ((subVal - accVal).abs() > epsilon) continue;

      // Đơn vị đo: nếu cả hai đều có thì phải khớp; nếu 1 bên có 1 bên không thì coi là hợp lệ
      bool unitMatch = true;
      if (sub.unit != null && acc.unit != null) {
        unitMatch = sub.unit == acc.unit;
      }
      if (!unitMatch) continue;

      // Biến số
      bool varMatch = true;
      if (sub.variable != null && acc.variable != null) {
        varMatch = sub.variable == acc.variable;
      }
      if (varMatch) return true;
    }

    // Đuôi chuỗi
    if (acc.cleaned.isNotEmpty &&
        (sub.cleaned.endsWith(acc.cleaned) || acc.cleaned.endsWith(sub.cleaned))) {
      return true;
    }
  }

  return false;
}
