"""Module chuẩn hóa và so khớp đáp án Toán, Khoa học Tự nhiên cho MindClock (T040).

Đảm bảo học sinh nhập:
- Số thập phân: `0,5` hay `0.5`, `3,14` hay `3.14`, số 0 thừa `2.50`
- Phân số & LaTeX: `3/4`, `0.75`, `\\frac{3}{4}`, `6/8`
- Biến số & phương trình: `x = 8`, `x=8`, `X = 8`, `8`
- Đơn vị đo lường: `2A`, `2 A`, `2 a`, `10 m/s`, `10m/s`, `2.5 kg`
đều được quy chuẩn và so khớp chính xác với `accepted_answers`.
"""

from __future__ import annotations

from dataclasses import dataclass
import math
import re
from typing import Any


UNIT_SYNONYMS: dict[str, str] = {
    # Dòng điện
    'a': 'a',
    'ampe': 'a',
    'ampere': 'a',
    'ma': 'ma',
    'miliampe': 'ma',
    'ka': 'ka',
    # Điện thế
    'v': 'v',
    'von': 'v',
    'volt': 'v',
    'mv': 'mv',
    'kv': 'kv',
    # Điện trở
    'ôm': 'ohm',
    'om': 'ohm',
    'ohm': 'ohm',
    'ω': 'ohm',
    'kohm': 'kohm',
    'kôm': 'kohm',
    # Chiều dài
    'm': 'm',
    'met': 'm',
    'mét': 'm',
    'cm': 'cm',
    'xentimet': 'cm',
    'mm': 'mm',
    'milimet': 'mm',
    'km': 'km',
    'kilomet': 'km',
    'dm': 'dm',
    # Khối lượng
    'kg': 'kg',
    'kilogam': 'kg',
    'kí': 'kg',
    'ki': 'kg',
    'g': 'g',
    'gam': 'g',
    'mg': 'mg',
    'miligam': 'mg',
    'tấn': 'tan',
    'tan': 'tan',
    # Thời gian
    's': 's',
    'giây': 's',
    'giay': 's',
    'sec': 's',
    'p': 'min',
    'phút': 'min',
    'phut': 'min',
    'min': 'min',
    'h': 'h',
    'giờ': 'h',
    'gio': 'h',
    'hour': 'h',
    # Vận tốc
    'm/s': 'm/s',
    'met/s': 'm/s',
    'mét/s': 'm/s',
    'km/h': 'km/h',
    # Gia tốc
    'm/s^2': 'm/s^2',
    'm/s2': 'm/s^2',
    # Lực
    'n': 'n',
    'newton': 'n',
    'kn': 'kn',
    # Năng lượng / Công
    'j': 'j',
    'jun': 'j',
    'joule': 'j',
    'kj': 'kj',
    'cal': 'cal',
    'calo': 'cal',
    'kcal': 'kcal',
    # Công suất
    'w': 'w',
    'oat': 'w',
    'watt': 'w',
    'kw': 'kw',
    'mw': 'mw',
    # Áp suất
    'pa': 'pa',
    'pascal': 'pa',
    'kpa': 'kpa',
    'atm': 'atm',
    'bar': 'bar',
    'mmhg': 'mmhg',
    # Nhiệt độ
    '°c': 'c',
    'độ c': 'c',
    'do c': 'c',
    'c': 'c',
    'k': 'k',
    'kelvin': 'k',
    # Nồng độ / Lượng chất
    'mol': 'mol',
    'mol/l': 'mol/l',
    # Tần số
    'hz': 'hz',
    'khz': 'khz',
    'mhz': 'mhz',
    # Góc
    'rad': 'rad',
    'radian': 'rad',
    'độ': 'deg',
    'do': 'deg',
    '°': 'deg',
    # Phần trăm
    '%': '%',
}


@dataclass
class ParsedAnswer:
    raw: str
    cleaned: str
    variable: str | None = None
    numeric_value: float | None = None
    fraction: tuple[int, int] | None = None
    unit: str | None = None
    is_numeric: bool = False


def _canonicalize_unit(raw_unit: str) -> str:
    cleaned = raw_unit.strip().lower()
    return UNIT_SYNONYMS.get(cleaned, cleaned)


def _canonicalize_symbolic_expr(text: str) -> str:
    """Chuẩn hóa ký hiệu Toán/Lý/Hóa phổ biến để so khớp biểu thức đại số & đạo hàm."""
    out = text.strip().lower()
    out = out.replace('²', '^2').replace('³', '^3')
    out = out.replace(r'\cdot', '*').replace('·', '*').replace('×', '*')
    out = re.sub(r'\\sqrt\{([^{}]+)\}', r'√(\1)', out)
    out = re.sub(r'(\d)\s+([a-z(√])', r'\1\2', out)
    out = re.sub(r'\s*([+\-*/^=()])\s*', r'\1', out)
    return re.sub(r'\s+', ' ', out).strip()


def _simplify_fraction(num: int, den: int) -> tuple[int, int]:
    if den < 0:
        num, den = -num, -den
    g = math.gcd(abs(num), abs(den))
    return (num // g, den // g)


def parse_answer(text: Any) -> ParsedAnswer:
    """Phân tích một chuỗi đáp án thành các trường cấu trúc số, biến và đơn vị."""
    if text is None:
        return ParsedAnswer(raw='', cleaned='')

    raw_str = str(text).strip()
    if not raw_str:
        return ParsedAnswer(raw='', cleaned='')

    cleaned = raw_str.strip().lower()
    cleaned = cleaned.replace('²', '^2').replace('³', '^3')

    # 1. Bóc tách LaTeX phân số: \frac{a}{b} -> a/b
    cleaned = re.sub(r'\\frac\{([+-]?\d+)\}\{([+-]?\d+)\}', r'\1/\2', cleaned)
    cleaned = re.sub(r'\\dfrac\{([+-]?\d+)\}\{([+-]?\d+)\}', r'\1/\2', cleaned)

    # 2. Xóa các tiền tố tập nghiệm như "s = {8}", "x \in {8}" -> "x = 8"
    cleaned = re.sub(r'^[a-z]\s*(\\in|\:|=)\s*\{([^}]+)\}$', r'\2', cleaned)

    # 3. Bóc tách phương trình biến: "x = 8", "y'(2) = 9", "i = 2a", "v = 10 m/s"
    var_name: str | None = None
    eq_match = re.match(r"^([a-z0-9_'\(\)]+)\s*=\s*(.+)$", cleaned)
    if eq_match:
        cand_var = eq_match.group(1).strip()
        # Biến số hợp lệ thường ngắn hoặc dạng hàm y'(x)
        if len(cand_var) <= 8:
            var_name = cand_var
            cleaned = eq_match.group(2).strip()

    # 4. Tách phần số và phần đơn vị
    # Ví dụ: "2.5 kg", "2,5kg", "2a", "10 m/s", "3/4"
    # Chuẩn hóa dấu phẩy số thập phân thành dấu chấm: "2,5" -> "2.5"
    norm_text = re.sub(r'(\d+),(\d+)', r'\1.\2', cleaned)

    # Phân số kèm đơn vị hoặc đứng một mình: "3/4", "3/4 m", "-1/2"
    frac_match = re.match(r'^([+-]?\d+)\s*/\s*([+-]?\d+)(?:\s+([a-z0-9_°/%\^]+))?$', norm_text)
    if frac_match:
        n_str, d_str, u_str = frac_match.groups()
        den = int(d_str)
        if den != 0:
            num = int(n_str)
            frac = _simplify_fraction(num, den)
            val = float(num) / float(den)
            unit = _canonicalize_unit(u_str) if u_str else None
            return ParsedAnswer(
                raw=raw_str,
                cleaned=cleaned,
                variable=var_name,
                numeric_value=val,
                fraction=frac,
                unit=unit,
                is_numeric=True,
            )

    # Số thập phân / nguyên kèm đơn vị: "2a", "2 a", "10 m/s", "2.5kg", "-8"
    # Regex nhận diện: bắt đầu bằng số [+-]?\d+(\.\d+)?, theo sau có thể là đơn vị
    num_unit_match = re.match(
        r'^([+-]?(?:\d+\.?\d*|\.\d+))(?:\s*([a-z°%][a-z0-9_°/%\^]*))?$',
        norm_text,
    )
    if num_unit_match:
        val_str, u_str = num_unit_match.groups()
        try:
            val = float(val_str)
            unit = _canonicalize_unit(u_str) if u_str else None
            return ParsedAnswer(
                raw=raw_str,
                cleaned=cleaned,
                variable=var_name,
                numeric_value=val,
                fraction=None,
                unit=unit,
                is_numeric=True,
            )
        except ValueError:
            pass

    # Nếu không phải cấu trúc số + đơn vị chuẩn thì giữ dạng text
    return ParsedAnswer(
        raw=raw_str,
        cleaned=cleaned,
        variable=var_name,
        numeric_value=None,
        fraction=None,
        unit=None,
        is_numeric=False,
    )


def is_answer_accepted(
    submitted_answer: Any,
    accepted_answers: list[Any],
    *,
    epsilon: float = 1e-5,
) -> bool:
    """So khớp đáp án học sinh nộp với danh sách `accepted_answers`.

    Tự động chuẩn hóa số thập phân, phân số, biến số và đơn vị đo lường.
    """
    if submitted_answer is None:
        return False

    sub_parsed = parse_answer(submitted_answer)
    sub_clean = sub_parsed.cleaned

    if not sub_clean:
        return False

    # 1. So khớp chuỗi trực tiếp & biểu thức đại số chuẩn hóa (cho trắc nghiệm, đạo hàm, lũy thừa)
    sub_symbolic = _canonicalize_symbolic_expr(sub_clean)
    for raw_acc in accepted_answers:
        if raw_acc is None:
            continue
        acc_str = str(raw_acc).strip().lower()
        if sub_clean == acc_str or sub_symbolic == _canonicalize_symbolic_expr(parse_answer(raw_acc).cleaned):
            return True

    # 2. So khớp số học & đơn vị đo lường
    for raw_acc in accepted_answers:
        if raw_acc is None:
            continue
        acc_parsed = parse_answer(raw_acc)

        # Trường hợp 2.1: Cả hai bên đều có giá trị số
        if sub_parsed.is_numeric and acc_parsed.is_numeric:
            assert sub_parsed.numeric_value is not None
            assert acc_parsed.numeric_value is not None

            # So khớp giá trị số (gần đúng sai số nhỏ)
            val_match = abs(sub_parsed.numeric_value - acc_parsed.numeric_value) < epsilon

            # Nếu cả 2 đều là phân số thì kiểm tra phân số tối giản
            if not val_match and sub_parsed.fraction and acc_parsed.fraction:
                val_match = sub_parsed.fraction == acc_parsed.fraction

            if not val_match:
                continue

            # Kiểm tra đơn vị đo:
            # - Nếu cả hai đều có đơn vị: phải cùng đơn vị chuẩn hóa
            # - Nếu 1 bên có đơn vị, 1 bên không có:
            #   Cho phép khớp (vì đề thi thường đã có sẵn đơn vị trong câu hỏi hoặc học sinh quen ghi đơn vị)
            unit_match = False
            if sub_parsed.unit and acc_parsed.unit:
                unit_match = sub_parsed.unit == acc_parsed.unit
            elif not sub_parsed.unit or not acc_parsed.unit:
                # 1 bên khuyết đơn vị: coi là hợp lệ
                unit_match = True

            if not unit_match:
                continue

            # Kiểm tra biến số (ví dụ: x = 8 vs x = 8 hoặc x = 8 vs 8)
            var_match = False
            if sub_parsed.variable and acc_parsed.variable:
                var_match = sub_parsed.variable == acc_parsed.variable
            else:
                var_match = True

            if var_match:
                return True

        # Trường hợp 2.2: So khớp đuôi chuỗi hoặc biến số
        # Ví dụ: submitted là "x = 8" nhưng accepted là "8" hoặc "x=8"
        clean_acc = acc_parsed.cleaned
        if clean_acc and (sub_clean.endswith(clean_acc) or clean_acc.endswith(sub_clean)):
            return True

    return False
