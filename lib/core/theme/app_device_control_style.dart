// 悬浮设备控件的具名视觉规格；Ardot 来源与光学参数限制见组件布局约定。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

/// 全局设备控件的主题契约，不包含业务状态或页面定位策略。
abstract final class AppDeviceControlStyle {
  /// 设计基准逻辑尺寸；所有主状态共用同一外框。
  static const Size baseSize = Size(126, 68);

  /// 图标尺寸。
  static const double iconSize = 32;

  /// 图标与文字的间距。
  static const double iconGap = 6;

  /// 左右留白沿用设计稿的 20 / 14。
  static const EdgeInsets contentPadding = EdgeInsets.fromLTRB(20, 16, 14, 16);

  /// 主状态文字：MiSans 的平台默认字体替代，保留设计行高。
  static const TextStyle title = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 19 / 14,
    letterSpacing: 0,
    color: Colors.white,
    decoration: TextDecoration.none,
  );

  /// 辅助操作提示。
  static const TextStyle subtitle = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.w500,
    height: 11 / 8,
    letterSpacing: 0,
    color: Color(0xFF8F8F8F),
    decoration: TextDecoration.none,
  );

  /// 未连接双行文案。
  static const TextStyle disconnected = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0,
    color: Colors.white,
    decoration: TextDecoration.none,
  );

  /// SVG 外框导出的渐变方向及 20% 透明度。
  static const LinearGradient surface = LinearGradient(
    begin: Alignment(-0.11, -1),
    end: Alignment(0.39, 1.16),
    colors: [Color(0x33454545), Color(0x33D13BD8)],
  );

  /// GLASS 效果无法通过当前 Ardot API 读取；使用明确的工程初始光学值。
  static const LiquidGlassSettings glass = LiquidGlassSettings(
    glassColor: Colors.transparent,
    blur: 5,
    lightIntensity: 0.5,
    saturation: 1,
  );

  /// Running 的暂停动作图标来自 Ardot。
  static const String pauseAsset = 'assets/images/control/pause.svg';

  /// Paused 的播放动作图标来自 Ardot。
  static const String playAsset = 'assets/images/control/play.svg';

  /// 未连接状态图标来自 Ardot。
  static const String disconnectedAsset =
      'assets/images/control/bluetooth_off.svg';

  /// 低电量提示图标来自 Ardot。
  static const String batteryAsset = 'assets/images/control/battery.svg';

  /// 按所有状态的最长文字统一测量，切换状态不改变尺寸；大字体自然增高。
  static Size sizeFor({
    required TextScaler textScaler,
    required double maxWidth,
    String? fontFamily,
  }) {
    double widthOf(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(fontFamily: fontFamily),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    final textWidth = [
      widthOf('Running', title),
      widthOf('Tap to resume', subtitle),
      widthOf('Low battery', subtitle) + 12,
      widthOf('connected', disconnected) - 4,
    ].reduce(math.max);
    final width = math.min(
      math.max(1.0, maxWidth),
      math.max(baseSize.width, textWidth + iconSize + iconGap + 34),
    );
    final availableText = math.max(1.0, width - iconSize - iconGap - 34);
    double heightOf(String text, TextStyle style, {double extraWidth = 0}) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(fontFamily: fontFamily),
        ),
        textDirection: TextDirection.ltr,
        textScaler: textScaler,
      )..layout(maxWidth: availableText + extraWidth);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final textHeight = math.max(
      heightOf('Running', title) + heightOf('Tap to resume', subtitle),
      // 未连接图标与文字间距为 2，比其余状态多出 4px 可用宽度。
      heightOf('Not\nconnected', disconnected, extraWidth: iconGap - 2),
    );
    return Size(width, math.max(baseSize.height, textHeight + 32));
  }
}
