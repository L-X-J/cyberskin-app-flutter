# device/presentation 目录

设备管理功能的展示层。

- `device_home_controller.dart`：加载设备列表并管理独立 UI 状态。
- `device_home_page.dart`：设备主页、空状态、错误状态和设备卡片。

页面通过 Controller 访问领域契约，不直接调用 API、缓存或 BLE；列表状态使用局部
`Obx`，避免重建整个应用壳。
