import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/core/widgets/math_formula_text.dart';
import 'package:mindclock_app/ui/core/widgets/math_input_keypad.dart';

void main() {
  testWidgets(
    'T060 TC-02: MathFormulaText render rõ mũ/phân số/%/căn/đạo hàm và MathInputKeypad chèn tại con trỏ ở 320dp 200%',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final TextEditingController controller =
          TextEditingController(text: '3x');
      controller.selection = const TextSelection.collapsed(offset: 2);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 760),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: MindClockTheme.buildThemeData(),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const MathFormulaText(
                      r"f'(x) = 3x^2 + \frac{1}{2} - 25% + \sqrt{9} -> \Delta\pi",
                      key: ValueKey<String>('test-math-formula'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const ValueKey<String>('test-math-field'),
                      controller: controller,
                    ),
                    const SizedBox(height: 8),
                    MathInputKeypad(controller: controller),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byKey(const ValueKey<String>('test-math-formula'))).label,
        contains("f'(x) = 3x^2 + 1/2 - 25% + √(9) → Δπ"),
      );

      // Chèn tại vị trí con trỏ offset 2 ("3x|") -> "3x^2"
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('math-key-pow2')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('math-key-pow2')));
      await tester.pump();
      expect(controller.text, '3x^2');
      expect(controller.selection.baseOffset, 4);

      // Chèn thêm '%', '/', '√', 'π', 'Δ', '→' rồi xóa 1 ký tự
      for (final String keyId in <String>[
        'percent',
        'frac',
        'sqrt',
        'pi',
        'delta',
        'arrow',
      ]) {
        await tester.ensureVisible(
          find.byKey(ValueKey<String>('math-key-$keyId')),
        );
        await tester.tap(find.byKey(ValueKey<String>('math-key-$keyId')));
        await tester.pump();
      }
      expect(controller.text, '3x^2%/√πΔ→');

      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('math-key-backspace')),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('math-key-backspace')),
      );
      await tester.pump();
      expect(controller.text, '3x^2%/√πΔ');
      expect(tester.takeException(), isNull);
    },
  );
}
