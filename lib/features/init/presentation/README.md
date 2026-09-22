# init/presentation 目录

包含 `InitPage` 和 `InitController`。

`InitPage` 只展示加载、失败和重试状态；`InitController` 决定当天首次阻塞请求、非首次后台
刷新以及进入设备主页的时机。页面和控制器不得直接访问 HTTP 或缓存实现。
