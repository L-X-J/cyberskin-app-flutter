# profile/domain/repositories 目录

包含用户资料更新的 Repository 抽象与输入值对象。

接口只描述资料更新和错误语义，不暴露具体 HTTP 路径、存储键或 SDK 类型；实现由
`profile/data` 提供并由 `app` 完成装配。

文件职责：

- `profile_repository.dart`：定义用户资料更新方法和输入值对象，不暴露 API 路径或存储细节。
