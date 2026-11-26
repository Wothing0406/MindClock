import 'package:flutter/material.dart';

import '../theme/mindclock_theme.dart';
import 'mindclock_pressable.dart';
import 'math_formula_text.dart';

/// Thanh bàn phím ký hiệu Toán/Lý/Hóa chèn trực tiếp tại vị trí con trỏ (`T060`, `AC-04`).
///
/// Tuân thủ theme tokens `context.mc` (không hardcode hex color) và wrap gọn ở `320dp`, chữ 200%.
class MathInputKeypad extends StatelessWidget {
  const MathInputKeypad({
    super.key,
    required this.controller,
    this.onChanged,
    this.compact = false,
  });

  final TextEditingController controller;
  final VoidCallback? onChanged;
  final bool compact;

  static const List<_MathKeyDef> _keys = <_MathKeyDef>[
    _MathKeyDef(id: 'pow2', label: 'x²', insert: '^2', semantic: 'Chèn mũ 2'),
    _MathKeyDef(id: 'pow3', label: 'x³', insert: '^3', semantic: 'Chèn mũ 3'),
    _MathKeyDef(id: 'pow', label: '^', insert: '^', semantic: 'Chèn dấu mũ'),
    _MathKeyDef(id: 'frac', label: '/', insert: '/', semantic: 'Chèn phân số'),
    _MathKeyDef(
        id: 'percent', label: '%', insert: '%', semantic: 'Chèn phần trăm'),
    _MathKeyDef(
        id: 'sqrt', label: '√', insert: '√', semantic: 'Chèn căn bậc hai'),
    _MathKeyDef(
        id: 'prime', label: "'", insert: "'", semantic: 'Chèn dấu đạo hàm'),
    _MathKeyDef(id: 'pi', label: 'π', insert: 'π', semantic: 'Chèn số pi'),
    _MathKeyDef(id: 'delta', label: 'Δ', insert: 'Δ', semantic: 'Chèn Delta'),
    _MathKeyDef(
        id: 'arrow', label: '→', insert: '→', semantic: 'Chèn dấu suy ra'),
    _MathKeyDef(id: 'eq', label: '=', insert: '=', semantic: 'Chèn dấu bằng'),
    _MathKeyDef(
        id: 'lparen', label: '(', insert: '(', semantic: 'Chèn mở ngoặc'),
    _MathKeyDef(
        id: 'rparen', label: ')', insert: ')', semantic: 'Chèn đóng ngoặc'),
    _MathKeyDef(
        id: 'sub', label: 'x₂', insert: '_2', semantic: 'Chèn chỉ số dưới 2'),
    _MathKeyDef(
        id: 'times', label: '×', insert: '×', semantic: 'Chèn dấu nhân'),
    _MathKeyDef(id: 'degree', label: '°', insert: '°', semantic: 'Chèn độ'),
    _MathKeyDef(
        id: 'unit',
        label: 'm/s²',
        insert: ' m/s^2',
        semantic: 'Chèn mét trên giây bình phương'),
  ];

  void _insertToken(String token) {
    final TextEditingValue value = controller.value;
    final String text = value.text;
    final TextSelection sel = value.selection;
    final int start =
        sel.isValid ? sel.start.clamp(0, text.length) : text.length;
    final int end =
        sel.isValid ? sel.end.clamp(start, text.length) : text.length;
    final String nextText = text.replaceRange(start, end, token);
    final int nextOffset = start + token.length;
    controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
    onChanged?.call();
  }

  void _backspaceAtCursor() {
    final TextEditingValue value = controller.value;
    final String text = value.text;
    if (text.isEmpty) return;
    final TextSelection sel = value.selection;
    final int start =
        sel.isValid ? sel.start.clamp(0, text.length) : text.length;
    final int end =
        sel.isValid ? sel.end.clamp(start, text.length) : text.length;
    if (start != end) {
      controller.value = TextEditingValue(
        text: text.replaceRange(start, end, ''),
        selection: TextSelection.collapsed(offset: start),
      );
    } else if (start > 0) {
      controller.value = TextEditingValue(
        text: text.replaceRange(start - 1, start, ''),
        selection: TextSelection.collapsed(offset: start - 1),
      );
    }
    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final MindClockTheme mc = context.mc;
    return Container(
      key: const ValueKey<String>('math-input-keypad'),
      width: double.infinity,
      padding: EdgeInsets.all(mc.space8),
      decoration: BoxDecoration(
        color: mc.paper,
        borderRadius: BorderRadius.circular(mc.radiusControl),
        border: Border.all(color: mc.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!compact) ...<Widget>[
            Text(
              'Ký hiệu nhanh (mũ, phân số, %, đạo hàm, căn)',
              style: mc.captionStyle,
            ),
            SizedBox(height: mc.space8),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: mc.space8,
              runSpacing: mc.space8,
              children: <Widget>[
                ..._keys.map(
                  (_MathKeyDef keyDef) => MindClockPressable(
                    key: ValueKey<String>('math-key-${keyDef.id}'),
                    semanticLabel: keyDef.semantic,
                    onPressed: () => _insertToken(keyDef.insert),
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: 40,
                        minHeight: compact ? 38 : 42,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: mc.space12,
                        vertical: mc.space8,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: mc.surface,
                        borderRadius: BorderRadius.circular(mc.radiusChip),
                        border: Border.all(color: mc.outline),
                      ),
                      child: Text(
                        keyDef.label,
                        style: mc.bodyStrongStyle.copyWith(color: mc.primary),
                      ),
                    ),
                  ),
                ),
                MindClockPressable(
                  key: const ValueKey<String>('math-key-backspace'),
                  semanticLabel: 'Xóa 1 ký tự trước con trỏ',
                  onPressed: _backspaceAtCursor,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 44,
                      minHeight: compact ? 38 : 42,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: mc.space12,
                      vertical: mc.space8,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: mc.sunriseSoft,
                      borderRadius: BorderRadius.circular(mc.radiusChip),
                      border: Border.all(color: mc.outline),
                    ),
                    child: Text('Xóa', style: mc.chipLabelStyle),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.only(top: mc.space8),
                    child: MathFormulaText(value.text, style: mc.bodyStyle),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MathKeyDef {
  const _MathKeyDef({
    required this.id,
    required this.label,
    required this.insert,
    required this.semantic,
  });

  final String id;
  final String label;
  final String insert;
  final String semantic;
}
