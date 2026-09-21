# device/data 目录

设备管理的数据访问实现层。

当前 `in_memory_device_repository.dart` 在真实服务接入前明确返回空设备列表。后续 API、
本地缓存和 BLE 数据源均在此实现，并统一转换为 `DeviceRepository` 契约与 `Result`；
不得把连接句柄或原始响应泄漏给展示层。
