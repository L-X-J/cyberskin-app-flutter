# core/extensions 目录

跨业务域稳定使用的 Dart 类型扩展。

文件职责：

- `string_extensions.dart`：提供字符串安全数值转换、基础文本判断、`rgb()` / 十六进制颜色解析和资源路径构造。

边界：本目录只扩展与业务状态无关的通用语义。BLE 十六进制字节转换属于协议层，JSON
结构校验属于网络层，分别使用 `core/protocol/hex_codec.dart` 与
`core/network/json_text.dart`；不得把 Feature 业务规则或万能 helper 放入本目录。
