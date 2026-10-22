# rhythm/domain/repositories

节奏持久化、型号能力、设备及后台服务的领域边界。

- `rhythm_catalog.dart`：节奏可选择的已绑定型号及其能力访问边界。
- `rhythm_device_port.dart`：节奏执行所需的设备及后台能力边界；展示层不接触 BLE 协调器。
- `rhythm_repository.dart`：自定义节奏 CRUD 的领域访问抽象。
