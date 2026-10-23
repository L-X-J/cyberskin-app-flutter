# home/presentation 目录

主页展示层按设备连接状态组合可复用的设备、内容和广告组件。

目录及文件职责：

- `home_page.dart`：持有首页一级 Device / Video 内容切换，渲染主页壳层与动画过渡。
- `home_disconnected/`：未连接状态的独立 UI 视图目录。
  - `home_disconnected_view.dart`：未连接状态视图（`HomeDisconnectedView`）、扫描卡与型号入口。
- `home_connected/`：已连接状态的独立 UI 视图目录。
  - `home_connected_view.dart`：已连接状态视图（`HomeConnectedView`）、设备页标题与控制器容器。
  - `connected_device_hero_card.dart`：已连接设备主卡（`ConnectedDeviceHeroCard`）。
  - `home_feature_cards.dart`：功能模式双列网格与卡片（`HomeFeatureGrid`、`HomeFeatureCard`）。
  - `home_training_card.dart`：训练模式推荐卡（`HomeTrainingCard`）。
  - `home_advertisement_card.dart`：运营位广告卡（`HomeAdvertisementCard`）。
  - `home_device_states.dart`：设备列表空状态、加载中与错误重试组件。
  - `compact_glass_button.dart`：跨卡片复用的紧凑液态玻璃按钮。
- `widgets/`：主页共享展示与广告辅助组件目录。
  - `home_shared_widgets.dart`：主页共享背景与头部标题组件。
  - `home_advertisement_helper.dart`：广告图片本地缓存与统一跳转逻辑。
- `states/`：主页 UI 状态目录。
  - `home_ble_card_state.dart`：主页顶部 BLE 蓝牙卡视图展示状态 (`HomeBleCardState`) 与阶段枚举 (`HomeBleCardPhase`)。
- `app/widgets/app_glass_surfaces.dart`：跨一级页面复用的玻璃卡片、紧凑操作和提示表面；主页不再维护第二套实现。
- `home_controller.dart`：聚合 SessionController、设备/内容/训练 Repository，并编排 BLE profile 加载、自动发现、已知设备自动重连、首次发现确认和连接状态同步。
- `home_dashboard.dart`：冻结主页可渲染数据，避免 Widget 持有可变 Repository 结果。
- `home_binding.dart`：装配主页 Controller 与领域 Repository。

页面不直接访问 HTTP、BLE 或持久化；主页通过 Controller 接收扫描状态和首次发现设备，Controller 将 BLE 事件同步到 SessionController 与设备 Repository。型号展示数据消费后台颜色和标签，公共表面绘制位于 `core/widgets`，默认视觉参数位于 `core/theme`，产品图通过素材流程提供。

首页训练与广告通过 HomeRepository 一次聚合；HomeController 对内容加载单独维护请求世代、加载状态和错误，型号优先级为实际连接 → 绑定 → 不筛选。
