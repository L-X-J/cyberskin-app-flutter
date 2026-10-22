// 节奏列表折叠标题；滚动占位、全屏磨砂和安全区内交互分层绘制。
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_blur.dart';
import '../../../../../../core/theme/app_rhythm_style.dart';
import '../../../../../../core/widgets/app_liquid_glass_button.dart';
import '../../../widgets/rhythm_title.dart';

/// 只依赖滚动几何和展示文字，不持有设备或请求生命周期。
final class RhythmHomeHeader extends SliverPersistentHeaderDelegate {
  /// 创建可折叠标题；宽度为已经扣除页面左右边距的局部宽度。
  RhythmHomeHeader({
    required this.width,
    required this.subtitle,
    required this.textScaler,
    required this.direction,
    required this.onBack,
    required this.disableAnimations,
  });

  /// 当前局部宽度、系统文字缩放与排版方向。
  final double width;
  final TextScaler textScaler;
  final TextDirection direction;

  /// 设备说明仅用于展示。
  final String subtitle;
  final VoidCallback onBack;

  /// 减少动态效果时不插值位置，滚动越过阈值直接切换。
  final bool disableAnimations;

  static const titleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
  );
  static const subtitleStyle = TextStyle(
    fontSize: 16,
    color: AppRhythmStyle.secondary,
  );

  double _height(
    String text,
    TextStyle style,
    double maxWidth, {
    int? maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textScaler: textScaler,
      textDirection: direction,
      maxLines: maxLines,
    )..layout(maxWidth: math.max(1, maxWidth));
    final height = painter.height;
    painter.dispose();
    return height;
  }

  @override
  double get minExtent => math.max(
    44,
    _height('Custom rhythm', titleStyle.copyWith(fontSize: 18), width - 104) +
        16,
  );

  @override
  double get maxExtent =>
      minExtent +
      20 +
      _height('Custom rhythm', titleStyle, width) +
      4 +
      _height(subtitle, subtitleStyle, width, maxLines: 2) +
      20;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => const SizedBox.expand();

  /// 前景覆盖在全宽磨砂之上，滚动仅重建这一局部层，保持按钮和 Hero 清晰。
  Widget buildOverlay(BuildContext context, double scrollOffset) {
    final shrinkOffset = math.max(0.0, scrollOffset);
    final raw = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final extent = math.max(minExtent, maxExtent - shrinkOffset);
    final padding = MediaQuery.paddingOf(context);
    return Stack(
      children: [
        if (raw > 0)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // 覆盖状态栏至工具栏底部，并在按钮下保留呼吸空间。
            height: padding.top + minExtent + 16,
            child: IgnorePointer(
              child: ClipRect(
                key: const ValueKey('rhythm-header-frost'),
                child: BackdropFilter(
                  filter: AppBlur.backgroundFilter(24 * raw),
                  child: ColoredBox(
                    color: AppRhythmStyle.background.withValues(
                      alpha: .2 * raw,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          top: padding.top,
          left: padding.left,
          right: padding.right,
          height: extent,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: AppRhythmStyle.maxWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppRhythmStyle.pagePadding,
                ),
                child: ClipRect(child: _buildContent(raw)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(double raw) {
    final t = disableAnimations ? (raw > 0 ? 1.0 : 0.0) : raw;
    final style = titleStyle.copyWith(fontSize: lerpDouble(28, 18, t));
    final titleWidth = width - 104 * t;
    final height = _height('Custom rhythm', style, titleWidth);
    final top = lerpDouble(minExtent + 20, (minExtent - height) / 2, t)!;
    final subtitleOpacity = (1 - raw * 2.2).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: minExtent + 20 + _height('Custom rhythm', titleStyle, width) + 4,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: ExcludeSemantics(
              excluding: subtitleOpacity == 0,
              child: Opacity(
                key: const ValueKey('rhythm-subtitle-opacity'),
                opacity: disableAnimations
                    ? (raw == 0 ? 1 : 0)
                    : subtitleOpacity,
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: subtitleStyle,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: top,
          left: 52 * t,
          right: 52 * t,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment(-1 + t, 0),
              child: RhythmTitle(style: style),
            ),
          ),
        ),
        Positioned(
          top: (minExtent - 44) / 2,
          left: 0,
          child: AppLiquidGlassButton(
            label: 'Back',
            icon: Icons.chevron_left,
            width: 44,
            height: 44,
            iconSize: 30,
            contentPadding: EdgeInsets.zero,
            variant: AppLiquidGlassButtonVariant.translucent,
            onPressed: onBack,
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant RhythmHomeHeader oldDelegate) =>
      width != oldDelegate.width ||
      subtitle != oldDelegate.subtitle ||
      textScaler != oldDelegate.textScaler ||
      direction != oldDelegate.direction ||
      disableAnimations != oldDelegate.disableAnimations;
}
