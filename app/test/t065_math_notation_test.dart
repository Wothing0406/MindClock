import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/core/widgets/math_formula_text.dart';
import 'package:mindclock_app/ui/core/widgets/math_input_keypad.dart';

void main() {
  test('TC01: giữ nhóm phân số, đơn vị và phần trăm', () {
    expect(
        MathFormulaText.normalizeReadableSymbols(
            r'25\% ; \frac{a+b}{c-d} ; 9.8\,\mathrm{m}/\mathrm{s}^2 ; H_2O \leq 3'),
        '25% ; (a+b)/(c-d) ; 9.8 m/s^2 ; H_2O ≤ 3');
  });

  testWidgets('TC01: chỉ số không nuốt ký tự đơn vị bên cạnh', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: MathFormulaText('H_2O, 10^-6m, x^{n+1}'))));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('-6'), findsOneWidget);
    expect(find.text('n+1'), findsOneWidget);
    expect(find.text('2O'), findsNothing);
    expect(find.text('-6m'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TC02: thay vùng chọn đúng controller trình bày', (tester) async {
    final answer = TextEditingController(text: '12');
    final reasoning = TextEditingController(text: 'a = xx');
    addTearDown(answer.dispose);
    addTearDown(reasoning.dispose);
    reasoning.selection = const TextSelection(baseOffset: 4, extentOffset: 6);
    await tester.pumpWidget(MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      home: Scaffold(
          body: SingleChildScrollView(
              child: Column(children: [
        TextField(controller: answer),
        TextField(controller: reasoning),
        MathInputKeypad(controller: reasoning),
      ]))),
    ));
    final key = find.byKey(const ValueKey<String>('math-key-percent'));
    await tester.ensureVisible(key);
    await tester.tap(key);
    expect(reasoning.text, 'a = %');
    expect(reasoning.selection.baseOffset, 5);
    expect(answer.text, '12');
  });
}
