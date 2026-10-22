# rhythm/domain/repositories

节奏持久化和型号能力的领域边界；设备播放端口由 control 领域统一定义。

- `rhythm_catalog.dart`：节奏可选择的已绑定型号及其能力访问边界。
- `rhythm_device_port.dart`：旧节奏端口类型的兼容名称，映射到公共 `DevicePlaybackPort` / Target / Event，避免影响既有节奏调用方。
- `rhythm_repository.dart`：自定义节奏 CRUD 的领域访问抽象。
