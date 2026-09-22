# core/network 目录

提供数据层共享的 HTTP 客户端基础能力。

当前内容包括 GetX `GetConnect` 客户端、OpenAPI 操作索引、可替换传输接口、统一
`{ code, msg, data }` 包装、严格 JSON/布尔解码、Repository 基类和无敏感信息的请求
状态监控。基础地址仍由构建参数注入。

业务请求的路径选择、请求体、DTO 转换和业务模型映射仍应留在 Feature 的 `data` 层；
`presentation` 与 `domain` 不得依赖此目录。预签名对象存储的原始字节 PUT 是唯一例外，
其使用 `package:http` 避免 GetConnect 将字节数组 JSON 编码。
