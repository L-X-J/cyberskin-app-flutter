# home/presentation/home_connected 目录

已连接状态下的主页视图及专属卡片与状态组件目录。

文件职责：

- `home_connected_view.dart`：已连接状态页面主视图（`HomeConnectedView`）、独立设备页标题（`_DeviceHeader`）与控制器容器（`DeviceBodyContent`）。
- `connected_device_hero_card.dart`：已连接设备主英雄卡片（`ConnectedDeviceHeroCard`）及图片占位（`DeviceImagePlaceholder`）。
- `home_feature_cards.dart`：双列功能模式入口网格（`HomeFeatureGrid`）与功能模式原子卡片（`HomeFeatureCard`）。
- `home_training_card.dart`：训练模式推荐卡片（`HomeTrainingCard`）。
- `home_advertisement_card.dart`：运营位与新品推荐广告卡片（`HomeAdvertisementCard`）。
- `home_device_states.dart`：设备列表边界状态组件（`HomeDeviceLoadingState`、`HomeEmptyDeviceState`、`HomeNearbyDeviceCard`、`HomeDeviceErrorState`）。
- `compact_glass_button.dart`：设备页各卡片中复用的紧凑型液态玻璃按钮（`CompactGlassButton`）。
