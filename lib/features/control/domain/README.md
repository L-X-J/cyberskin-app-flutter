# control/domain 目录

自由控制功能的领域层。

当前 `device_session.dart` 定义全局控制条使用的会话状态。后续具体控制规则、命令值和
Repository 契约应放在这里，并使用不可变模型；此层不得依赖 Flutter、GetX 或 BLE 插件。
