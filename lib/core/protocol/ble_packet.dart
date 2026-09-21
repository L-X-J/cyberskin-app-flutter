/// Cyberskin BLE 协议的数据方向标记。
enum BlePacketDirection {
  /// App 发往设备的命令包标记 `0xAA`。
  command(0xAA),

  /// 设备发往 App 的通知包标记 `0xDD`。
  notification(0xDD);

  const BlePacketDirection(this.marker);

  /// BLE 数据帧使用的首字节标记。
  final int marker;

  /// 将数据帧首字节解析为方向枚举。
  static BlePacketDirection fromMarker(int marker) => switch (marker) {
    0xAA => BlePacketDirection.command,
    0xDD => BlePacketDirection.notification,
    _ => throw FormatException(
      'Unknown BLE packet marker: 0x${marker.toRadixString(16)}',
    ),
  };
}

/// 不可变的 BLE 协议数据包，负责帧结构与校验和处理。
final class BlePacket {
  /// 创建数据包；调用方必须保证各字段均为无符号字节。
  const BlePacket({
    required this.direction,
    required this.command,
    required this.payload,
  });

  /// 从字节序列解码数据包，并校验长度与校验和。
  factory BlePacket.fromBytes(List<int> bytes) {
    if (bytes.length < 3) {
      throw const FormatException(
        'BLE packet must contain marker, command and checksum',
      );
    }
    final direction = BlePacketDirection.fromMarker(bytes.first);
    final command = bytes[1];
    final payload = bytes.sublist(2, bytes.length - 1);
    final checksum = bytes.last;
    final expected = calculateChecksum(<int>[command, ...payload]);
    if (checksum != expected) {
      throw FormatException(
        'Invalid BLE checksum: expected 0x${expected.toRadixString(16)}, '
        'received 0x${checksum.toRadixString(16)}',
      );
    }
    return BlePacket(
      direction: direction,
      command: command,
      payload: List.unmodifiable(payload),
    );
  }

  /// 数据包在 App 与设备之间的传输方向。
  final BlePacketDirection direction;

  /// 协议命令字节。
  final int command;

  /// 命令参数字节列表。
  final List<int> payload;

  /// 将数据包编码为可写入 BLE 特征的字节序列。
  List<int> toBytes() {
    final body = <int>[command, ...payload];
    return <int>[direction.marker, ...body, calculateChecksum(body)];
  }

  /// 按协议计算累加后对 256 取模的校验和。
  static int calculateChecksum(Iterable<int> bytes) {
    final sum = bytes.fold<int>(0, (total, byte) => total + byte);
    return sum & 0xFF;
  }
}
