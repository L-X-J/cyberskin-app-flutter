# app/widgets 目录

存放跨一级页面复用的应用壳组件。

当前 `app_scaffold.dart` 统一顶部栏、底部导航和全局设备控制条。组件只接收展示所需
状态并转发导航事件，不直接访问 Repository、BLE 或持久化。仅被单一 Feature 使用的
Widget 应留在对应 Feature 的 `presentation` 层。
