# core/network 目录

提供数据层共享的 HTTP 客户端基础能力。

当前内容包括 GetX `GetConnect` 客户端、OpenAPI 操作索引、可替换传输接口、统一
`{ code, msg, data }` 包装、严格 JSON/布尔解码、Repository 基类和无敏感信息的请求
状态监控。基础地址仍由构建参数注入。

业务请求的路径选择、请求体、DTO 转换和业务模型映射仍应留在 Feature 的 `data` 层；
`presentation` 与 `domain` 不得依赖此目录。预签名对象存储的原始字节 PUT 是唯一例外，
其使用 `package:http` 避免 GetConnect 将字节数组 JSON 编码。

文件职责：

- `api_envelope.dart`：表示后端统一的 `{ code, msg, data }` 业务响应包装。
- `api_transport.dart`：定义传输抽象和 GetConnect 实现，负责鉴权头、路径参数、请求发送和原始响应转换。
- `app_api_client.dart`：配置 API 基础地址和 GetConnect 客户端生命周期。
- `app_api_operation.dart`：集中登记 App API 操作、HTTP 方法、路径、鉴权要求和请求元数据。
- `base_remote_repository.dart`：统一处理 HTTP/业务码、401 会话失效、JSON 解码异常和 `Result` 映射。
- `json_decoder.dart`：提供严格的 JSON 对象、列表、字符串、数字、布尔值和扩展字段解码。
- `json_text.dart`：从模型回复或外部文本中提取并解析 JSON 对象。
- `network_request_monitor.dart`：保存有界、无敏感数据的请求开始/完成状态，供诊断或页面观察。
