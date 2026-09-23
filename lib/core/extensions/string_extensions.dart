// 字符串基础扩展：统一安全的数值转换、文本解析、颜色解析和资源路径构造。
import 'package:flutter/material.dart';

/// 与业务状态无关的字符串便捷能力。
///
/// 扩展只处理纯字符串转换，不读取环境、不访问网络或存储。资源路径方法要求调用方传入
/// 不含 `assets/` 前缀的后缀名，避免同一资源在不同调用点拼出不一致路径。
extension StringExtensions on String {
  /// 将字符串安全转换为整数，失败或溢出时返回 [fallback]。
  int toIntOr({int fallback = 0}) => int.tryParse(this) ?? fallback;

  /// 将字符串安全转换为浮点数，失败时返回 [fallback]。
  double toDoubleOr({double fallback = 0}) => double.tryParse(this) ?? fallback;

  /// 判断去除首尾空白后的字符串是否为空。
  bool get isBlank => trim().isEmpty;

  /// 判断去除首尾空白后的字符串是否非空。
  bool get isNotBlank => !isBlank;

  /// 将资源名称转换为 `assets/images` 下的 PNG 路径。
  String get assetsPng =>
      'assets/images/${this.endsWith(".png") ? this : "$this.png"}';

  /// 将资源名称转换为 `assets/images` 下的 SVG 路径。
  String get assetsSvg => 'assets/images/$this.svg';

  /// 将资源名称转换为 `assets/lotties` 下的 JSON 路径。
  String get assetsLottie => 'assets/lotties/$this.json';

  /// 将相对资源路径转换为 `assets/images` 下的完整路径。
  String get images => 'assets/images/$this';

  /// 将资源名称转换为 `assets/lotties` 下的 JSON 路径。
  String get lottie =>
      'assets/lotties/${this.endsWith(".json") ? this : "$this.json"}';

  /// 解析 `#RRGGBB`、`#AARRGGBB`、`RRGGBB`、`AARRGGBB` 或 `rgb(r,g,b)`。
  ///
  /// 空字符串或格式非法时返回 [fallback]；该方法不捕获业务层的颜色配置错误，调用方
  /// 仍应决定非法后台配置是展示默认值还是产生可观测错误。
  Color toColor({Color fallback = Colors.transparent}) {
    final normalized = trim().toLowerCase();
    if (normalized.startsWith('rgb(') && normalized.endsWith(')')) {
      final values = normalized
          .substring(4, normalized.length - 1)
          .split(',')
          .map((value) => value.trim())
          .toList(growable: false);
      if (values.length != 3) {
        return fallback;
      }
      final channels = values
          .map((value) => int.tryParse(value))
          .toList(growable: false);
      if (channels.any((value) => value == null || value < 0 || value > 255)) {
        return fallback;
      }
      return Color.fromARGB(255, channels[0]!, channels[1]!, channels[2]!);
    }

    final hex = normalized.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    if (value == null) {
      return fallback;
    }
    return switch (hex.length) {
      6 => Color(0xFF000000 | value),
      8 => Color(value),
      _ => fallback,
    };
  }
}

/// 可空字符串的空值判断扩展。
extension NullableStringExtensions on String? {
  /// 字符串为 `null` 或空串时返回 `true`；纯空白不在此处视为空。
  bool get isNullOrEmpty => this == null || this!.isEmpty;

  /// 字符串非 `null` 且非空串时返回 `true`；纯空白不在此处视为非空。
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
