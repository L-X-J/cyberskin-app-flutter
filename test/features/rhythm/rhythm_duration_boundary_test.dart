// 片段时长的解析、执行前校验和往返边界回归。
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm_program.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const capabilities = [
    RhythmChannelCapability(
      channel: RhythmChannel.thrust,
      modes: [],
      variableSpeed: true,
    ),
  ];
  for (final seconds in [1, 120, 121, 180, 1199, 1200]) {
    test('$seconds 秒可解析、校验和往返，不被旧 120 秒限制拦截', () {
      final step = RhythmStep.decode(
        RhythmSegment({'durationSec': seconds, 'channels': <Object?>[]}),
      );
      expect(() => step.validate(capabilities), returnsNormally);
      expect(RhythmStep.decode(step.encode()).durationSec, seconds);
    });
  }
  for (final seconds in [-1, 0, 1201]) {
    test('$seconds 秒在解析与执行前均拒绝', () {
      expect(
        () => RhythmStep.decode(
          RhythmSegment({'durationSec': seconds, 'channels': <Object?>[]}),
        ),
        throwsFormatException,
      );
      expect(
        () => RhythmStep(
          durationSec: seconds,
          channels: [],
        ).validate(capabilities),
        throwsFormatException,
      );
    });
  }
  for (final value in [1.5, '1200', null, double.infinity]) {
    test('$value 不作为整数时长解析', () {
      expect(
        () => RhythmStep.decode(
          RhythmSegment({'durationSec': value, 'channels': <Object?>[]}),
        ),
        throwsFormatException,
      );
    });
  }
}
