// 片段时长的解析、执行前校验和往返边界回归。
import 'dart:convert';
import 'dart:io';

import 'package:cyberskin_app/core/protocol/common_business_command.dart';
import 'package:cyberskin_app/features/control/domain/entities/common_program_segment.dart';
import 'package:cyberskin_app/features/control/domain/services/common_program_compiler.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm_program.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('标准样例原样往返，共用编译器只按打点进入发令，相对段不盲目恢复', () {
    final raw = jsonDecode(
      File('docs/BLE协议相关/program_data_sample.json').readAsStringSync(),
    ) as List;
    final segments = raw
        .map(
          (item) => CommonProgramSegment.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
    expect(segments.map((segment) => segment.toJson()).toList(), raw);
    final program = CommonProgramCompiler.compile(
      source: 'training',
      deviceModelId: 1,
      segments: segments,
      modules: CommonModule.values,
    );
    expect(program.steps.map((step) => step.duration.inSeconds), [3, 2, 3]);
    expect(program.steps.first.commands.single.toString(), 't:+|v:+');
    expect(program.steps.first.resumable, isFalse);
    expect(program.steps[1].resumable, isTrue);
    expect(program.stopCommand.toString(), 't:s|v:s|s:s|h:f');
  });
  test('修改和删除后连续重排；输出仅包含标准三字段', () {
    final segments = RhythmStep.timeline([
      RhythmStep(durationSec: 3, channels: []).encode(),
      RhythmStep(durationSec: 1200, channels: []).encode(),
    ]);
    expect(segments.last.payload['start-end'], '00:03-20:03');
    expect(segments.first.payload.keys.toSet(), {
      'start-end',
      'des',
      'command_data',
    });
    expect(
      RhythmStep.timeline(segments.skip(1)).single.payload['start-end'],
      '00:00-20:00',
    );
  });
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
        RhythmSegment({
          'start-end': '00:00-${CommonProgramSegment.formatTime(seconds)}',
          'des': 'Rest',
          'command_data': 't:s',
        }),
      );
      expect(() => step.validate(capabilities), returnsNormally);
      expect(RhythmStep.decode(step.encode()).durationSec, seconds);
    });
  }
  for (final seconds in [-1, 0, 1201]) {
    test('$seconds 秒在解析与执行前均拒绝', () {
      expect(
        () => RhythmStep.decode(
          RhythmSegment({
            'start-end': '00:00-${CommonProgramSegment.formatTime(seconds)}',
            'des': 'Rest',
            'command_data': 't:s',
          }),
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
