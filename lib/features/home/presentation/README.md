# home/presentation 目录

主页展示层按设备连接状态组合可复用的设备、内容和广告组件。

文件职责：

- `home_page.dart`：渲染未连接和已连接两种主页视觉状态，以及设备、训练和广告卡片。
- `home_widgets.dart`：主页状态卡、型号展示数据、设备卡、训练卡和广告卡，作为 `home_page.dart` 的 part 文件共享私有边界；彩色表面复用公共 `AppLayeredGradientCard`。
- `home_controller.dart`：聚合 SessionController 与设备、内容、训练 Repository 的状态。
- `home_dashboard.dart`：冻结主页可渲染数据，避免 Widget 持有可变 Repository 结果。
- `home_binding.dart`：装配主页 Controller 与领域 Repository。

页面不直接访问 HTTP、BLE 或持久化；型号展示数据消费后台颜色和标签，公共表面绘制位于 `core/widgets`，默认视觉参数位于 `core/theme`，产品图通过素材流程提供。
