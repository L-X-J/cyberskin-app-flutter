// 日志运行配置：集中解析构建参数并控制接口日志与控制台输出。
import 'package:flutter/foundation.dart';

/// 应用日志的不可变运行配置。
final class AppLogConfiguration {
  /// 创建日志配置。
  const AppLogConfiguration({
    required this.apiLoggingEnabled,
    required this.consoleOutputEnabled,
  });

  /// 从当前 Flutter 构建模式和 `dart-define` 解析日志配置。
  ///
  /// Debug 构建始终打开 API 日志；Release/Profile 只有显式传入
  /// `--dart-define=CYBERSKIN_API_LOG_ENABLED=true` 才会打开。
  factory AppLogConfiguration.fromEnvironment() {
    const apiLoggingFromDefine = bool.fromEnvironment(
      'CYBERSKIN_API_LOG_ENABLED',
    );
    return AppLogConfiguration.resolve(
      isDebugMode: kDebugMode,
      apiLoggingFromDefine: apiLoggingFromDefine,
    );
  }

  /// 使用显式值解析配置，供单元测试覆盖 Debug/Release 分支。
  factory AppLogConfiguration.resolve({
    required bool isDebugMode,
    required bool apiLoggingFromDefine,
  }) {
    final apiLoggingEnabled = isDebugMode || apiLoggingFromDefine;
    return AppLogConfiguration(
      apiLoggingEnabled: apiLoggingEnabled,
      // API 日志打开时必须同时显示和落盘；Debug 也保留普通日志控制台输出。
      consoleOutputEnabled: isDebugMode || apiLoggingEnabled,
    );
  }

  /// 是否记录 API 交互汇总日志。
  final bool apiLoggingEnabled;

  /// 是否同时把日志输出到调试控制台。
  final bool consoleOutputEnabled;
}
