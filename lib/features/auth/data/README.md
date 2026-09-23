# auth/data 目录

实现认证 App API 和安全会话持久化的 Repository 位于此处。

本目录通过 `core/network` 的传输边界访问网络，并将解析失败、HTTP 失败和业务失败转换为
`Result`；不得让 token 或 clientId 离开认证数据边界。

文件职责：

- `auth_remote_repository.dart`：实现邮箱验证码、邮箱/Google/Apple 登录、当前用户和登出，并负责会话凭证保存与清理。
