# core/logging 目录

提供跨业务域统一日志边界，封装第三方 `logger` 框架、异步队列文件写入、文件轮转、
API 日志开关、敏感字段脱敏和结构化输出。

- `app_log_configuration.dart`：解析 Debug/Release 模式与 `CYBERSKIN_API_LOG_ENABLED`
  构建参数，决定 API 日志是否同时显示并存储。
- `app_log.dart`：定义业务日志接口、生产文件实现、测试替身以及 API/路由日志格式。
- `log_file_writer.dart`：提供有界队列、串行异步文件写入和按容量轮转。
- `logging.dart`：统一导出应用可使用的日志接口、实现和配置。

边界约束：

- 业务模块只依赖 `AppLog`，禁止直接导入第三方日志框架。
- API 日志必须脱敏 `Authorization`、token、clientId、验证码和个人信息。
- 文件上传或下载只记录方法、脱敏请求头、地址、状态和耗时，禁止记录请求参数、
  二进制载荷或响应载荷。
- `NetworkRequestMonitor` 继续负责 UI 可观察的有界请求状态；本目录不替代其职责。
