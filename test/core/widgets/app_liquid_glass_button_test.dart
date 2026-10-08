import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final variant in AppLiquidGlassButtonVariant.values) {
    testWidgets(
      '$variant supports touch and keyboard and blocks loading activation',
      (tester) async {
        var activated = 0;
        Future<void> render({bool loading = false}) => tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 353,
                child: AppLiquidGlassButton(
                  label: 'Continue',
                  variant: variant,
                  isLoading: loading,
                  onPressed: () => activated++,
                ),
              ),
            ),
          ),
        );
        await render();
        final button = tester.widget<LGButton>(find.byType(LGButton));
        expect(button.useOwnLayer, isTrue);
        expect(button.quality, LGQuality.standard);
        await tester.tap(find.byType(LGButton));
        expect(activated, 1);
        Focus.of(tester.element(find.byType(LGButton))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(activated, 2);
        await render(loading: true);
        await tester.tap(find.byType(LGButton));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(activated, 2);
        expect(
          tester.getSize(find.byType(AppLiquidGlassButton)),
          const Size(353, 58),
        );
      },
    );
  }
}
