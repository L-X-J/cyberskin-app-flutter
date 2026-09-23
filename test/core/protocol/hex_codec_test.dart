import 'package:cyberskin_app/core/protocol/hex_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HexCodec', () {
    test('decodes separators and pads odd-length input', () {
      expect(HexCodec.tryDecode('#AA 0D E'), <int>[0xAA, 0x0D, 0xE0]);
      expect(HexCodec.tryDecode(''), isEmpty);
    });

    test('rejects invalid characters instead of silently truncating', () {
      expect(HexCodec.tryDecode('AA-G'), isNull);
    });

    test('encodes bytes with stable uppercase formatting', () {
      expect(HexCodec.encode(<int>[0xAA, 0x0D, 0x0E]), 'AA0D0E');
      expect(() => HexCodec.encode(<int>[256]), throwsRangeError);
    });
  });
}
