# training/presentation

- `training_binding.dart`：训练列表命名路由的局部依赖绑定。
- `training_route_arguments.dart`：首帧摘要及包含入口和课程 ID 的 Hero 身份。
- `training_session_controller.dart`：应用级预览与运行快照编排，原子 Rx、请求世代与账号隔离；不包含 BLE 或 HTTP。
- `pages/`：列表 home 和预览／运行详情 info，各页专用组件放在本页 widgets。
- `widgets/`：训练共用页面框架与 Hero 标题。

启动先由 TrainingProgram 校验，执行只交给现有唯一 DeviceProgramPlayback。返回不停止会话，Stop 带原程序身份，停止失败保留会话。
