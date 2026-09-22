# ADR-004：以 GetConnect 和 Base Repository 固化 App API 数据边界

状态：Accepted

## 背景

App OpenAPI 快照当前包含 29 个 `/app/v1/**` 操作。后端同时使用 HTTP 状态与统一
`{ code, msg, data }` 业务包装，受保护请求要求 `Authorization: Bearer <token>` 与
`clientid` 两个请求头。各业务域的 DTO 变化节奏不同，直接在 Page 或 GetxController 中调用
HTTP 会使鉴权、错误处理和接口契约快速分散。

## 决策

- 所有 App JSON API 经由 `core/network` 的 GetX `GetConnect` 传输和 Feature `data` 层
  Repository 调用；领域层只暴露不可变模型与 `Result`。
- `BaseRemoteRepository` 统一校验 HTTP 响应、`{ code, msg, data }` 包装以及 DTO 格式；仅
  `code == 200` 视为成功。HTTP 或业务 `401` 必须清理本地会话。
- 会话 token、clientId 和到期时间使用 `flutter_secure_storage` 保存；凭证不暴露给
  presentation 或 domain。
- 所有请求写入仅含操作名、方法、路径、状态码、业务码和耗时的有界
  `NetworkRequestMonitor` 历史，禁止记录载荷或凭证。
- 反馈图片预签名 URL 的原始字节 PUT 是唯一例外，使用 `package:http`；原因是 GetConnect 会
  把 `List<int>` 作为 JSON 数据编码。该上传仍使用同一请求监控与 `Result` 错误语义。

## 结果

- 新增或删除 App API 时必须更新操作注册表和契约测试，使其与 OpenAPI 快照保持一致。
- Feature Repository 可以独立演进，不会把接口细节引入页面、Controller 或跨业务的万能工具。
- 调用方获得一致的业务失败、未授权、网络失败和无效数据错误分类。

## 替代方案

- 在 GetxController 中直接调用 GetConnect。
- 每个 Repository 自行解析 HTTP/业务码并管理 token。
- 全部请求改用 `package:http`。
- 使用通用网络封装直接返回动态 JSON。

## 重新评估条件

后端取消统一业务包装、鉴权头契约变更，或团队正式批准另一套网络/错误边界并提供完整迁移与
回归方案时，重新评估本决策。
