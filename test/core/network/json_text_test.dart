import 'package:cyberskin_app/core/network/json_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonText', () {
    test('decodes a JSON object wrapped by prose and Markdown fences', () {
      const source = '''
Here is the result:
```json
{"name":"Cyberskin","enabled":true}
```
''';

      expect(JsonText.tryDecodeObject(source), <String, dynamic>{
        'name': 'Cyberskin',
        'enabled': true,
      });
    });

    test('returns null for malformed or non-object JSON', () {
      expect(JsonText.tryDecodeObject('{"name":'), isNull);
      expect(JsonText.tryDecodeObject('[1,2,3]'), isNull);
      expect(JsonText.isValid('{"ok":true}'), isTrue);
      expect(JsonText.isValid('{"ok":'), isFalse);
    });
  });
}
