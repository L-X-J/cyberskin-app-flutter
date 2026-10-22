# control/presentation 目录

子目录：

- `widgets/`：自由控制域局部 UI 组件；见 `widgets/README.md`。

自由控制功能的展示层。

当前 `control_session_controller.dart` 负责全局会话状态和暂停/继续编排。后续控制页面
和状态控制器继续放在此处；页面只订阅最小状态子树并将操作转发给 Controller，不直接
访问 BLE 或 Repository 实现。

文件职责：

- `control_session_controller.dart`：以独立 `Rx` 字段维护共享会话状态，监听 BLE 连接与完整提交后的逐帧遥测（含同值帧）同步手动运行态，保留节奏/编辑优先级；编排暂停/继续及不覆盖较新状态的失败回滚。
