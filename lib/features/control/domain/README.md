# control/domain 目录

子目录与文件：

- `entities/`：复杂控制实体的预留目录，当前无 Dart 文件。
- `repositories/`：控制数据访问抽象的预留目录，当前无 Dart 文件。

自由控制功能的领域层。

当前 `device_session.dart` 定义控制会话状态，`device_quick_control.dart` 将连接与会话状态映射为悬浮控件的展示状态。后续具体控制规则、命令值和
Repository 契约应放在这里，并使用不可变模型；此层不得依赖 Flutter、GetX 或 BLE 插件。

文件职责：

- `device_session.dart`：定义设备会话状态枚举及其展示标签/引导语，供全局控制条和 Controller 使用。
- `device_quick_control.dart`：连接状态优先的四态及连接中过渡态映射；低电量只覆盖运行态。
