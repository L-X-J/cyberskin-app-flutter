# video/data 目录

文件职责：

- `video_remote_repository.dart`：分页查询后台官方视频，并把分页响应映射为不可变领域模型。

`video_remote_repository.dart` 实现后台官方视频分页查询。

本地文件索引、缓存和平台播放器适配仍应在此层或基础设施中实现；生命周期、权限与资源
释放策略不得进入展示层。
