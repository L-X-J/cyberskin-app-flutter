# device Feature

设备管理业务域，负责设备发现、摘要、连接状态和后台驱动的能力模型。

当前包含设备领域模型、Repository 抽象与实现、设备状态控制器、型号卡片和说明书页面。
设备首页由 `home` Feature 组合；UI 不得硬编码设备型号、通道或控制布局。

目录与文件：

- `data/`：远端设备目录、用户绑定和内存设备 Repository 实现；见 `data/README.md`。
- `domain/`：设备、能力和 Repository 契约；下含 `entities/`、`repositories/`；见各目录 README。
- `presentation/`：首页设备状态 Controller、型号卡片和说明书页面；见 `presentation/README.md`。
- 当前 Feature 根目录无 Dart 文件。

## BLE runtime

真实扫描、自动重连、GATT 服务/特征绑定、协议 Adapter 和语义指令发送由同级的
`cyberskin_device_sdk` 包负责。`data/` 只把后端 `DeviceModelDetail.ble` 映射成 SDK
profile，并把 SDK 事件转换成 Cyberskin 状态；页面不直接依赖 FlutterBluePlus。
