# video Feature

视频体验业务域，规划官方、浏览器和本地视频来源。

当前包含 `presentation/` 入口占位，其余分层为后续扩展预留。视频来源模型和访问契约
进入 `domain/`，平台播放器、文件访问和远端数据进入 `data/`；页面不得直接处理文件
路径、网络协议或播放器资源生命周期。

目录与文件：

- `data/`：官方视频 API、文件索引、缓存和播放器适配的数据边界；见 `data/README.md`。
- `domain/`：视频模型和访问契约；下含 `entities/`、`repositories/`。
- `presentation/`：视频标签页入口和后续播放器宿主；见 `presentation/README.md`。
- 当前 Feature 根目录无 Dart 文件。
