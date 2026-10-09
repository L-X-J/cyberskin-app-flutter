# control/presentation/widgets 目录

自由控制功能的局部 UI 组件目录。

当前 `device_control_pill.dart` 展示跨页面复用的会话快捷控制条，不读取全局依赖，状态与动作由应用悬浮宿主传入。仅服务控制业务域的
组件放在此处，并优先以独立响应式字段驱动最小 `Obx`；跨业务域稳定复用后才考虑提升到
`core/widgets`。

文件职责：

- `device_control_pill.dart`：基于 `flutter_liquid_glass_plus` 展示运行、低电量、暂停、断连和连接中过渡态；不负责导航、设备协议或拖动定位。
