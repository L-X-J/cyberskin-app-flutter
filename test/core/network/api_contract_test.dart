import 'dart:convert';
import 'dart:io';

import 'package:cyberskin_app/core/network/app_api_operation.dart';
import 'package:cyberskin_app/core/network/json_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'OpenAPI operation registry exactly covers every App API operation',
    () async {
      final source = await File('docs/openapi/app-openapi.json').readAsString();
      final document = jsonDecode(source) as Map<String, dynamic>;
      final paths = document['paths'] as Map<String, dynamic>;
      final expected = <String>{};
      for (final entry in paths.entries) {
        final operations = entry.value as Map<String, dynamic>;
        for (final operation in operations.entries) {
          if (!const <String>{
            'get',
            'post',
            'put',
            'delete',
          }.contains(operation.key)) {
            continue;
          }
          final details = operation.value as Map<String, dynamic>;
          final authenticated = (details['security'] as List).isNotEmpty;
          expected.add(
            '${operation.key.toUpperCase()} ${entry.key} $authenticated',
          );
        }
      }

      final actual = AppApiOperation.values.map((operation) {
        final spec = AppApiOperations.spec(operation);
        return '${spec.method.name.toUpperCase()} ${spec.path} '
            '${spec.requiresAuthentication}';
      }).toSet();

      expect(actual, expected);
      expect(actual, hasLength(30));
    },
  );

  test('boolean decoder accepts supported compatibility encodings', () {
    const pairs = <Object, bool>{
      true: true,
      false: false,
      1: true,
      0: false,
      'true': true,
      'false': false,
      'Y': true,
      'N': false,
    };

    for (final entry in pairs.entries) {
      expect(
        ApiJson.boolean(<String, dynamic>{'value': entry.key}, 'value'),
        entry.value,
      );
    }
    expect(ApiJson.boolean(const <String, dynamic>{}, 'value'), isNull);
    expect(
      () => ApiJson.boolean(<String, dynamic>{'value': 'enabled'}, 'value'),
      throwsFormatException,
    );
  });
}
