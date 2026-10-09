# app/widgets 目录

存放跨一级页面复用的应用壳组件。

文件职责：

- `app_scaffold.dart`：统一顶部栏、可选的 Device / Video 底部导航，报告随路由转场变化的内容区域，并为悬浮控件保留滚动余量。
- `floating_device_control_overlay.dart`：根 Navigator 上方的单实例悬浮宿主，订阅最小设备状态树，接收点击与拖动事件。

业务状态映射留在 control/domain，设备会话操作由既有 Controller 处理；这里不访问 Repository、BLE 或持久化。仅被单一 Feature 使用的 Widget 留在对应 Feature 的 `presentation` 层。
