# control/domain/repositories

控制领域与设备 IO 的抽象边界，不暴露 BLE 特征值或具体插件类型。

- `device_playback_port.dart`：公共播放的物理设备身份、连接/心跳/账号失效事件，以及语义发令和后台资源端口；实现归属 `control/data`。
