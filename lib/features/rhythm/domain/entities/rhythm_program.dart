// 节奏片段的类型化解析、设备能力与执行前校验；不依赖 Flutter。
import '../../../../core/protocol/common_business_command.dart';
import '../../../device/domain/repositories/device_catalog_repository.dart';
import 'rhythm.dart';

/// 节奏编辑器支持的运动通道；加热不属于本期片段控制。
enum RhythmChannel {
  /// 伸缩运动通道。
  thrust('Stretch', CommonModule.telescopic),

  /// 振动运动通道。
  vibration('Vibration', CommonModule.vibration),

  /// 吸吮运动通道。
  suck('Suck', CommonModule.suck);

  const RhythmChannel(this.label, this.module);

  /// 界面展示文案。
  final String label;

  /// 对应通用语义协议模块，不暴露硬件字节。
  final CommonModule module;

  /// 统一历史通道别名，未知通道明确拒绝。
  static RhythmChannel parse(String value) => switch (value.toLowerCase()) {
    'thrust' || 'telescopic' || 't' => thrust,
    'vibration' || 'vibrate' || 'v' => vibration,
    'suck' || 'suction' || 's' => suck,
    _ => throw FormatException('Unsupported rhythm channel: $value'),
  };
}

/// 后台型号能力，模式顺序沿用当前通用协议的 1-based 编号。
final class RhythmChannelCapability {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmChannelCapability({
    required this.channel,
    required this.modes,
    required this.variableSpeed,
    this.gearMax,
    this.defaultValue = 0,
  });

  /// 对应的运动通道。
  final RhythmChannel channel;

  /// 后台配置的模式显示名称，列表顺序对应协议编号。
  final List<String> modes;

  /// 是否支持 0–100 的连续速度。
  final bool variableSpeed;

  /// 离散档位上限；为空时不展示分档滑杆。
  final int? gearMax;

  /// 后台提供的默认逻辑强度。
  final int defaultValue;

  /// 从已发布型号提取支持的通道和模式，不写死型号能力。
  static List<RhythmChannelCapability> fromModel(DeviceModelDetail model) {
    final result = <RhythmChannelCapability>[];
    for (final action in model.supportedActions) {
      RhythmChannel channel;
      try {
        channel = RhythmChannel.parse('${action['code']}');
      } on FormatException {
        continue;
      }

      final modes = action['modes'] as List? ?? const [];
      result.add(
        RhythmChannelCapability(
          channel: channel,
          modes: List.unmodifiable([
            for (var i = 0; i < modes.length; i++)
              modes[i] is Map
                  ? '${(modes[i] as Map)['name'] ?? 'Mode ${i + 1}'}'
                  : '${modes[i]}',
          ]),
          variableSpeed:
              action['variableSpeed'] == true ||
              action['variableSpeedSupported'] == true,
          gearMax: (action['gearMax'] as num?)?.toInt(),
          defaultValue: (action['defaultValue'] as num?)?.toInt() ?? 0,
        ),
      );
    }
    return List.unmodifiable(result);
  }
}

/// 一个通道在片段内的完整状态；value 始终为逻辑百分比。
final class RhythmChannelSetting {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmChannelSetting({
    required this.channel,
    this.on = false,
    this.mode,
    this.value,
  });

  /// 对应的运动通道。
  final RhythmChannel channel;

  /// 本片段是否启用该通道；关闭时执行器会明确发送停止。
  final bool on;

  /// 1-based 模式号；为空时执行使用该通道默认模式。
  final int? mode;

  /// 逻辑强度百分比；不存储设备专属硬件档位。
  final int? value;

  /// 产生新的通道草稿；未传字段保持不变，clearMode 显式清除模式。
  RhythmChannelSetting copyWith({
    bool? on,
    int? mode,
    int? value,
    bool clearMode = false,
  }) => RhythmChannelSetting(
    channel: channel,
    on: on ?? this.on,
    mode: clearMode ? null : mode ?? this.mode,
    value: value ?? this.value,
  );

  /// 序列化为现有 channels 数组条目。
  Map<String, Object?> toJson() => {
    'channel': channel.name,
    'on': on,
    if (mode != null) 'mode': mode,
    if (value != null) 'value': value,
  };
}

/// 可执行片段；开放原始 payload 仍由 RhythmSegment 保留。
final class RhythmStep {
  /// 客户端片段最短整数秒；解析与输入共用同一边界。
  static const minDurationSec = 1;

  /// 用户确认的客户端上限；远端契约须同步支持后才能保证云端保存。
  static const maxDurationSec = 1200;

  /// 整数秒边界校验，供解析、执行和输入复用。
  static bool isValidDuration(int seconds) =>
      seconds >= minDurationSec && seconds <= maxDurationSec;

  /// 可直接展示的时长边界错误。
  static const durationError = 'Duration must be 1–1200 seconds.';

  /// 解析历史及当前片段结构，拒绝无法安全执行的歧义数据。
  factory RhythmStep.decode(RhythmSegment segment) {
    final raw = segment.payload;
    final duration = _integer(raw['durationSec'], 'Duration');
    if (!isValidDuration(duration)) {
      throw const FormatException(durationError);
    }

    final items = <Map<String, dynamic>>[];
    final nested = raw['channels'];
    if (nested != null &&
        raw.keys.any((key) => key != 'durationSec' && key != 'channels')) {
      throw const FormatException(
        'Do not mix nested and flat channel settings.',
      );
    }
    if (nested is List) {
      for (final item in nested) {
        if (item is! Map) throw const FormatException('Invalid channel data.');
        items.add(Map<String, dynamic>.from(item));
      }
    } else if (nested == null || nested is Map) {
      final map = nested is Map ? Map<String, dynamic>.from(nested) : raw;
      for (final entry in map.entries) {
        if (entry.key == 'durationSec') continue;
        if (entry.value is! Map) {
          throw const FormatException('Unsupported segment data.');
        }
        items.add({
          ...Map<String, dynamic>.from(entry.value as Map),
          'channel': entry.key,
        });
      }
    } else {
      throw const FormatException('Unsupported segment data.');
    }
    if (raw.keys.any(
      (key) =>
          key != 'durationSec' &&
          key != 'channels' &&
          ![
            'thrust',
            'telescopic',
            'vibration',
            'vibrate',
            'suck',
            'suction',
            't',
            'v',
            's',
          ].contains(key),
    )) {
      throw const FormatException(
        'This segment contains unsupported settings.',
      );
    }
    final values = <RhythmChannelSetting>[];
    final seen = <RhythmChannel>{};
    for (final item in items) {
      if (item.keys.any(
        (key) => !['channel', 'on', 'mode', 'value'].contains(key),
      )) {
        throw const FormatException(
          'This channel contains unsupported settings.',
        );
      }

      final channel = RhythmChannel.parse('${item['channel']}');
      if (!seen.add(channel)) {
        throw const FormatException('Duplicate rhythm channel.');
      }
      if (item['on'] is! bool) {
        throw const FormatException('Channel on must be boolean.');
      }

      final mode = item['mode'] == null ? null : _integer(item['mode'], 'Mode');

      final value = item['value'] == null
          ? null
          : _integer(item['value'], 'Speed');
      if (mode != null && (mode < 1 || mode > 100)) {
        throw const FormatException('Invalid mode.');
      }
      if (value != null && (value < 0 || value > 100)) {
        throw const FormatException('Invalid speed.');
      }
      if (channel == RhythmChannel.suck && value != null) {
        throw const FormatException('Suck does not support speed.');
      }
      values.add(
        RhythmChannelSetting(
          channel: channel,
          on: item['on'] as bool,
          mode: mode,
          value: value,
        ),
      );
    }
    return RhythmStep(durationSec: duration, channels: values);
  }

  /// 创建实例；依赖及初始状态由调用方提供。
  RhythmStep({
    required this.durationSec,
    required List<RhythmChannelSetting> channels,
  }) : channels = List.unmodifiable(channels);

  /// 片段持续整数秒，范围由 minDurationSec / maxDurationSec 定义。
  final int durationSec;

  /// 冻结的通道设置列表。
  final List<RhythmChannelSetting> channels;

  static int _integer(Object? value, String field) {
    if (value is! num || !value.isFinite || value != value.roundToDouble()) {
      throw FormatException('$field must be an integer.');
    }
    return value.toInt();
  }

  /// 生成当前规范结构的片段快照。
  RhythmSegment encode() => RhythmSegment({
    'durationSec': durationSec,
    'channels': channels.map((e) => e.toJson()).toList(),
  });

  /// 在保存及执行前核对时长与型号能力，防止失效模式被下发。
  void validate(List<RhythmChannelCapability> capabilities) {
    if (!isValidDuration(durationSec)) {
      throw const FormatException(durationError);
    }
    if (capabilities.isEmpty) {
      throw const FormatException(
        'This device has no supported rhythm channels.',
      );
    }
    final seen = <RhythmChannel>{};
    for (final setting in channels) {
      if (!seen.add(setting.channel)) {
        throw const FormatException('Duplicate rhythm channel.');
      }
      if (setting.channel == RhythmChannel.suck && setting.value != null) {
        throw const FormatException('Suck does not support speed.');
      }
      final matches = capabilities.where((c) => c.channel == setting.channel);
      if (matches.isEmpty) {
        throw FormatException(
          '${setting.channel.label} is not supported by this device.',
        );
      }
      final cap = matches.first;
      if (setting.mode != null &&
          (setting.mode! < 1 ||
              setting.mode! > 100 ||
              setting.mode! > cap.modes.length)) {
        throw const FormatException(
          'A saved mode is no longer available. Edit this rhythm first.',
        );
      }
      if (setting.value != null &&
          (setting.value! < 0 || setting.value! > 100)) {
        throw const FormatException('Speed must be between 0 and 100%.');
      }
    }
  }

  /// 每段重发所有可用运动通道；关闭未开启的通道，避免遗留上段参数。
  List<CommonBusinessCommand> commands(
    List<RhythmChannelCapability> capabilities,
  ) {
    validate(capabilities);

    final modes = <CommonInstruction>[];
    final levels = <CommonInstruction>[];
    for (final cap in capabilities) {
      final settings = channels.where((s) => s.channel == cap.channel);

      final setting = settings.isEmpty
          ? RhythmChannelSetting(channel: cap.channel)
          : settings.first;

      final mode = setting.mode ?? (cap.modes.isNotEmpty ? 1 : null);
      if (setting.on && mode != null) {
        modes.add(
          CommonInstruction(
            module: cap.channel.module,
            value: '$mode',
            isMode: true,
          ),
        );
      }

      final value = !setting.on
          ? 's'
          : cap.channel == RhythmChannel.suck
          ? 'o'
          : setting.value != null
          ? '${setting.value}'
          : cap.defaultValue > 0
          ? '${cap.defaultValue.clamp(0, 100)}'
          : 'o';
      levels.add(
        CommonInstruction(
          module: cap.channel.module,
          value: value,
          isMode: false,
        ),
      );
    }
    return [
      if (modes.isNotEmpty)
        CommonBusinessCommand(isModeCommand: true, instructions: modes),
      CommonBusinessCommand(isModeCommand: false, instructions: levels),
    ];
  }
}
