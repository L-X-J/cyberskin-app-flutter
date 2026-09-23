# device/domain 目录

子目录与文件：

- `entities/`：设备实体拆分的预留目录，当前无 Dart 文件。
- `repositories/`：远端设备目录和用户绑定 Repository 抽象；见 `repositories/README.md`。

设备管理领域层。

- `device.dart`：设备摘要和连接状态。
- `device_capability.dart`：后台驱动的通道、档位和布局能力。
- `device_repository.dart`：设备数据访问契约。

此层保持纯 Dart，不依赖 Flutter、GetX、BLE 插件或具体网络客户端。

文件职责：

- `device.dart`：定义设备摘要、连接状态及其状态展示语义。
- `device_capability.dart`：定义后台驱动的设备通道、档位、模式和控制布局能力模型。
- `device_repository.dart`：定义本地会话设备列表的领域访问接口。
