# init/presentation 目录

文件职责：

- `init_controller.dart`：读取缓存并执行当天首次阻塞/非首次后台刷新策略，维护初始化状态并导航到设备页。
- `init_page.dart`：展示初始化加载、失败和重试 UI，不直接执行启动 IO。

包含 `InitPage` 和 `InitController`。

`InitPage` 只展示加载、失败和重试状态；`InitController` 决定当天首次阻塞请求、非首次后台
刷新以及进入设备主页的时机。页面和控制器不得直接访问 HTTP 或缓存实现。
