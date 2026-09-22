# auth/domain 目录

认证领域的不可变用户模型、登录输入值和 Repository 抽象位于此处。

本目录不得依赖 Flutter、GetX、GetConnect 或安全存储插件；登录凭证只允许在 `data/` 内部
持久化，避免令牌泄漏到 presentation。
