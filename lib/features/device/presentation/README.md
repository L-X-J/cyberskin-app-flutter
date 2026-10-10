# device/presentation 目录

设备管理功能的展示层。

- `device_home_controller.dart`：加载设备列表并管理独立 UI 状态。
- `device_home_page.dart`：设备主页、空状态、错误状态、已连接设备 hero、能力入口、训练占位和广告占位。
- `device_manual_binding.dart`：解析说明书路由型号参数并注册页面 Controller。
- `device_manual_controller.dart`：加载设备说明书，维护加载、失败和选中条目状态。
- `device_manual_route_arguments.dart`：说明书路由的非领域展示参数，保留来源设备名称。
- `device_manual_page.dart`：只读产品说明书页面、后台顺序标签和 HTML 文本 fallback。

页面通过 Controller 访问领域契约，不直接调用 API、缓存或 BLE；列表状态使用局部
`Obx`，避免重建整个应用壳。

## 布局边界

- 顶部标题和资料入口位于页面内容层，`AppScaffold` 负责全局壳层、底部 Device / Video 导航
  和设备快捷控制条空间。
- 设备列表按 Repository 顺序展示；每个设备包含 hero、两个能力入口、训练占位和广告占位，
  不复制 `home` Feature 的 Repository 编排逻辑。
- 设备名称、状态、电量、颜色和标签来自 `Device`。当 `Device.model` 是数字字符串时，
  页面将其作为当前可用的型号 ID，通过 `AppRoutes.deviceManual` 打开说明书；硬件键不是
  数字时保留禁用占位，避免伪造路由参数。
- 训练与广告当前没有接入设备页 Controller，页面只保留与已连接设计一致的稳定占位，不在
  presentation 层引入网络访问。

文件职责：

- `device_home_controller.dart`：加载设备列表，维护加载/失败/成功状态，并屏蔽 Repository 细节。
- `device_home_page.dart`：渲染深色滚动设备首页、已连接设备主卡、能力入口、训练/广告占位、
  刷新操作、空态和错误态。
- `device_manual_binding.dart`：只负责路由参数校验和 Repository 依赖装配，不承载业务加载逻辑。
- `device_manual_controller.dart`：通过 `DeviceCatalogRepository.getManual` 编排说明书读取和 tab 选中状态。
- `device_manual_route_arguments.dart`：只传递来源页面已有的设备显示名，不替代型号 ID 或 Repository 数据。
- `device_manual_page.dart`：消费 Controller 状态并渲染深色、滚动、无主导航的说明书页面。
