# rhythm/data

远端 CRUD、安全缓存和共享 BLE/原生后台能力的适配实现。

- `ble_rhythm_device_port.dart`：将 BLE 状态通知与原生后台运行能力适配为节奏领域端口。
- `cached_rhythm_repository.dart`：节奏远端访问的缓存装饰器；只在网络失败时读缓存，写入以服务端成功为准。
- `rhythm_catalog_repository.dart`：聚合已绑定型号和后台能力，并缓存离线运行所需的最小能力快照。
- `rhythm_local_store.dart`：节奏缓存保存在安全存储中，以登录会话隔离，避免跨账号读取。
- `rhythm_remote_repository.dart`：自定义节奏 App API 的远端 Repository 实现。
