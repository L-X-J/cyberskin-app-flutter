// 十六进制文本与字节序列之间的严格编解码工具。

/// 将协议字节与十六进制文本互转。
///
/// 该工具只负责文本格式转换，不包含 BLE 命令语义、校验和或设备适配规则。调用方必须
/// 在协议边界校验包长度、方向和校验和，避免把任意十六进制文本直接当作有效设备命令。
abstract final class HexCodec {
  /// 解析可含空格或 `#` 前缀的十六进制文本。
  ///
  /// 奇数长度的有效十六进制字符串按最低位补零处理；空串返回空列表；包含非十六进制
  /// 字符时返回 `null`，由调用方决定错误转换结果。
  static List<int>? tryDecode(String source) {
    final normalized = source.replaceAll('#', '').replaceAll(' ', '');
    if (normalized.isEmpty) {
      return const <int>[];
    }
    final padded = normalized.length.isOdd ? '${normalized}0' : normalized;
    final bytes = <int>[];
    for (var offset = 0; offset < padded.length; offset += 2) {
      final value = int.tryParse(
        padded.substring(offset, offset + 2),
        radix: 16,
      );
      if (value == null) {
        return null;
      }
      bytes.add(value);
    }
    return List<int>.unmodifiable(bytes);
  }

  /// 将无符号字节编码成大写十六进制文本。
  static String encode(Iterable<int> bytes) {
    final buffer = StringBuffer();
    for (final byte in bytes) {
      if (byte < 0 || byte > 0xFF) {
        throw RangeError.range(byte, 0, 0xFF, 'byte');
      }
      buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return buffer.toString();
  }
}
