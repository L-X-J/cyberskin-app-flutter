import 'package:cyberskin_app/core/protocol/common_business_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CommonBusinessCommand', () {
    test('parses regular and mode instructions', () {
      final command = CommonBusinessCommand.parse('CM->t:2|v:+');

      expect(command.isModeCommand, isTrue);
      expect(command.instructions, hasLength(2));
      expect(command.instructions.first.module, CommonModule.telescopic);
      expect(command.instructions.first.isMode, isTrue);
      expect(command.instructions.last.value, '+');
      expect(command.toString(), 'CM->t:2|v:+');
    });

    test('rejects invalid ranges and unsupported heat modes', () {
      expect(() => CommonBusinessCommand.parse('t:101'), throwsFormatException);
      expect(
        () => CommonBusinessCommand.parse('CM->h:1'),
        throwsFormatException,
      );
      expect(() => CommonBusinessCommand.parse('h:u'), throwsFormatException);
      expect(() => CommonBusinessCommand.parse('s:50'), throwsFormatException);
    });
  });
}
