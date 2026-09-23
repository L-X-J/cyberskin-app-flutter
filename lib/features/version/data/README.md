# version/data 目录

文件职责：

- `version_remote_repository.dart`：请求指定平台和版本的升级信息，并将可为空的发布字段解码为 `VersionCheck`。

包含 VersionRepository 的 App API 实现和版本 JSON 映射。

请求参数和响应字段遵循 OpenAPI，错误由基础 Repository 转换为 `Result`。
