# device/domain/repositories 目录

本目录定义设备型号目录和用户绑定设备的 Repository 抽象及不可变模型。

现有 `device_repository.dart` 仍只描述本地 BLE 连接/会话设备列表；它与这里的远端型号、
绑定记录分离，避免将缺少实时连接状态和电量的后台数据伪装为 BLE 会话状态。接口不得暴露
HTTP、BLE 句柄或数据库类型。

文件职责：

- `device_catalog_repository.dart`：定义远端设备型号目录查询契约及相关领域模型。
- `user_device_repository.dart`：定义当前用户设备绑定列表、绑定和解绑契约及相关领域模型。
