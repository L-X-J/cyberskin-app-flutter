// 应用圆角 token：提供命名尺寸及常用 Radius、BorderRadius 构造。
import 'package:flutter/material.dart';

/// 应用设计系统的圆角规格。
abstract final class AppRadius {
  /// 2 logical px。
  static const double radiusXxs = 2;

  /// 4 logical px。
  static const double radiusXs = 4;

  /// 8 logical px。
  static const double radiusSm = 8;

  /// 10 logical px。
  static const double radiusMd = 10;

  /// 12 logical px。
  static const double radiusMdLarge = 12;

  /// 14 logical px。
  static const double radiusLg = 14;

  /// 16 logical px。
  static const double radiusLgLarge = 16;

  /// 18 logical px。
  static const double radiusXl = 18;

  /// 20 logical px。
  static const double radiusXlLarge = 20;

  /// 26 logical px。
  static const double radiusXxl = 26;

  /// 32 logical px，卡片圆角。
  static const double radiusCard = 32;

  /// 39 logical px，按钮圆角。
  static const double radiusButton = 39;

  /// 48 logical px，面板圆角。
  static const double radiusPanel = 48;

  /// 100 logical px，胶囊圆角。
  static const double radiusPill = 100;

  /// 最小圆角构造。
  static const Radius xxSmall = Radius.circular(radiusXxs);

  /// 小圆角构造。
  static const Radius small = Radius.circular(radiusSm);

  /// 中圆角构造。
  static const Radius medium = Radius.circular(radiusMd);

  /// 大圆角构造。
  static const Radius large = Radius.circular(radiusLgLarge);

  /// 卡片圆角构造。
  static const BorderRadius card = BorderRadius.all(
    Radius.circular(radiusCard),
  );

  /// 按钮圆角构造。
  static const BorderRadius button = BorderRadius.all(
    Radius.circular(radiusButton),
  );

  /// 面板圆角构造。
  static const BorderRadius panel = BorderRadius.all(
    Radius.circular(radiusPanel),
  );

  /// 胶囊圆角构造。
  static const BorderRadius pill = BorderRadius.all(
    Radius.circular(radiusPill),
  );

  /// 根据统一圆角 token 创建自定义圆角对象。
  static BorderRadius circular(double radius) =>
      BorderRadius.all(Radius.circular(radius));
}
