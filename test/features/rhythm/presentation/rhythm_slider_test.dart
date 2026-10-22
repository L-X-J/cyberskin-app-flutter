// 滑杆局部回归；截图是审阅产物，不作为未经确认的 Golden 基线。
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/theme/app_rhythm_style.dart';
import 'package:cyberskin_app/features/rhythm/presentation/pages/edit/widgets/rhythm_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:flutter_test/flutter_test.dart';

const _captureKey = ValueKey('slider-capture');
const _active = Color(0xFF841184);

Future<void> _pumpSlider(
  WidgetTester tester, {
  double initialValue = 50,
  double min = 0,
  double max = 100,
  int? divisions = 100,
  double textScale = 1,
  bool enabled = true,
  bool showLabel = true,
  TextDirection direction = TextDirection.ltr,
  ValueChanged<double>? onChanged,
  ValueChanged<double>? onStart,
  ValueChanged<double>? onEnd,
}) async {
  var value = initialValue;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: direction,
          child: RepaintBoundary(
            key: _captureKey,
            child: Scaffold(
              backgroundColor: AppRhythmStyle.panel,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: StatefulBuilder(
                    builder: (context, setState) => RhythmSlider(
                      value: value,
                      min: min,
                      max: max,
                      divisions: divisions,
                      activeColor: _active,
                      inactiveColor: AppRhythmStyle.glass,
                      rightLabel: showLabel ? '${value.round()}%' : null,
                      onChanged: enabled
                          ? (next) {
                              setState(() => value = next);
                              onChanged?.call(next);
                            }
                          : null,
                      onChangeStart: onStart,
                      onChangeEnd: onEnd,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SliderThemeData _theme(WidgetTester tester) => tester
    .widget<SliderTheme>(
      find
          .ancestor(of: find.byType(Slider), matching: find.byType(SliderTheme))
          .first,
    )
    .data;

// 原生 Slider 的交互行程，不是铺满组件宽度的视觉轨道。
Rect _track(WidgetTester tester) {
  final box = tester.renderObject<RenderBox>(find.byType(Slider));
  final theme = _theme(tester);
  return theme.trackShape!.getPreferredRect(
    parentBox: box,
    offset: box.localToGlobal(Offset.zero),
    sliderTheme: theme,
    isEnabled: true,
    isDiscrete: true,
  );
}

// getRect 不保证包含缩放；逐角转换才能验证实际绘制范围。
void _expectGlassWithinVisualTrack(
  WidgetTester tester, {
  bool atEndpoint = false,
}) {
  final visual = tester.getRect(find.byType(RhythmSlider));
  final glass = tester.renderObject<RenderBox>(find.byType(LiquidGlass));
  for (final corner in [
    Offset.zero,
    Offset(glass.size.width, 0),
    Offset(0, glass.size.height),
    Offset(glass.size.width, glass.size.height),
  ]) {
    final painted = glass.localToGlobal(corner);
    expect(painted.dx, greaterThanOrEqualTo(visual.left - 4.01));
    expect(painted.dx, lessThanOrEqualTo(visual.right + 4.01));
    expect(painted.dy, greaterThanOrEqualTo(visual.top - 0.01));
    expect(painted.dy, lessThanOrEqualTo(visual.bottom + 0.01));
  }
  final slider = tester.widget<Slider>(find.byType(Slider));
  final normalized = (slider.value - slider.min) / (slider.max - slider.min);
  final rtl =
      Directionality.of(tester.element(find.byType(Slider))) ==
      TextDirection.rtl;
  final fraction = rtl ? 1 - normalized : normalized;
  final track = _track(tester);
  final center = glass.localToGlobal(glass.size.center(Offset.zero));
  expect(center.dx, closeTo(track.left + track.width * fraction, 0.01));
  if (atEndpoint) {
    final edge = glass.localToGlobal(
      Offset(fraction == 0 ? 0 : glass.size.width, 0),
    );
    expect(
      edge.dx,
      closeTo(fraction == 0 ? visual.left - 4 : visual.right + 4, 0.01),
    );
  }
}

double _glassScale(WidgetTester tester) {
  final glass = tester.renderObject<RenderBox>(find.byType(LiquidGlass));
  return (glass.localToGlobal(Offset(glass.size.width, 0)).dx -
          glass.localToGlobal(Offset.zero).dx) /
      glass.size.width;
}

void _expectClearGlass(WidgetTester tester) {
  final glass = tester.widget<LiquidGlass>(find.byType(LiquidGlass));
  expect(glass.ownLayerConfig!.$1.glassColor.a, 0);
  expect(glass.child, isA<SizedBox>());
  expect(_theme(tester).thumbShape, isNot(isA<RoundSliderThumbShape>()));
}

Future<void> _capture(WidgetTester tester, String state) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_captureKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('build/ui/rhythm/slider_${state}_402x874_text1.0.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('min/mid/max share track geometry and keep transparent glass', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final value in [0.0, 50.0, 100.0]) {
      await _pumpSlider(tester, initialValue: value);
      _expectClearGlass(tester);
      final track = _track(tester);
      final visual = tester.getRect(find.byType(RhythmSlider));
      _expectGlassWithinVisualTrack(tester, atEndpoint: value != 50);
      expect(track.left - visual.left, closeTo(18 * 2.6 / 2 - 4, 0.01));
      expect(
        tester.getCenter(find.byType(LiquidGlass)).dx,
        closeTo(track.left + track.width * value / 100, 0.01),
      );
      expect(_theme(tester).activeTrackColor, _active);
      expect(_theme(tester).inactiveTrackColor, AppRhythmStyle.glass);
      expect(_theme(tester).inactiveTrackColor, isNot(_active));
      expect(
        tester.getRect(find.text('${value.round()}%')).right,
        closeTo(visual.right - 4, 0.01),
      );
      await _capture(tester, 'rest_${value.round()}');
      expect(tester.takeException(), isNull);
    }
  });

  for (final width in [402.0, 160.0, 100.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'painted glass overhang is 4px at rest and throughout endpoint animations $width $direction',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 874));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          for (final endpoint in [0.0, 100.0]) {
            await _pumpSlider(
              tester,
              initialValue: endpoint,
              direction: direction,
            );
            _expectGlassWithinVisualTrack(tester, atEndpoint: true);
            final visual = tester.getRect(find.byType(RhythmSlider));
            expect(
              tester.getRect(find.text('${endpoint.round()}%')).right,
              closeTo(visual.right - 4, 0.01),
            );
          }
          // 从中点拖到两端，保持按下以检查完整 1.15 倍的绘制边界。
          await _pumpSlider(tester, direction: direction);
          final gesture = await tester.startGesture(
            tester.getCenter(find.byType(LiquidGlass)),
          );
          final visual = tester.getRect(find.byType(RhythmSlider));
          for (final endpoint in [0.0, 100.0]) {
            final toRight =
                (endpoint == 100) == (direction == TextDirection.ltr);
            await gesture.moveTo(
              Offset(toRight ? visual.right : visual.left, visual.center.dy),
            );
            await tester.pump();
            for (var frame = 0; frame < 12; frame++) {
              await tester.pump(const Duration(milliseconds: 1));
              _expectGlassWithinVisualTrack(tester, atEndpoint: true);
            }
            expect(tester.widget<Slider>(find.byType(Slider)).value, endpoint);
            expect(_glassScale(tester), closeTo(1.15, 0.001));
            _expectClearGlass(tester);
            _expectGlassWithinVisualTrack(tester);
            if (width == 402 && direction == TextDirection.ltr) {
              await _capture(tester, 'drag_${endpoint.round()}');
            }
          }
          await gesture.up();
          await tester.pump();
          for (var frame = 0; frame < 12; frame++) {
            await tester.pump(const Duration(milliseconds: 1));
            _expectGlassWithinVisualTrack(tester, atEndpoint: true);
          }
          await tester.pumpAndSettle();
          expect(_glassScale(tester), closeTo(1, 0.001));
          _expectGlassWithinVisualTrack(tester, atEndpoint: true);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('drag updates step and callbacks while glass stays transparent', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final values = <double>[];
    final starts = <double>[];
    final ends = <double>[];
    await _pumpSlider(
      tester,
      onChanged: values.add,
      onStart: starts.add,
      onEnd: ends.add,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(LiquidGlass)),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    _expectClearGlass(tester);
    expect(_glassScale(tester), closeTo(1.15, 0.001));
    expect(values, isNotEmpty);
    await _capture(tester, 'drag_partial');
    await gesture.up();
    await tester.pumpAndSettle();
    _expectClearGlass(tester);
    expect(starts, hasLength(1));
    expect(ends, hasLength(1));
    expect(ends.single, values.last);
    expect(_glassScale(tester), closeTo(1, 0.001));
  });

  testWidgets(
    'label overlays without blocking taps and honors nonzero min divisions',
    (tester) async {
      final values = <double>[];
      await _pumpSlider(
        tester,
        initialValue: 60,
        min: 10,
        max: 110,
        divisions: 4,
        onChanged: values.add,
      );
      final track = _track(tester);
      await tester.tapAt(
        Offset(track.left + track.width * 0.74, track.center.dy),
      );
      await tester.pumpAndSettle();
      expect(values.last, 85);
      await tester.tapAt(Offset(track.right - 4, track.center.dy));
      await tester.pumpAndSettle();
      expect(values.last, 110);
      expect(find.text('110%'), findsOneWidget);
    },
  );

  testWidgets('keyboard and semantics work; disabled slider ignores input', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final values = <double>[];
    await _pumpSlider(tester, divisions: 4, onChanged: values.add);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(values.last, 75);
    final root = tester.getSemantics(find.byType(Slider));
    expect(root.toStringDeep(), contains('75%'));
    expect(root.toStringDeep(), contains('increase'));
    semantics.dispose();
    await _pumpSlider(tester, enabled: false, onChanged: values.add);
    final count = values.length;
    await tester.tapAt(_track(tester).centerRight);
    await tester.pumpAndSettle();
    expect(values, hasLength(count));
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
  });

  testWidgets(
    'narrow doubled text and RTL keep label within track; null hides label',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpSlider(
        tester,
        initialValue: 25,
        textScale: 2,
        direction: TextDirection.rtl,
      );
      final track = _track(tester);
      expect(
        tester.getCenter(find.byType(LiquidGlass)).dx,
        closeTo(track.left + track.width * 0.75, 0.01),
      );
      expect(
        tester.getRect(find.text('25%')).right,
        closeTo(tester.getRect(find.byType(RhythmSlider)).right - 4, 0.01),
      );
      _expectGlassWithinVisualTrack(tester);
      expect(
        tester.getSize(find.byType(RhythmSlider)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        MediaQuery.textScalerOf(tester.element(find.byType(RhythmSlider)))
            .scale(12),
        24,
      );
      expect(tester.takeException(), isNull);
      await _pumpSlider(tester, showLabel: false);
      expect(find.text('50%'), findsNothing);
    },
  );
}
