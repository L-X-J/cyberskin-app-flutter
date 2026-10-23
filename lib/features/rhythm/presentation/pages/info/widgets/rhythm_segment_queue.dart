// 详情片段叠放卡组；真实推进时预览提升，计时更新不重播动画。
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../../domain/entities/rhythm.dart';
import '../../../../domain/entities/rhythm_program.dart';
import '../../../../domain/services/rhythm_playback.dart';
import '../../../widgets/rhythm_segment_card.dart';

/// 自然高度的当前/下一片段卡组，只为同一运行快照前向推进提示。
final class RhythmSegmentQueue extends StatefulWidget {
  /// 创建卡组，不参与播放会话或设备控制。
  const RhythmSegmentQueue({
    super.key,
    required this.rhythm,
    required this.index,
    required this.remaining,
    required this.phase,
    required this.capabilities,
  });

  /// 同一运行快照引用用于识别真实片段推进。
  final Rhythm rhythm;

  /// 详情短预览独立于完整执行输入，不能回写到 rhythm.segments。
  List<RhythmSegment> get visibleSegments =>
      rhythm.hasCompleteProgram ? rhythm.segments : rhythm.previewSegments;

  /// 片段位置与当前剩余秒数。
  final int index, remaining;

  /// 只有运行确认后的前向推进才提示。
  final RhythmPlaybackPhase phase;

  /// 后台能力用于通道摘要。
  final List<RhythmChannelCapability> capabilities;

  @override
  State<RhythmSegmentQueue> createState() => _RhythmSegmentQueueState();
}

final class _RhythmSegmentQueueState extends State<RhythmSegmentQueue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    value: 1,
  );
  RhythmSegmentQueue? _outgoing;

  @override
  void didUpdateWidget(covariant RhythmSegmentQueue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.rhythm, widget.rhythm) &&
        oldWidget.index == widget.index) {
      return;
    }
    final forward =
        identical(oldWidget.rhythm, widget.rhythm) &&
        widget.index > oldWidget.index &&
        widget.phase == RhythmPlaybackPhase.running;
    if (forward) HapticFeedback.lightImpact();
    // 跳跃推进不伪造不存在的预览；重启、换节奏立即重置视觉。
    if (forward &&
        widget.index == oldWidget.index + 1 &&
        !MediaQuery.disableAnimationsOf(context)) {
      _outgoing = oldWidget;
      _motion.forward(from: 0);
    } else {
      _outgoing = null;
      _motion.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _outgoing = null;
      _motion.value = 1;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Widget _card(RhythmSegmentQueue source, int index, {bool preview = false}) =>
      RhythmSegmentCard(
        key: ValueKey(('segment', source.rhythm, index)),
        segment: source.visibleSegments[index],
        capabilities: source.capabilities,
        remainingSeconds: preview ? null : source.remaining,
        running: true,
        nextIn: !preview && index + 1 < source.visibleSegments.length
            ? source.remaining
            : null,
      );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _motion,
    builder: (context, _) {
      final t = Curves.easeInOutCubic.transform(_motion.value);
      final old = t < 1 ? _outgoing : null;
      final hasNext = widget.index + 1 < widget.visibleSegments.length;
      // 顺序是绘制顺序：预览在底层，当前在中层，退出卡在顶层。
      return _DeckLayout(
        progress: old == null ? 1 : t,
        transitioning: old != null,
        hasNext: hasNext,
        children: [
          if (hasNext)
            Opacity(
              opacity: .4 * (old == null ? 1 : t),
              child: _card(widget, widget.index + 1, preview: true),
            ),
          Opacity(
            opacity: old == null ? 1 : lerpDouble(.4, 1, t)!,
            child: _card(widget, widget.index),
          ),
          if (old != null)
            IgnorePointer(
              child: ExcludeSemantics(
                child: Opacity(opacity: 1 - t, child: _card(old, old.index)),
              ),
            ),
        ],
      );
    },
  );
}

/// 布局时读取各卡真实高度，避免固定高度和整列切换导致跳动或裁切。
final class _DeckLayout extends MultiChildRenderObjectWidget {
  const _DeckLayout({
    required this.progress,
    required this.transitioning,
    required this.hasNext,
    required super.children,
  });
  final double progress;
  final bool transitioning, hasNext;

  @override
  _RenderDeck createRenderObject(BuildContext context) =>
      _RenderDeck(progress, transitioning, hasNext);

  @override
  void updateRenderObject(BuildContext context, _RenderDeck renderObject) {
    renderObject
      ..progress = progress
      ..transitioning = transitioning
      ..hasNext = hasNext
      ..markNeedsLayout();
  }
}

final class _DeckParentData extends ContainerBoxParentData<RenderBox> {}

final class _RenderDeck extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _DeckParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _DeckParentData> {
  _RenderDeck(this.progress, this.transitioning, this.hasNext);
  double progress;
  bool transitioning, hasNext;
  static const double _inset = 12, _overlap = 32;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _DeckParentData) {
      child.parentData = _DeckParentData();
    }
  }

  @override
  void performLayout() {
    final children = getChildrenAsList();
    final preview = hasNext ? children.first : null;
    final current = children[hasNext ? 1 : 0];
    final outgoing = transitioning ? children.last : null;
    final width = constraints.maxWidth;
    void measure(RenderBox? card, double inset) {
      card?.layout(
        BoxConstraints.tightFor(width: (width - 2 * inset).clamp(0, width)),
        parentUsesSize: true,
      );
    }

    measure(preview, _inset);
    measure(current, transitioning ? _inset * (1 - progress) : 0);
    measure(outgoing, 0);
    final currentHeight = current.size.height;
    final oldHeight = outgoing?.size.height ?? 0;
    final startY = (oldHeight - _overlap).clamp(0.0, double.infinity);
    final y = transitioning ? startY * (1 - progress) : 0.0;
    void position(RenderBox? card, double x, double y) {
      if (card != null) {
        (card.parentData! as _DeckParentData).offset = Offset(x, y);
      }
    }

    position(current, transitioning ? _inset * (1 - progress) : 0, y);
    position(outgoing, 0, -oldHeight * .22 * progress);
    position(
      preview,
      _inset,
      y + currentHeight - _overlap + (transitioning ? 24 * (1 - progress) : 0),
    );
    final endHeight =
        currentHeight +
        (preview == null
            ? 0
            : (preview.size.height - _overlap).clamp(0.0, double.infinity));
    final startHeight = startY + currentHeight;
    size = constraints.constrain(
      Size(
        width,
        transitioning
            ? lerpDouble(startHeight, endHeight, progress)!
            : endHeight,
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
