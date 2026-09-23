// 应用模糊 token：并列保留 Figma 设计 blur 与 Flutter ImageFilter sigma。
import 'dart:ui';

/// Figma 报告中的模糊参数及 Flutter 实际滤镜的工程默认值。
abstract final class AppBlur {
  /// Background Blur：普通玻璃层设计参数。
  static const double glass = 10;

  /// Background Blur：强玻璃层设计参数。
  static const double glassStrong = 20;

  /// Background Blur：遮罩层设计参数。
  static const double overlay = 23;

  /// Layer Blur：小辉光设计参数。
  static const double glowSmall = 14;

  /// Layer Blur：中辉光设计范围下限。
  static const double glowMediumMin = 36;

  /// Layer Blur：中辉光设计范围上限。
  static const double glowMediumMax = 43;

  /// Layer Blur：大辉光设计参数。
  static const double glowLarge = 110;

  /// Ambient Glow：第一组背景氛围光设计参数。
  static const double ambientOne = 117;

  /// Ambient Glow：第二组背景氛围光设计参数。
  static const double ambientTwo = 140;

  /// Ambient Glow：第三组背景氛围光设计参数。
  static const double ambientThree = 160;

  /// Flutter sigma 的统一工程映射系数；1:1 映射尚未经截图校准。
  static const double flutterSigmaScale = 1;

  /// 创建背景模糊滤镜；当前按工程默认的 1:1 sigma 映射。
  static ImageFilter backgroundFilter(double designBlur) => ImageFilter.blur(
    sigmaX: designBlur * flutterSigmaScale,
    sigmaY: designBlur * flutterSigmaScale,
  );

  /// 创建图层辉光滤镜；当前按工程默认的 1:1 sigma 映射。
  static ImageFilter layerFilter(double designBlur) => ImageFilter.blur(
    sigmaX: designBlur * flutterSigmaScale,
    sigmaY: designBlur * flutterSigmaScale,
  );

  /// 创建背景氛围光滤镜；当前按工程默认的 1:1 sigma 映射。
  static ImageFilter ambientFilter(double designBlur) => ImageFilter.blur(
    sigmaX: designBlur * flutterSigmaScale,
    sigmaY: designBlur * flutterSigmaScale,
  );
}
