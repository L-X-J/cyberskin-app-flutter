# training Feature

训练课程与运行业务域，负责课程浏览、启动、进度和运行状态。

当前目录仅完成分层骨架。领域课程模型与运行规则进入 `domain/`，课程 API、缓存和
设备执行适配进入 `data/`，相关页面与控制状态进入 `presentation/`。

目录与文件：

- `data/`：训练课程远端 Repository；当前有 `training_remote_repository.dart`。
- `domain/`：课程、阶段、进度和运行规则的领域边界；下含 `entities/`、`repositories/`。
- `presentation/`：课程列表、详情和运行页的预留展示层，当前无 Dart 文件。
- 当前 Feature 根目录无 Dart 文件。
