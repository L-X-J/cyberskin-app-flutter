import 'package:cyberskin_app/core/theme/app_colors.dart';
import 'package:cyberskin_app/core/widgets/app_lottie_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

void main() {
  testWidgets('fills its bounded parent and owns the looping controller', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 320,
            height: 480,
            child: AppLottieBackground(playbackSpeed: 2),
          ),
        ),
      ),
    );
    await tester.pump();

    final background = find.byType(AppLottieBackground);
    final lottie = tester.widget<LottieBuilder>(find.byType(LottieBuilder));
    final coloredBox = tester.widget<ColoredBox>(
      find.descendant(of: background, matching: find.byType(ColoredBox)),
    );

    expect(tester.getSize(background), const Size(320, 480));
    expect(coloredBox.color, AppColors.scaffold);
    expect(lottie.controller, isNotNull);
    expect(lottie.controller!.isAnimating, isTrue);
    expect(lottie.fit, BoxFit.cover);
    expect(lottie.alignment, Alignment.center);
  });

  testWidgets('updates the duration when playback speed changes', (
    tester,
  ) async {
    Widget buildBackground(double playbackSpeed) {
      return MaterialApp(
        home: SizedBox(
          width: 320,
          height: 480,
          child: AppLottieBackground(playbackSpeed: playbackSpeed),
        ),
      );
    }

    await tester.pumpWidget(buildBackground(2));
    await tester.pump();
    await tester.pump();

    final controller =
        tester.widget<LottieBuilder>(find.byType(LottieBuilder)).controller!
            as AnimationController;
    final doubleSpeedDuration = controller.duration;
    expect(doubleSpeedDuration, isNotNull);

    await tester.pumpWidget(buildBackground(4));
    await tester.pump();

    expect(controller.duration, isNotNull);
    expect(
      controller.duration!.inMicroseconds * 2,
      closeTo(doubleSpeedDuration!.inMicroseconds, 1),
    );
  });
}
