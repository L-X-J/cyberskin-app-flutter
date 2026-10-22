// 节奏片段时长的循环滚轮；只负责展示与局部交互。
import 'dart:math' as math;

import 'package:cyberskin_app/core/theme/app_rhythm_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 用户确认的展示预设，不作为领域允许值列表。
const rhythmDurationPresets = <int>[
  1,
  3,
  5,
  10,
  30,
  60,
  120,
  180,
  240,
  300,
  360,
  420,
  480,
  540,
  600,
  660,
  720,
  780,
  840,
  900,
  960,
  1020,
  1080,
  1140,
  1200,
];

/// 整分钟用 m，其余保留准确秒数。
String formatRhythmDuration(int seconds) =>
    seconds >= 60 && seconds % 60 == 0 ? '${seconds ~/ 60}m' : '${seconds}s';

/// 固定中心选择窗的水平循环滚轮，外部值变化时同步准确秒数。
final class RhythmDurationWheel extends StatefulWidget {
  /// 当前秒数和局部草稿回调由弹层提供。
  const RhythmDurationWheel({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// 当前草稿秒数。
  final int value;

  /// 用户切换中心项时通知弹层。
  final ValueChanged<int> onChanged;
  @override
  State<RhythmDurationWheel> createState() => _RhythmDurationWheelState();
}

final class _RhythmDurationWheelState extends State<RhythmDurationWheel> {
  late List<int> _values;
  @override
  void initState() {
    super.initState();
    _setValues();
  }

  void _setValues() {
    _values = [...rhythmDurationPresets];
    if (!_values.contains(widget.value)) {
      _values.add(widget.value);
      _values.sort();
    }
  }

  @override
  void didUpdateWidget(covariant RhythmDurationWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 离开自定义项时仍保留该项，避免手势途中列表长度变化。
    if (!_values.contains(widget.value)) _setValues();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scaled = MediaQuery.textScalerOf(context).scale(14);
      final longest = _values
          .map(formatRhythmDuration)
          .map((s) => s.length)
          .reduce(math.max);
      final extent = math.max(64.0, scaled * (longest + 1));
      final fraction = math.min(1.0, extent / constraints.maxWidth);
      final height = math.max(52.0, scaled * 1.5 + 20);
      return SizedBox(
        height: height,
        child: _WheelTrack(
          // 窗口/字体重排重新计算视口，草稿秒数不丢失。
          key: ValueKey((fraction, height, Object.hashAll(_values))),
          values: _values,
          value: widget.value,
          fraction: fraction,
          height: height,
          onChanged: widget.onChanged,
        ),
      );
    },
  );
}

/// 按原 SVG 的坐标绘制底色与内柔光，不依赖不受支持的 SVG filter。
final class _DurationSelectionPainter extends CustomPainter {
  const _DurationSelectionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 46, size.height / 52);
    final capsule = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 46, 52),
      const Radius.circular(23),
    );
    canvas.drawRRect(capsule, Paint()..color = const Color(0xFFCD68BD));
    canvas.clipRRect(capsule);
    // 反向蒙版：内缩 6 后下移 4，模糊其外部并裁切回原胶囊。
    // 对应 SVG 的 1 - blurred(erodedAlpha)，不是投到外部的阴影。
    final inverse = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(const Rect.fromLTWH(-60, -60, 166, 172))
      ..addRRect(capsule.deflate(6).shift(const Offset(0, 4)));
    canvas.drawPath(
      inverse,
      Paint()
        ..color = const Color(0x54FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DurationSelectionPainter oldDelegate) => false;
}

final class _WheelTrack extends StatefulWidget {
  const _WheelTrack({
    super.key,
    required this.values,
    required this.value,
    required this.fraction,
    required this.height,
    required this.onChanged,
  });
  final List<int> values;
  final int value;
  final double fraction;
  final double height;
  final ValueChanged<int> onChanged;
  @override
  State<_WheelTrack> createState() => _WheelTrackState();
}

final class _WheelTrackState extends State<_WheelTrack> {
  late final PageController _controller;
  final _focusNode = FocusNode(debugLabel: 'Rhythm duration');
  late int _page;
  // 每次静止重定位到等价周期，不让有限的正索引形成可达端点。
  int get _anchor => widget.values.length * 10000;
  int _valueAt(int page) => widget.values[page % widget.values.length];
  @override
  void initState() {
    super.initState();
    _page = _anchor + widget.values.indexOf(widget.value);
    _controller = PageController(
      initialPage: _page,
      viewportFraction: widget.fraction,
    );
  }

  @override
  void didUpdateWidget(covariant _WheelTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_valueAt(_page) != widget.value) {
      _page = _anchor + widget.values.indexOf(widget.value);
      _controller.jumpToPage(_page);
    }
  }

  void _move(int delta) => _toPage(_page + delta);
  void _toPage(int page) => _controller.animateToPage(
    page,
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
  );
  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      final target = _anchor + _page % widget.values.length;
      if (_page != target) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_controller.position.isScrollingNotifier.value) {
            _page = target;
            _controller.jumpToPage(target);
          }
        });
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _move(rtl ? -1 : 1);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _move(rtl ? 1 : -1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Semantics(
        label: 'Duration',
        value: '${widget.value} seconds',
        increasedValue: '${_valueAt(_page + 1)} seconds',
        decreasedValue: '${_valueAt(_page - 1)} seconds',
        onIncrease: () => _move(1),
        onDecrease: () => _move(-1),
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppRhythmStyle.panel,
              borderRadius: BorderRadius.circular(widget.height / 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IgnorePointer(
                  child: SizedBox(
                    width: math.max(
                      46,
                      MediaQuery.textScalerOf(context).scale(14) *
                              widget.values
                                  .map(formatRhythmDuration)
                                  .map((s) => s.length)
                                  .reduce(math.max) +
                          4,
                    ),
                    height: widget.height,
                    child: const CustomPaint(
                      painter: _DurationSelectionPainter(),
                    ),
                  ),
                ),
                NotificationListener<ScrollNotification>(
                  onNotification: _onScroll,
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (page) {
                      setState(() => _page = page);
                      final value = _valueAt(page);
                      if (value != widget.value) {
                        // 仅实际切换档位时反馈；外部同步和等价周期回位不震动。
                        HapticFeedback.selectionClick();
                        widget.onChanged(value);
                      }
                    },
                    itemBuilder: (context, index) => AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final position =
                            _controller.hasClients &&
                                _controller.position.hasContentDimensions
                            ? _controller.page ?? _page.toDouble()
                            : _page.toDouble();
                        final distance = (index - position).abs();
                        return Opacity(
                          opacity: (1 - distance * .3).clamp(.22, 1.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, .001)
                              ..rotateY(
                                (rtl ? -1 : 1) *
                                    (index - position).clamp(-2.0, 2.0) *
                                    .18,
                              )
                              ..scaleByDouble(
                                1 - math.min(distance * .08, .18),
                                1.0,
                                1.0,
                                1.0,
                              ),
                            child: child,
                          ),
                        );
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _focusNode.requestFocus();
                          _toPage(index);
                        },
                        child: Center(
                          child: Text(
                            formatRhythmDuration(_valueAt(index)),
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
