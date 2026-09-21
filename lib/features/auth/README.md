# auth Feature

账号与会话业务域，负责登录、注册、凭证生命周期和用户身份状态。

当前仅建立 `presentation/` 目录骨架，尚无实现。后续领域模型、认证 Repository 抽象
放在 `domain/`，API 与安全存储实现放在 `data/`；页面不得直接处理令牌或调用认证 API。
