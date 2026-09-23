# video/domain/repositories 目录

文件职责：

- `video_repository.dart`：定义官方视频分页查询接口。

包含官方视频分页查询的 Repository 抽象。

接口不暴露 HTTP、文件系统或播放器 SDK 类型；实现归 `video/data`。
