# control/presentation 目录

自由控制功能的展示层。

当前 `control_session_controller.dart` 负责全局会话状态和暂停/继续编排。后续控制页面
和状态控制器继续放在此处；页面只订阅最小状态子树并将操作转发给 Controller，不直接
访问 BLE 或 Repository 实现。
