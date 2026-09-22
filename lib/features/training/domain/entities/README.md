# training/domain/entities 目录

包含训练课程摘要、详情、开放 stages 协议和稳定 customMode 打点模型。

`stages` 的协议结构尚未在 OpenAPI 细化，保持不可变原始 JSON；`customMode` 的
`start-end`、`des`、`command_data` 已显式建模，命令文本可由协议层验证。
