// 节奏片段的类型化解析、设备能力与执行前校验；不依赖 Flutter。
import '../../../../core/protocol/common_business_command.dart';
import '../../../control/domain/entities/common_program_segment.dart';
import '../../../device/domain/repositories/device_catalog_repository.dart';
import 'rhythm.dart';

/// 通用协议的四类通道；可见项由已发布设备能力决定。
enum RhythmChannel {
  /// 伸缩运动通道。
  thrust('Stretch', CommonModule.telescopic),

  /// 振动运动通道。
  vibration('Vibration', CommonModule.vibration),

  /// 吸吮运动通道。
  suck('Suck', CommonModule.suck),

  /// 加热通道，只允许开启/关闭。
  heat('Heat', CommonModule.heat);

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
    'heat' || 'heating' || 'h' => heat,
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
    if (model.heatSupported &&
        !result.any((cap) => cap.channel == RhythmChannel.heat)) {
      result.add(
        const RhythmChannelCapability(
          channel: RhythmChannel.heat,
          modes: [],
          variableSpeed: false,
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
    this.operation,
  });

  /// 对应的运动通道。
  final RhythmChannel channel;

  /// 本片段是否启用该通道；关闭时执行器会明确发送停止。
  final bool on;

  /// 1-based 模式号；为空时不自动插入模式指令。
  final int? mode;

  /// 逻辑强度百分比；不存储设备专属硬件档位。
  final int? value;

  /// 通用协议的其他操作符（如 +、-、u、d）；读取后编辑时保留。
  final String? operation;

  /// 产生新的通道草稿；未传字段保持不变，clearMode 显式清除模式。
  RhythmChannelSetting copyWith({
    bool? on,
    int? mode,
    int? value,
    bool clearMode = false,
    bool clearValue = false,
  }) => RhythmChannelSetting(
    channel: channel,
    on: on ?? this.on,
    mode: clearMode ? null : mode ?? this.mode,
    value: clearValue ? null : value ?? this.value,
    operation: on != null || mode != null || value != null || clearMode
        ? null
        : operation,
  );
}

/// 可执行片段；开放原始 payload 仍由 RhythmSegment 保留。
final class RhythmStep {
  /// 从标准打点还原编辑草稿；通用协议数字的含义由 CM-> 决定。
  factory RhythmStep.decode(RhythmSegment segment) {
    final program = segment.program;
    if (!isValidDuration(program.durationSeconds)) {
      throw const FormatException(durationError);
    }
    final channels = program.command.instructions.map((instruction) {
      final channel = RhythmChannel.parse(instruction.module.key);
      final numeric = int.tryParse(instruction.value);
      return RhythmChannelSetting(
        channel: channel,
        on: !const {'s', 'f', '0'}.contains(instruction.value),
        mode: instruction.isMode ? numeric : null,
        value: !instruction.isMode ? numeric : null,
        operation:
            numeric == null &&
                !const {'o', 's', 'f'}.contains(instruction.value)
            ? instruction.value
            : null,
      );
    }).toList();
    return RhythmStep(durationSec: program.durationSeconds, channels: channels);
  }

  /// 创建实例；依赖及初始状态由调用方提供。
  RhythmStep({
    required this.durationSec,
    required List<RhythmChannelSetting> channels,
  }) : channels = List.unmodifiable(channels);

  /// 客户端片段最短整数秒；解析与输入共用同一边界。
  static const minDurationSec = 1;

  /// App 与服务端共用的单段最大时长。
  static const maxDurationSec = 1200;

  /// 整数秒边界校验，供解析、执行和输入复用。
  static bool isValidDuration(int seconds) =>
      seconds >= minDurationSec && seconds <= maxDurationSec;

  /// 可直接展示的时长边界错误。
  static const durationError = 'Duration must be 1–1200 seconds.';

  /// 片段持续整数秒，范围由 minDurationSec / maxDurationSec 定义。
  final int durationSec;

  /// 冻结的通道设置列表。
  final List<RhythmChannelSetting> channels;

  /// 生成样例规定的标准打点；设备能力只决定缺省停止通道，不写入文件。
  RhythmSegment encode({
    int startSeconds = 0,
    List<RhythmChannelCapability>? capabilities,
  }) {
    if (!isValidDuration(durationSec)) {
      throw const FormatException(durationError);
    }
    final command = _command(capabilities);
    final description = channels
        .where((setting) => setting.on)
        .map(
          (setting) =>
              '${setting.channel.label}: ${setting.mode != null
                  ? 'Mode ${setting.mode}'
                  : setting.value != null
                  ? '${setting.value}%'
                  : setting.operation ?? 'on'}',
        )
        .join('; ');
    return RhythmSegment({
      'start-end':
          '${CommonProgramSegment.formatTime(startSeconds)}-${CommonProgramSegment.formatTime(startSeconds + durationSec)}',
      'des': description.isEmpty ? 'Rest; all channels off' : description,
      'command_data': command.toString(),
    });
  }

  /// 编辑/删除后统一重排时间轴，命令及说明保持原值。
  static List<RhythmSegment> timeline(Iterable<RhythmSegment> segments) {
    var start = 0;
    return segments
        .map((segment) {
          final program = segment.program.at(start);
          start = program.endSeconds;
          return RhythmSegment(program.toJson());
        })
        .toList(growable: false);
  }

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
    if (channels.any((setting) => setting.on && setting.mode != null) &&
        channels.any((setting) => setting.on && setting.value != null)) {
      throw const FormatException(
        'Use modes or numeric speeds in one segment.',
      );
    }
    final seen = <RhythmChannel>{};
    for (final setting in channels) {
      if (!seen.add(setting.channel)) {
        throw const FormatException('Duplicate rhythm channel.');
      }
      if (setting.channel == RhythmChannel.heat &&
          (setting.value != null || setting.mode != null)) {
        throw const FormatException('Heat only supports on/off.');
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

  /// 每个打点只有一条通用指令；模式和数字速度不能在同条指令混用。
  List<CommonBusinessCommand> commands(
    List<RhythmChannelCapability> capabilities,
  ) {
    validate(capabilities);
    return [_command(capabilities)];
  }

  CommonBusinessCommand _command(List<RhythmChannelCapability>? capabilities) {
    final modeCommand = channels.any(
      (setting) => setting.on && setting.mode != null,
    );
    if (modeCommand &&
        channels.any((setting) => setting.on && setting.value != null)) {
      throw const FormatException(
        'Use modes or numeric speeds in one segment.',
      );
    }
    final ordered =
        capabilities?.map((capability) => capability.channel).toList() ??
        (channels.isEmpty
            ? [RhythmChannel.thrust]
            : channels.map((setting) => setting.channel).toList());
    final parts = <String>[];
    for (final channel in ordered) {
      final matches = channels.where((setting) => setting.channel == channel);
      final setting = matches.isEmpty
          ? RhythmChannelSetting(channel: channel)
          : matches.first;
      final value = !setting.on
          ? channel == RhythmChannel.heat
                ? 'f'
                : 's'
          : setting.mode?.toString() ??
                setting.value?.toString() ??
                setting.operation ??
                'o';
      parts.add('${channel.module.key}:$value');
    }
    return CommonBusinessCommand.parse(
      '${modeCommand ? 'CM->' : ''}${parts.join('|')}',
    );
  }
}
