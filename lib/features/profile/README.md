# profile Feature

用户资料业务域，规划账号资料、隐私、反馈和版本等能力。

当前仅包含 `presentation/` 占位页面，其余分层目录为后续扩展预留。领域模型与
Repository 契约应先在 `domain/` 定义，API 和本地存储实现放在 `data/`，页面不得直接
读取凭证或调用远端接口。
