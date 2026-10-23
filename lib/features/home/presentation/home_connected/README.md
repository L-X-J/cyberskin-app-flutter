# home/presentation/home_connected 目录

已连接状态下的主页视图及专属卡片与状态组件目录。

文件职责：

- `home_connected_view.dart`：已连接状态页面主视图（`HomeConnectedView`）与首页设备控制器容器（`DeviceBodyContent`），共享标题由 HomePage 渲染。
- `connected_device_hero_card.dart`：已连接设备主英雄卡片（`ConnectedDeviceHeroCard`）及图片占位（`DeviceImagePlaceholder`）。
- `home_feature_cards.dart`：双列功能模式入口网格（`HomeFeatureGrid`）与功能模式原子卡片（`HomeFeatureCard`）。
- `home_training_card.dart`：训练模式推荐卡片（`HomeTrainingCard`）。
- `home_training_background.dart`：训练推荐专属背景（`HomeTrainingBackground`），参考 SVG 自绘深蓝底、内发光与模糊菱形渐变，不依赖公共双层渐变卡片。
- `home_advertisement_card.dart`：运营位与新品推荐广告卡片（`HomeAdvertisementCard`）。
- `home_device_states.dart`：设备列表边界状态组件（`HomeDeviceLoadingState`、`HomeEmptyDeviceState`、`HomeNearbyDeviceCard`、`HomeDeviceErrorState`）。
- `compact_glass_button.dart`：设备页各卡片中复用的紧凑型液态玻璃按钮（`CompactGlassButton`）。

训练与广告组件现在消费 HomeController 的真实聚合内容。HomeTrainingCard 只展示第一条并提供 More；HomeAdvertisementCard 通过壳层提供的 RouteObserver 与应用／标签生命周期控制五秒轮播。
