# control/data

语义指令进入共享 `cyberskin_device_sdk` 的数据层；设备帧编码和 BLE 写入仍由 SDK 所有。

- `ble_device_command_repository.dart`：语义命令 Repository，手动操作经公共播放器仲裁后接管设备；公共播放端口使用未装饰的命令实例，避免递归仲裁。
- `ble_device_playback_port.dart`：把共享 BLE 协调器的设备身份、通知心跳、账号失效及原生后台服务适配为公共播放端口，节奏和 Training 共用。

- `common_program_file_cache.dart`：以稳定 URL 为键下载/校验标准程序 JSON，复用 CacheManager 磁盘缓存最多30天；临时签名不落盘，过期不降级，供 Rhythm 和 Training 共用。
