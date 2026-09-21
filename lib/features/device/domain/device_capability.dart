/// 设备能力模型可以开放的硬件控制通道。
enum DeviceChannel {
  /// 伸缩通道。
  telescopic,

  /// 振动通道。
  vibration,

  /// 吸附通道。
  suck,

  /// 加热通道。
  heat,
}

/// 单个硬件通道的不可变能力定义。
final class ChannelCapability {
  /// 创建通道能力定义并校验默认值与档位范围。
  ChannelCapability({
    required this.channel,
    this.gearMax,
    this.defaultValue = 0,
    this.variableSpeedSupported = false,
    List<String> modes = const <String>[],
  }) : assert(defaultValue >= 0 && defaultValue <= 100),
       assert(gearMax == null || gearMax > 0),
       modes = List.unmodifiable(modes);

  /// 当前定义对应的硬件通道。
  final DeviceChannel channel;

  /// 通道支持离散档位时的最大档位。
  final int? gearMax;

  /// 设备会话开始使用的默认逻辑值。
  final int defaultValue;

  /// 通道是否接受 `0-100` 的连续数值。
  final bool variableSpeedSupported;

  /// 后台配置的模式展示名称。
  final List<String> modes;
}

/// 由后台驱动的硬件型号功能与布局能力。
final class DeviceCapabilities {
  /// 创建能力模型，并冻结通道列表。
  DeviceCapabilities({
    required List<ChannelCapability> channels,
    this.layoutConfigRef,
    this.gridColumns = 2,
  }) : assert(gridColumns == 1 || gridColumns == 2),
       channels = List.unmodifiable(channels);

  /// 按通道保存的能力定义列表。
  final List<ChannelCapability> channels;

  /// 已发布后台布局配置的标识。
  final String? layoutConfigRef;

  /// 自由控制布局使用的列数。
  final int gridColumns;

  /// 判断设备是否支持指定通道。
  bool supports(DeviceChannel channel) =>
      channels.any((capability) => capability.channel == channel);

  /// 返回 [channel] 对应的能力定义；未配置时返回 `null`。
  ChannelCapability? forChannel(DeviceChannel channel) {
    for (final capability in channels) {
      if (capability.channel == channel) {
        return capability;
      }
    }
    return null;
  }
}
