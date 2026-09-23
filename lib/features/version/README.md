# version Feature

版本检查业务域负责读取服务端发布的升级信息。

本 Feature 只提供升级决策数据，不执行下载、安装或平台权限操作。

目录与文件：

- `data/`：版本检查 API Repository；当前有 `version_remote_repository.dart`。
- `domain/`：版本检查模型和 Repository 契约；下含 `entities/`、`repositories/`。
- `presentation/`：当前尚无目录和 Dart 文件；升级提示与路由应由后续展示层负责。
- 当前 Feature 根目录无 Dart 文件。
