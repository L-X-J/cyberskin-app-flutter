# device/presentation 目录

设备管理功能的展示层，提供首页仍使用的设备状态控制器、型号卡片和说明书页面。

文件职责：

- `device_home_controller.dart`：供主页设备内容体加载设备列表，维护加载、失败、发现状态，并同步已连接设备视图；订阅实时连接快照，空绑定列表不清除活动连接。
- `device_manual_binding.dart`：解析说明书路由参数并注册说明书 Controller。
- `device_manual_controller.dart`：通过 `DeviceCatalogRepository` 加载型号列表、详情和三段说明书，并读取型号广告配置。
- `device_manual_page.dart`：统一渲染型号选择、固定 AppBar、产品 hero、三段 HTML 富文本和底部广告。
- `device_manual_route_arguments.dart`：传递型号 ID 与入口卡片摘要，支持首帧和 Hero 动画。
- `device_model_card.dart`：首页型号入口和说明书页型号选择器共用的彩色玻璃型号卡片。

页面通过 Controller 访问领域契约，不直接调用 API、缓存或 BLE。
设备首页统一由 `home/presentation/home_page.dart` 组合 `home_connected/` 与
`home_disconnected/` 视图，不再提供独立设备首页路由。

## 布局边界

- 详情与说明书使用同一页面；顶部返回按钮固定，滚动后型号名称自动成为 AppBar 标题。
- 型号列表按 Repository 顺序展示；详情页只展示后端返回的产品内容和广告配置，不复制
  `home` Feature 的 Repository 编排逻辑，也不在广告缺失时渲染本地默认广告。
- 首页设备卡通过 `AppRoutes.deviceManual` 打开说明书，路由参数只传递型号 ID 和入口摘要。
- 训练与主页广告由 HomeController 提供；详情页广告由型号详情接口返回，presentation
  层只消费 Controller 状态，不引入网络访问。
