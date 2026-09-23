# core/protocol 目录

设备无关协议与 BLE 帧编解码的统一边界。

- `common_business_command.dart`：解析和校验 `t/v/s/h` 通用业务指令。
- `ble_packet.dart`：负责 BLE 数据包方向、命令、载荷及校验和编解码。

具体设备命令到 BLE 字节的映射应由 Feature `data` 层 Adapter 完成。页面和控制器禁止
依赖十六进制字符串拼接或绕过本目录的协议值对象。

文件职责：

- `common_business_command.dart`：解析、校验和序列化设备无关的 `t/v/s/h` 业务指令。
- `ble_packet.dart`：编码、解码 BLE 命令/通知数据包，并校验包方向、载荷和校验和。
