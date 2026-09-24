# ADR-005：采用统一异步日志边界

状态：Accepted

## 背景

项目需要同时观察 API 请求、页面路由和普通运行事件，并将日志异步写入设备本地文件。API
日志可能包含凭证、个人信息、预签名 URL 和二进制传输，不能让第三方日志 API 或未经筛选
的 HTTP 对象扩散到 Feature 和 presentation。

## 决策

- 在 `lib/core/logging` 提供 `AppLog` 项目接口，第三方 `logger` 只在该目录内使用。
- 使用 `LogFileWriter` 维护有界队列、串行异步 `IOSink` 写入、2 MiB 文件轮转和最近 5 个归档保留。
- 日志文件写入 Application Support 的 `logs/` 目录；初始化失败降级为控制台输出，不阻塞应用启动。
- Debug 模式默认启用 API 日志；Release/Profile 仅在
  `--dart-define=CYBERSKIN_API_LOG_ENABLED=true` 时启用。启用 API 日志时同时写文件和控制台。
- 每次 API 调用只写一条汇总日志，记录方法、脱敏请求头、地址、参数、响应和耗时。Authorization、clientid、token、
  邮箱、验证码、个人资料和对象存储字段统一脱敏。
- 上传/下载等文件传输必须传入 `isFileTransfer=true`，并移除 URL query、请求参数、请求体和响应体，
  只保留方法、脱敏请求头、清理后的地址、状态和耗时。
- GetX `routingCallback` 记录前后路由、返回方向和路由类型，不记录 arguments；弹窗和 BottomSheet 不作为页面跳转。
- `NetworkRequestMonitor` 继续保存给 UI/诊断使用的有界元数据历史，与持久化日志职责分离。

## 结果

- `app` 负责启动日志并装配到 `AppBinding`；`core/network` 和反馈上传边界统一调用 `AppLog`。
- 日志写入不阻塞请求和路由调用，关闭时等待队列并释放文件句柄。
- 日志脱敏策略和轮转行为可通过纯 Dart/Flutter 测试验证。

## 替代方案

- 直接使用 `logger` 的 `AdvancedFileOutput`：实现简单，但无法清晰表达本项目的有界队列、敏感字段和文件传输契约。
- 使用 `talker`：诊断能力较丰富，但文件异步持久化与轮转仍需自行实现。
- 使用 Dart `logging`：需要完整自建 formatter、sink、轮转和生命周期管理。

## 重新评估条件

需要远程日志采集、崩溃平台集成、用户导出/上传日志或更复杂的隐私分类时，重新评估文件保留、
字段白名单和日志传输策略。
