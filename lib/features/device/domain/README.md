# device/domain 目录

设备管理领域层。

- `device.dart`：设备摘要和连接状态。
- `device_capability.dart`：后台驱动的通道、档位和布局能力。
- `device_repository.dart`：设备数据访问契约。

此层保持纯 Dart，不依赖 Flutter、GetX、BLE 插件或具体网络客户端。
