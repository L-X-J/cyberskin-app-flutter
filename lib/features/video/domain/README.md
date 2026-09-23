# video/domain 目录

子目录与文件：

- `entities/`：官方视频和分页领域模型；见 `entities/README.md`。
- `repositories/`：官方视频访问抽象；见 `repositories/README.md`。
- 当前 `domain/` 根目录无 Dart 文件。

视频功能的领域层预留目录，当前尚无实现。

后续放置视频来源、元数据和播放状态等纯 Dart 模型及 Repository 契约。领域层不得依赖
Flutter 播放器、文件系统插件或具体 API。
