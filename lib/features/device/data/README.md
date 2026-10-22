# device data

设备数据层负责 App API、BLE SDK profile 映射、用户设备绑定和运行态协调。

- `device_api_repositories.dart`：设备目录和用户绑定 API Repository。
- `ble_known_device_store.dart`：使用 SharedPreferences 保存已确认的物理 remoteId。
- `cyberskin_ble_runtime_coordinator.dart`：加载后端 profile、启动后台扫描、处理首次发现确认、完成 BLE 连接与后端绑定，并把 SDK 事件投影成 GetX 状态；每帧先提交完整快照与连接视图，再广播不去重的心跳，供节奏推进和快捷会话遥测校正。
- `connected_device_repository.dart`：合并用户绑定记录、设备详情和 BLE 连接状态，向领域层提供设备摘要。

本目录不得直接拼接 BLE 十六进制帧；命令必须经 `cyberskin_device_sdk` 的 profile 生成。
