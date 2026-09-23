# control/presentation/widgets 目录

自由控制功能的局部 UI 组件目录。

当前 `device_control_pill.dart` 展示跨页面复用的会话快捷控制条。仅服务控制业务域的
组件放在此处，并优先以独立响应式字段驱动最小 `Obx`；跨业务域稳定复用后才考虑提升到
`core/widgets`。

文件职责：

- `device_control_pill.dart`：展示当前设备会话状态和暂停/继续入口的局部控制条组件。
