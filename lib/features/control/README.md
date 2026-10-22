# control Feature

自由控制、全局设备会话与跨业务播放领域，负责运行状态、暂停/继续、设备控制权和协议序列执行。

领域模型和播放规则位于 `domain/`，语义命令访问和设备/后台端口实现在 `data/`，
会话控制器和全局控制条位于 `presentation/`。UI 不得直接拼接或发送 BLE 指令。

目录与文件：

- `data/`：语义指令 Repository 与公共 BLE/原生后台播放端口。
- `domain/`：设备会话状态与公共播放；下含 `entities/`、`repositories/`、`services/`；见各目录 README。
- `presentation/`：会话 Controller 和控制条 Widget；下含 `widgets/`；见各目录 README。
- `free_control/`：能力与后台布局驱动的自由控制子域；见各目录 README。
- 当前 Feature 根目录的领域文件为 `domain/device_session.dart`，定义共享会话状态枚举。

## BLE command boundary

`data/ble_device_command_repository.dart` 是语义指令进入共享 BLE SDK 的唯一入口。控制器和
页面只能发送 `t/v/s/h` 语义命令，不得拼接十六进制帧或按型号写协议分支。

## free_control 数据流

`free_control/` 子域：`DeviceModelDetail.layout + supportedActions → FreeControlLayout`（领域层合并）
→ `FreeControlController` → 各模块 Widget；用户操作经 `FreeControlCommandMapper` 生成语义指令，
由控制器按通道 latest-wins 串行下发（拖动滑杆只发最新值，开关/模式指令独立排队）；
`ConnectedDeviceState` 遥测回流到模块 Widget。详见 `free_control/domain/README.md`。

节奏与 Training 共用 `domain/entities/device_program.dart` 和 `domain/services/device_program_playback.dart`，由 `AppBinding` 注册唯一实例。各业务持久化 DTO 独立转换；接入方式见 `domain/services/README.md`。
