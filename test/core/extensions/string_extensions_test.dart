import 'package:cyberskin_app/core/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StringExtensions', () {
    test('parses numbers with fallbacks', () {
      expect('42'.toIntOr(), 42);
      expect('bad'.toIntOr(fallback: 7), 7);
      expect('3.5'.toDoubleOr(), 3.5);
      expect('bad'.toDoubleOr(fallback: 1.25), 1.25);
    });

    test('builds consistent asset paths', () {
      expect('logo'.assetsPng, 'assets/images/logo.png');
      expect('icon'.assetsSvg, 'assets/images/icon.svg');
      expect('loading'.assetsLottie, 'assets/lotties/loading.json');
      expect('images/logo.png'.images, 'assets/images/images/logo.png');
    });

    test('parses color formats and rejects invalid values', () {
      expect('#FF00AA'.toColor(), const Color(0xFFFF00AA));
      expect('#80FF00AA'.toColor(), const Color(0x80FF00AA));
      expect('rgb(255, 0, 170)'.toColor(), const Color(0xFFFF00AA));
      expect('rgb(256, 0, 0)'.toColor(), Colors.transparent);
      expect('not-a-color'.toColor(), Colors.transparent);
    });

    test('distinguishes null and blank strings', () {
      const String? missing = null;
      expect(missing.isNullOrEmpty, isTrue);
      expect(''.isNullOrEmpty, isTrue);
      expect('text'.isNullOrEmpty, isFalse);
      expect(' text '.isBlank, isFalse);
      expect('   '.isBlank, isTrue);
    });
  });
}
