import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindclock_app/ui/core/theme/mindclock_theme.dart';
import 'package:mindclock_app/ui/core/widgets/mam_pet_view.dart';
import 'package:mindclock_app/ui/core/widgets/mindclock_icon.dart';
import 'package:mindclock_app/ui/features/study_focus/views/mindclock_ai_avatar.dart';

Future<void> _render(WidgetTester tester, Widget child,
    {bool reduce = false}) async {
  await tester.pumpWidget(MaterialApp(
      theme: MindClockTheme.buildThemeData(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: child!),
      home: Scaffold(body: child)));
  await tester.pump();
}

class _MissingBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      throw StateError('Asset unavailable in test');
}

void main() {
  testWidgets('asset lỗi vẫn có nhãn AI và icon dự phòng', (tester) async {
    await _render(
        tester,
        DefaultAssetBundle(
            bundle: _MissingBundle(),
            child: const MindClockAiAnimatedAvatar(animate: false)));
    await tester.pumpAndSettle();
    expect(find.byType(MindClockIcon), findsOneWidget);
    expect(find.text('MindClock AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('nhịp miệng có frame khác nhau và dừng khi audio kết thúc',
      (tester) async {
    await _render(tester, const MindClockAiAnimatedAvatar(isSpeaking: true));
    expect(
        find.byKey(const ValueKey('ai-avatar-speaking-small')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 140));
    expect(find.byKey(const ValueKey('ai-avatar-speaking-medium')),
        findsOneWidget);
    await _render(tester, const MindClockAiAnimatedAvatar(isSpeaking: false));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('ai-avatar-neutral')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('avatar thật chớp mắt bằng frame khác, không chỉ rung ảnh',
      (tester) async {
    await _render(tester, const MindClockAiAnimatedAvatar());
    expect(find.byKey(const ValueKey('ai-avatar-neutral')), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.byKey(const ValueKey('ai-avatar-blink')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.byKey(const ValueKey('ai-avatar-neutral')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('miệng đổi theo audioLevel chỉ khi isSpeaking, ngừng về neutral',
      (tester) async {
    await _render(tester,
        const MindClockAiAnimatedAvatar(isSpeaking: true, audioLevel: .2));
    expect(
        find.byKey(const ValueKey('ai-avatar-speaking-small')), findsOneWidget);
    await _render(tester,
        const MindClockAiAnimatedAvatar(isSpeaking: true, audioLevel: .9));
    expect(
        find.byKey(const ValueKey('ai-avatar-speaking-wide')), findsOneWidget);
    await _render(tester,
        const MindClockAiAnimatedAvatar(isSpeaking: false, audioLevel: .9));
    expect(find.byKey(const ValueKey('ai-avatar-neutral')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Reduce Motion và animate false không chạy blink/miệng',
      (tester) async {
    await _render(tester, const MindClockAiAnimatedAvatar(isSpeaking: true),
        reduce: true);
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const ValueKey('ai-avatar-neutral')), findsOneWidget);
    await _render(tester,
        const MindClockAiAnimatedAvatar(isSpeaking: true, animate: false));
    await tester.pump(const Duration(seconds: 5));
    expect(find.byKey(const ValueKey('ai-avatar-neutral')), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('suy nghĩ/nghe/khích lệ là asset riêng, có nhãn AI',
      (tester) async {
    await _render(tester,
        const MindClockAiAnimatedAvatar(isThinking: true, animate: false));
    expect(find.byKey(const ValueKey('ai-avatar-thinking')), findsOneWidget);
    await _render(
        tester,
        const MindClockAiAnimatedAvatar(
            mood: AiCompanionMood.listening, animate: false));
    expect(find.byKey(const ValueKey('ai-avatar-listening')), findsOneWidget);
    await _render(
        tester,
        const MindClockAiAnimatedAvatar(
            mood: AiCompanionMood.encouraging, animate: false));
    expect(find.byKey(const ValueKey('ai-avatar-encouraging')), findsOneWidget);
    expect(find.text('MindClock AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pet chỉ chọn hình theo props; stage/reaction có đường dẫn riêng',
      (tester) async {
    await _render(tester, const MamPetView(stage: 4));
    var image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName,
        'assets/companions/pet-mam/stage-4.webp');
    await _render(tester, const MamPetView(reaction: MamPetReaction.sleep));
    image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName,
        'assets/companions/pet-mam/sleep.webp');
    expect(tester.takeException(), isNull);
  });
}
