# profile/data 目录

`profile_remote_repository.dart` 实现昵称和头像的远端更新，并通过 ProfileRepository
暴露给领域层。

后续头像或偏好缓存仍应通过 Repository 统一访问。涉及凭证或个人数据时不得在此目录写入
日志或把敏感字段暴露给展示层。

文件职责：

- `profile_remote_repository.dart`：实现用户昵称和头像更新 API，并把响应和异常转换为领域结果。
