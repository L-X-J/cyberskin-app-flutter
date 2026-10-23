// 视频来源导航与播放控制的视觉规格；导航对应 Ardot Video Pages 567:3–567:7。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import 'app_colors.dart';
import 'app_gradients.dart';

/// 视频来源导航的玻璃、文字样式，以及 Official / Local 共用的播放进度样式。
abstract final class AppVideoStyle {
  /// 基准轨道为 356 × 52；宽屏居中，窄屏按父约束收缩。
  static const double tabBarMaxWidth = 356;

  /// 默认文字缩放下的轨道高度。
  static const double tabBarHeight = 52;

  /// 轨道外轮廓圆角。
  static const double tabBarRadius = 30;

  /// 基准状态栏占 62px，安全区下方留 18px，对应画板 y=80。
  static const EdgeInsets tabBarMargin = EdgeInsets.fromLTRB(23, 18, 23, 0);

  /// 基准内框宽 348px，三枚 112px 胶囊及两个 6px 间距。
  static const EdgeInsets tabIndicatorPadding = EdgeInsets.fromLTRB(5, 4, 3, 4);

  /// 保留 SVG 的 112px 基准宽度，不把指示器撑满三等分轨道。
  static const double tabGap = 6;

  /// 等宽标签内侧留白，给窄屏和大字体保留更多文字空间。
  static const EdgeInsets tabLabelPadding = EdgeInsets.symmetric(horizontal: 8);

  /// 轨道使用设计稿白色 20% 填充，未选中文字为 #CECECE。
  static const Color tabBarBackground = AppColors.white20;

  /// 未选中来源文字。
  static const Color tabUnselectedLabelColor = AppColors.textTertiary;

  /// MiSans Regular 的默认平台字体替代，保留 16px 字号与 21px 行高。
  static const TextStyle tabLabel = TextStyle(
    fontSize: 16,
    height: 21 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: AppColors.textOnAccent,
    decoration: TextDecoration.none,
  );

  /// 按用户 SVG 的 userSpaceOnUse 坐标归一化，保留方向与 20% 填充。
  ///
  /// SVG 基准 112×44，起点 (42.1991, 0)，终点 (85.497, 38.9647)。
  static final LinearGradient tabIndicatorGradient = LinearGradient(
    begin: const Alignment(42.1991 / 112 * 2 - 1, -1),
    end: const Alignment(85.497 / 112 * 2 - 1, 38.9647 / 44 * 2 - 1),
    colors: AppGradients.standard.purplePinkEmphasis.colors
        .map((color) => color.withValues(alpha: .2))
        .toList(growable: false),
  );

  /// Ardot 玻璃轮廓的工程映射：左上细高光，右下减弱，避免整圈白描边。
  static const LinearGradient tabIndicatorRim = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xE6FFFFFF),
      Color(0x40FFFFFF),
      Color(0x08FFFFFF),
      Color(0x4DFFFFFF),
    ],
    stops: [0, .3, .65, 1],
  );

  /// 高光全部位于胶囊内部，几何尺寸不因描边变化。
  static const double tabIndicatorRimWidth = .75;

  /// 轨道为背景模糊，不叠加额外高光或饱和度变化。
  static const LiquidGlassSettings tabBarGlass = LiquidGlassSettings(
    glassColor: Colors.transparent,
    blur: 10,
    lightIntensity: 0,
    saturation: 1,
  );

  /// 只提供透射与折射；高光由独立渐变轮廓绘制，避免库内高光重复叠加。
  static const LiquidGlassSettings tabIndicatorGlass = LiquidGlassSettings(
    glassColor: Colors.transparent,
    thickness: 14,
    blur: 0,
    refractiveIndex: 1.15,
    chromaticAberration: .58,
    lightIntensity: 0,
    saturation: 1,
  );

  /// 仅放大触控区域，细线仍贴住视频底边。
  static const double playbackTouchHeight = 48;

  /// 拖动时间提示贴近画面底边，保留与进度线的可读间距。
  static const double playbackPreviewBottomGap = 12;

  /// Official / Local 进度只显示横线，不显示拖动圆点或 Material 气泡。
  static final SliderThemeData playbackSliderTheme = SliderThemeData(
    padding: EdgeInsets.zero,
    trackHeight: 3,
    trackShape: const _BottomAlignedSliderTrackShape(),
    thumbShape: SliderComponentShape.noThumb,
    overlayShape: SliderComponentShape.noOverlay,
    activeTrackColor: Colors.white,
    inactiveTrackColor: Colors.white30,
    showValueIndicator: ShowValueIndicator.never,
  );

  /// 文字放大时增加轨道高度，保持行高和上下留白，不缩小字体。
  static double tabBarHeightFor(TextScaler textScaler) =>
      math.max(tabBarHeight, textScaler.scale(16) * (21 / 16) + 24);
}

/// 轨道贯穿视频宽度并贴底，向上保留完整触控高度而不增加视觉底部留白。
final class _BottomAlignedSliderTrackShape extends RectangularSliderTrackShape {
  const _BottomAlignedSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final height = sliderTheme.trackHeight!;
    return Rect.fromLTWH(
      offset.dx,
      offset.dy + parentBox.size.height - height,
      parentBox.size.width,
      height,
    );
  }
}
