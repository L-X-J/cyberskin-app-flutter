# rhythm/data

远端 CRUD、安全缓存和型号能力访问。设备播放端口统一归属 `control/data`。

- `cached_rhythm_repository.dart`：节奏远端访问的缓存装饰器；只缓存会话隔离的元数据/前3段快照；详情预览只读元数据，Start/主动编辑通过公共文件缓存加载完整JSON并核对统计，写入以服务端成功为准。
- `rhythm_catalog_repository.dart`：聚合已绑定型号和后台能力，并缓存离线运行所需的最小能力快照。
- `rhythm_local_store.dart`：节奏元数据缓存保存在安全存储v3中，以登录会话隔离，避免跨账号读取。
- `rhythm_remote_repository.dart`：自定义节奏 App API 的元数据 Repository；响应解析文件URL、短快照与统计，不从快照构造播放内容。
