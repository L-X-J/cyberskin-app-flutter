# device/presentation 目录

设备管理功能的展示层。

- `device_home_controller.dart`：加载设备列表并管理独立 UI 状态。
- `device_home_page.dart`：设备主页、空状态、错误状态、已连接设备 hero、能力入口、训练占位和广告占位。
- `device_manual_binding.dart`：解析说明书路由参数并注册说明书 Controller。
- `device_model_card.dart`：首页型号入口和说明书页型号选择器共用的彩色玻璃型号卡片。
- `device_manual_controller.dart`：通过 `DeviceCatalogRepository` 加载型号列表、详情和三段说明书，并读取型号广告配置。
- `device_manual_page.dart`：统一渲染型号选择、固定 AppBar、产品 hero、三段 HTML 富文本和底部广告。
- `device_manual_route_arguments.dart`：传递型号 ID 与入口卡片摘要，支持首帧和 Hero 动画。

页面通过 Controller 访问领域契约，不直接调用 API、缓存或 BLE；列表状态使用局部
`Obx`，避免重建整个应用壳。

## 布局边界

- 详情与说明书使用同一页面；顶部返回按钮固定，滚动后型号名称自动成为 AppBar 标题。
- 设备列表按 Repository 顺序展示；详情页只展示后端返回的产品内容和广告配置，不复制
  `home` Feature 的 Repository 编排逻辑，也不在广告缺失时渲染本地默认广告。
- 设备名称、状态、电量、颜色和标签来自 `Device`。当 `Device.model` 是数字字符串时，
  页面将其作为当前可用的型号 ID，通过 `AppRoutes.deviceManual` 打开说明书；硬件键不是
  数字时保留禁用占位，避免伪造路由参数。
- 训练仍由设备主页负责；详情页广告由型号详情接口返回，presentation 层只消费 Controller
  状态，不引入网络访问。

文件职责：

- `device_home_controller.dart`：加载设备列表，维护加载/失败/成功状态，并屏蔽 Repository 细节。
- `device_home_page.dart`：渲染深色滚动设备首页、已连接设备主卡、能力入口、训练/广告占位、
  刷新操作、空态和错误态。
- `device_manual_binding.dart`：只负责设备说明书路由参数校验和依赖装配。
- `device_manual_controller.dart`：维护详情加载、失败和重试状态，不解析 HTTP 响应。
- `device_manual_route_arguments.dart`：只传递入口卡片已知摘要，不替代详情 Repository。
- `device_model_card.dart`：只负责型号卡视觉、Hero 产品图和首页/详情选择器两个尺寸变体。
