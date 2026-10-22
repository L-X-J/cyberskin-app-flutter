# control/domain

自由控制、全局设备会话和跨业务播放的纯 Dart 领域层，不依赖 Flutter、GetX 或 BLE 插件。

- `device_command_repository.dart`：语义指令访问接口及统一结果。
- `device_session.dart`：全局设备会话状态枚举及展示标签/引导语。
- `device_quick_control.dart`：连接优先的悬浮控件状态映射，低电量只覆盖运行态。
- `entities/`：节奏、Training 等业务共用的协议播放输入；见目录 README。
- `repositories/`：设备播放和后台资源端口；见目录 README。
- `services/`：跨业务的唯一设备播放状态机；接入契约与数据边界见目录 README。
