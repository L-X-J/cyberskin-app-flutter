# core/network 目录

提供数据层共享的 HTTP 客户端基础能力。

当前 `app_api_client.dart` 封装 GetX `GetConnect` 的地址注入、超时和 JSON 请求入口。
业务请求、响应模型转换和错误映射仍应留在 Feature 的 `data` 层；`presentation` 和
`domain` 不得依赖此目录。
