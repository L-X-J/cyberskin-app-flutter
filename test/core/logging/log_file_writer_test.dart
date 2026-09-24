import 'dart:io';

import 'package:cyberskin_app/core/logging/log_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes queued lines in order and flush waits for disk', () async {
    final directory = await Directory.systemTemp.createTemp('log-writer-');
    final writer = LogFileWriter(directory: directory);
    await writer.initialize();

    writer.write('one');
    writer.write('two');
    await writer.flush();

    expect(await File(writer.currentFilePath).readAsLines(), <String>[
      'one',
      'two',
    ]);
    await writer.close();
    await directory.delete(recursive: true);
  });

  test('rotates oversized files and limits retained archives', () async {
    final directory = await Directory.systemTemp.createTemp('log-rotation-');
    final writer = LogFileWriter(
      directory: directory,
      configuration: const LogFileWriterConfiguration(
        maxFileBytes: 5,
        maxRotatedFiles: 1,
      ),
    );
    await writer.initialize();

    writer.write('1234');
    await writer.flush();
    writer.write('5678');
    await writer.flush();
    writer.write('abcd');
    await writer.flush();
    await writer.close();

    final logs = await directory
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.log'))
        .toList();
    expect(logs, hasLength(2));
    expect(await File(writer.currentFilePath).readAsLines(), <String>['abcd']);
    await directory.delete(recursive: true);
  });
}
