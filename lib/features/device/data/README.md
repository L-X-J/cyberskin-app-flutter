# device/data 目录

设备管理的数据访问实现层。

`in_memory_device_repository.dart` 继续为当前 BLE 会话壳提供空设备列表；
`device_api_repositories.dart` 实现后台设备型号目录和用户绑定 API。两类 Repository 的
生命周期与字段完整性不同，不得合并。

本地缓存和 BLE 数据源仍在此实现，并统一转换为领域契约与 `Result`；不得把连接句柄或
原始响应泄漏给展示层。
