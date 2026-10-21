import 'package:cyberskin_app/core/protocol/common_business_command.dart';
import 'package:cyberskin_app/features/control/free_control/domain/entities/free_control_layout.dart';
import 'package:cyberskin_app/features/control/free_control/domain/free_control_command_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const stepped = FreeControlComponentConfig(
    type: FreeControlComponentType.telescopic,
    variant: 'telescopic_mode_3x1',
    rows: 3,
    gearMax: 6,
  );

  /// 每条产出指令都必须能被通用业务协议解析器接受，否则设备适配层会拒绝。
  void expectLegal(CommonBusinessCommand command, String raw) {
    expect(command.toString(), raw);
    expect(CommonBusinessCommand.parse(raw).toString(), raw);
  }

  group('FreeControlCommandMapper', () {
    test('maps gears to logical intensity and back', () {
      // gear 0 = 停止，直接返回 0，不受 gearMin 下限干扰
      expect(FreeControlCommandMapper.gearToPercent(stepped, 0), 0);
      expect(FreeControlCommandMapper.gearToPercent(stepped, 1), 17);
      expect(FreeControlCommandMapper.gearToPercent(stepped, 4), 67);
      expect(FreeControlCommandMapper.gearToPercent(stepped, 6), 100);
      // 超界档位裁剪到 gearMin..gearMax。
      expect(FreeControlCommandMapper.gearToPercent(stepped, 99), 100);

      for (var gear = 1; gear <= 6; gear++) {
        final percent = FreeControlCommandMapper.gearToPercent(stepped, gear);
        expect(
          FreeControlCommandMapper.gearFromPercent(stepped, percent),
          gear,
        );
      }
    });

    test('stopped or unknown power has no gear', () {
      expect(FreeControlCommandMapper.gearFromPercent(stepped, 0), isNull);
      expect(FreeControlCommandMapper.gearFromPercent(stepped, -1), isNull);
      // 极低功率仍落在最低档，而不是 0 档。
      expect(FreeControlCommandMapper.gearFromPercent(stepped, 3), 1);
    });

    test('tolerates zero gearMax from backend', () {
      const broken = FreeControlComponentConfig(
        type: FreeControlComponentType.vibration,
        variant: 'vibration_mode_1x2',
        gearMax: 0,
      );
      expect(FreeControlCommandMapper.gearToPercent(broken, 1), 100);
      expect(FreeControlCommandMapper.gearFromPercent(broken, 40), 1);
    });

    test('produces protocol-legal commands', () {
      expectLegal(FreeControlCommandMapper.gear(stepped, 4), 't:67');
      expectLegal(
        FreeControlCommandMapper.intensity(
          FreeControlComponentType.vibration,
          130,
        ),
        'v:100',
      );
      expectLegal(
        FreeControlCommandMapper.toggle(FreeControlComponentType.suck, true),
        's:o',
      );
      expectLegal(
        FreeControlCommandMapper.toggle(FreeControlComponentType.heat, false),
        'h:f',
      );
      expectLegal(FreeControlCommandMapper.suckMode(2), 'CM->s:2');
    });

    test('rejects modules without a single channel', () {
      expect(
        () => FreeControlCommandMapper.toggle(
          FreeControlComponentType.oneClickClimax,
          true,
        ),
        throwsArgumentError,
      );
    });
  });

  group('FreeControlLayout.fromJson capability merge', () {
    test('fills gearMax and modes from supportedActions', () {
      final layout = FreeControlLayout.fromJson(
        deviceName: 'Device',
        layoutJson: {
          'columns': 2,
          'modules': [
            {
              'type': 'Telescopic',
              'variant': 'telescopic_mode_3x1',
              'row': 0,
              'col': 0,
              'order': 1,
            },
            {
              'type': 'Suck',
              'variant': 'suck_multi_2x2',
              'row': 3,
              'col': 0,
              'order': 2,
            },
          ],
        },
        supportedActions: [
          {'code': 'thrust', 'gearMax': 4, 'defaultValue': 50},
          {
            'code': 'suck',
            'gearMax': 0,
            'modes': [
              {'id': 'a', 'name': 'Easy'},
              {'id': 'b', 'name': ''},
            ],
          },
        ],
      );

      final telescopic = layout.components[0];
      expect(telescopic.gearMax, 4);
      // 能力 defaultValue 是 0–100 逻辑值，不能当作档位序号。
      expect(telescopic.defaultValue, 1);

      final suck = layout.components[1];
      // gearMax=0 表示不适用，不能覆盖为档位数。
      expect(suck.gearMax, isNull);
      expect(suck.modes, ['Easy', 'Mode 2']);
    });

    test('module fields win over capability', () {
      final layout = FreeControlLayout.fromJson(
        deviceName: 'Device',
        layoutJson: {
          'modules': [
            {
              'type': 'vibration',
              'variant': 'vibration_mode_1x2',
              'gearMax': 8,
              'modes': ['A'],
            },
          ],
        },
        supportedActions: [
          {
            'code': 'vibrate',
            'gearMax': 3,
            'modes': [
              {'name': 'B'},
            ],
          },
        ],
      );

      expect(layout.components.single.gearMax, 8);
      expect(layout.components.single.modes, ['A']);
    });
  });
}
