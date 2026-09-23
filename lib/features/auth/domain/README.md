# auth/domain 目录

认证领域的不可变用户模型、登录输入值和 Repository 抽象位于此处。

本目录不得依赖 Flutter、GetX、GetConnect 或安全存储插件；登录凭证只允许在 `data/` 内部
持久化，避免令牌泄漏到 presentation。

文件职责：

- `app_user.dart`：定义不可变的当前用户领域模型。
- `auth_repository.dart`：定义发送验证码、登录、读取当前用户和登出的领域接口，以及登录请求值对象。
