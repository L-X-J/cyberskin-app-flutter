import 'package:cyberskin_app/core/logging/app_log.dart';
import 'package:cyberskin_app/core/logging/app_log_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('API 日志关闭时不显示也不存储交互日志', () async {
    final lines = <String>[];
    final log = await AppLogger.forTesting(
      onLine: lines.add,
      configuration: const AppLogConfiguration(
        apiLoggingEnabled: false,
        consoleOutputEnabled: false,
      ),
    );

    log.apiExchange(
      method: 'POST',
      uri: Uri.parse('https://api.example.test/app/v1/auth/email/login'),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: const <String, Object?>{'email': 'user@example.test'},
      statusCode: 200,
      duration: const Duration(milliseconds: 10),
      response: const <String, Object?>{'code': 200},
    );

    expect(lines, isEmpty);
    await log.close();
  });

  test('API 汇总日志包含请求、响应、耗时并脱敏凭证和个人字段', () async {
    final lines = <String>[];
    final log = await AppLogger.forTesting(
      onLine: lines.add,
      configuration: const AppLogConfiguration(
        apiLoggingEnabled: true,
        consoleOutputEnabled: false,
      ),
    );

    log.apiExchange(
      method: 'POST',
      uri: Uri.parse('https://api.example.test/app/v1/auth/email/login'),
      headers: const <String, String>{
        'Authorization': 'Bearer raw-token',
        'Content-Type': 'application/json',
      },
      body: const <String, Object?>{
        'email': 'user@example.test',
        'code': '123456',
      },
      statusCode: 200,
      duration: const Duration(milliseconds: 12),
      response: const <String, Object?>{
        'code': 200,
        'data': <String, Object?>{'token': 'response-token'},
      },
    );

    await log.close();
    expect(lines, hasLength(1));
    final output = lines.single;
    expect(output, contains('api.exchange'));
    expect(output, contains('POST'));
    expect(output, contains('Content-Type'));
    expect(
      output,
      contains('https://api.example.test/app/v1/auth/email/login'),
    );
    expect(output, contains('"durationMs":12'));
    expect(output, contains('<redacted>'));
    expect(output, isNot(contains('raw-token')));
    expect(output, isNot(contains('response-token')));
    expect(output, isNot(contains('user@example.test')));
    expect(output, isNot(contains('123456')));
  });

  test('文件传输不记录请求参数、二进制载荷或响应载荷', () async {
    final lines = <String>[];
    final log = await AppLogger.forTesting(
      onLine: lines.add,
      configuration: const AppLogConfiguration(
        apiLoggingEnabled: true,
        consoleOutputEnabled: false,
      ),
    );

    log.apiExchange(
      method: 'PUT',
      uri: Uri.parse('https://upload.example.test/object'),
      headers: const <String, String>{'Content-Type': 'image/png'},
      body: const <int>[137, 80, 78, 71],
      statusCode: 200,
      duration: const Duration(milliseconds: 20),
      response: 'binary-response',
      isFileTransfer: true,
    );

    await log.close();
    final output = lines.single;
    expect(output, contains('api.exchange'));
    expect(output, isNot(contains('"parameters"')));
    expect(output, isNot(contains('"response"')));
    expect(output, isNot(contains('137')));
    expect(output, isNot(contains('binary-response')));
  });

  test('文件传输移除签名 query，普通 query 脱敏敏感值', () async {
    final lines = <String>[];
    final log = await AppLogger.forTesting(
      onLine: lines.add,
      configuration: const AppLogConfiguration(
        apiLoggingEnabled: true,
        consoleOutputEnabled: false,
      ),
    );

    log.apiExchange(
      method: 'PUT',
      uri: Uri.parse(
        'https://upload.example.test/object?X-Amz-Signature=raw-signature',
      ),
      headers: const <String, String>{},
      statusCode: 200,
      duration: const Duration(milliseconds: 5),
      isFileTransfer: true,
    );
    log.apiExchange(
      method: 'GET',
      uri: Uri.parse(
        'https://api.example.test/items?page=2&token=raw-query-token',
      ),
      headers: const <String, String>{},
      statusCode: 200,
      duration: const Duration(milliseconds: 5),
      response: const <String, Object?>{'code': 200},
    );

    await log.close();
    final output = lines.join('\n');
    expect(output, contains('https://upload.example.test/object'));
    expect(output, isNot(contains('X-Amz-Signature')));
    expect(output, isNot(contains('raw-signature')));
    expect(output, contains('page=2'));
    expect(output, contains('token=%3Credacted%3E'));
    expect(output, isNot(contains('raw-query-token')));
  });

  test('关闭幂等，关闭后忽略新日志', () async {
    final lines = <String>[];
    final log = await AppLogger.forTesting(
      onLine: lines.add,
      configuration: const AppLogConfiguration(
        apiLoggingEnabled: true,
        consoleOutputEnabled: false,
      ),
    );

    await Future.wait(<Future<void>>[log.close(), log.close()]);
    log.info('ignored after close');

    expect(lines, isEmpty);
  });
}
