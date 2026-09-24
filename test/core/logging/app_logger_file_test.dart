import 'dart:io';

import 'package:cyberskin_app/core/logging/app_log.dart';
import 'package:cyberskin_app/core/logging/app_log_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'buffers API log lines to the configured file and flushes on close',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'cyberskin-logs-',
      );
      final log = await AppLogger.initialize(
        configuration: const AppLogConfiguration(
          apiLoggingEnabled: true,
          consoleOutputEnabled: false,
        ),
        logDirectory: directory,
      );

      log.apiExchange(
        method: 'GET',
        uri: Uri.parse('https://api.example.test/app/v1/config'),
        headers: const <String, String>{'Accept': 'application/json'},
        statusCode: 200,
        duration: const Duration(milliseconds: 12),
        response: const <String, Object?>{'code': 200},
      );
      log.apiExchange(
        method: 'GET',
        uri: Uri.parse('https://api.example.test/app/v1/second'),
        headers: const <String, String>{},
        statusCode: 200,
        duration: const Duration(milliseconds: 8),
        response: const <String, Object?>{'code': 200},
      );
      await log.close();

      final content = await File('${directory.path}/latest.log').readAsString();
      expect(content, contains('api.exchange'));
      expect(content, contains('app/v1/second'));
      await directory.delete(recursive: true);
    },
  );
}
