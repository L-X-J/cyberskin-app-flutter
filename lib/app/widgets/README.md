# app/widgets 目录

存放跨一级页面复用的应用壳组件。

文件职责：

- `app_scaffold.dart`：统一顶部栏、左下 Device / Video 导航，按底部安全区与可用宽度协调导航/悬浮控件的位置，报告随路由转场变化的安全内容区域，并为 Dock 保留滚动余量。
- `app_flower_loading_indicator.dart`：无交互、无语义的持续旋转花形加载视觉组件，供应用壳和一级页面复用。
- `app_glass_surfaces.dart`：跨一级页面复用的玻璃卡片、文字按钮、图标按钮和提示表面；不承载业务状态。
- `app_primary_tab_navigation.dart`：一级 Device / Video 液态玻璃分段导航；只呈现选中状态和选择事件，不直接持有路由。
- `floating_device_control_overlay.dart`：根 Navigator 上方的单实例悬浮宿主，订阅最小设备状态树，接收点击与拖动事件。

业务状态映射留在 control/domain，设备会话操作由既有 Controller 处理；这里不访问 Repository、BLE 或持久化。仅被单一 Feature 使用的 Widget 留在对应 Feature 的 `presentation` 层。
