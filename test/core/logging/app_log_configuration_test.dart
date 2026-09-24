import 'package:cyberskin_app/core/logging/app_log_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Debug 模式默认打开 API 日志和控制台输出', () {
    final configuration = AppLogConfiguration.resolve(
      isDebugMode: true,
      apiLoggingFromDefine: false,
    );

    expect(configuration.apiLoggingEnabled, isTrue);
    expect(configuration.consoleOutputEnabled, isTrue);
  });

  test('Release 模式只有显式构建参数才打开 API 日志', () {
    final disabled = AppLogConfiguration.resolve(
      isDebugMode: false,
      apiLoggingFromDefine: false,
    );
    final enabled = AppLogConfiguration.resolve(
      isDebugMode: false,
      apiLoggingFromDefine: true,
    );

    expect(disabled.apiLoggingEnabled, isFalse);
    expect(disabled.consoleOutputEnabled, isFalse);
    expect(enabled.apiLoggingEnabled, isTrue);
    expect(enabled.consoleOutputEnabled, isTrue);
  });
}
