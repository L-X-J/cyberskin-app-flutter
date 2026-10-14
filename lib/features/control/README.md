# control Feature

自由控制与全局设备会话业务域，负责运行状态、暂停/继续和快速控制入口。

当前包含设备会话领域状态、会话控制器和全局控制条。后续具体设备命令执行、能力限制
和 BLE 适配应进入 `data/`，控制业务规则与 Repository 契约应在 `domain/` 稳定后接入；
UI 不得直接拼接或发送 BLE 指令。

目录与文件：

- `data/`：控制数据源和 BLE Adapter 的预留实现边界，当前无 Dart 文件。
- `domain/`：设备会话状态；下含预留的 `entities/`、`repositories/`；见各目录 README。
- `presentation/`：会话 Controller 和控制条 Widget；下含 `widgets/`；见各目录 README。
- 当前 Feature 根目录的领域文件为 `domain/device_session.dart`，定义共享会话状态枚举。

## BLE command boundary

`data/ble_device_command_repository.dart` 是语义指令进入共享 BLE SDK 的唯一入口。控制器和
页面只能发送 `t/v/s/h` 语义命令，不得拼接十六进制帧或按型号写协议分支。
