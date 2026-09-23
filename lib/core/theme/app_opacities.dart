// 应用透明度 token：仅提供可复用数值，具名语义色仍由 AppColors 持有。
/// 可复用的透明度比例，不绑定任何具体颜色或组件。
abstract final class AppOpacities {
  /// 轻微强调透明度。
  static const double subtle = 0.10;

  /// 浅透明度。
  static const double light = 0.12;

  /// 弱透明度。
  static const double weak = 0.20;

  /// 中等透明度。
  static const double medium = 0.30;

  /// 遮罩透明度。
  static const double overlay = 0.40;

  /// 半透明。
  static const double half = 0.50;

  /// 强透明度。
  static const double strong = 0.60;

  /// 强调透明度。
  static const double emphasis = 0.70;

  /// 玻璃表面透明度。
  static const double glassSurface = 0.80;

  /// 高亮透明度。
  static const double highlight = 0.90;
}
