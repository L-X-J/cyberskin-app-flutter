# core/storage 目录

本目录提供跨业务域稳定复用的安全凭证存储：`session_credential_store.dart` 使用
`flutter_secure_storage` 在系统 Keychain/Keystore 保存 App API token、clientId 和失效时间。

Feature 专属缓存键、序列化和失效策略仍归对应 Feature 的 `data` 层。这里不得保存业务
缓存、页面状态或可展示用户资料。

文件职责：

- `session_credential_store.dart`：定义会话凭证存储接口、凭证值对象和 Keychain/Keystore 实现。
