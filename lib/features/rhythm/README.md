# rhythm Feature

片段式自定义节奏业务域，负责节奏定义、编辑、保存和播放编排。

当前目录仅完成分层骨架。领域模型和 Repository 契约进入 `domain/`，API、本地缓存或
BLE 节奏下发进入 `data/`，页面与 Controller 进入 `presentation/`；节奏不得在 UI 中
转换为设备命令。

目录与文件：

- `data/`：节奏 API、缓存和后续设备 Adapter；当前有 `rhythm_remote_repository.dart`。
- `domain/`：节奏模型和 CRUD 契约；下含 `entities/`、`repositories/`。
- `presentation/`：编辑页、列表页和 Controller 的预留展示层，当前无 Dart 文件。
- 当前 Feature 根目录无 Dart 文件。
