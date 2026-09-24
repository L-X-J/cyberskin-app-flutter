# Project Status

Last updated: 2026-09-24

Current Focus: 维护 App API 数据层边界，并在后续 Feature 的 GetxController 中按需接入 Repository；统一日志基础能力已接入启动、网络和路由。

In Progress: App OpenAPI 的 29 个操作已完成 GetConnect/Repository 实现，并通过 `test/features/api/repository_live_api_test.dart` 对本机 `http://192.168.1.11:8090` 完成真实链路验证；新增 `init` 首屏，实现启动配置缓存、每日阻塞/后台刷新策略。

Recently Completed: 已读取 PRD、BLE 协议、通用业务协议；已确认 FVM 版本为 Flutter 3.47.5；完成 GetX 路由、Bindings、GetxController、GetConnect 入口和首批测试；为 `lib` 下目录建立职责 README；已接入 App 分组的 OpenAPI 3.1 静态快照，并实现 29 个 App API 的 Feature Repository、统一 `{code,msg,data}` 包装、兼容布尔解码、安全会话存储、401 清理和无敏感请求状态监控。新增 `core/logging` 统一日志、API/路由接入、脱敏、异步文件队列和轮转；相关定向测试通过。实现细节见 `docs/adr/ADR-004-app-api-data-boundary.md` 与 `docs/adr/ADR-005-unified-logging.md`。

Next: 在登录、资料、设备目录、节奏、内容、反馈、训练、视频和版本页面的 GetxController 中，按产品流程注入对应 Repository；继续实现 BLE 插件、本地缓存和后台能力模型。真实联调使用 `CYBERSKIN_LIVE_API_BASE_URL`，不要提交固定服务地址或测试凭证。若新增下载链路，必须沿用文件传输日志约束。

Blockers: 集成测试入口已准备完成，但当前机器没有可用 iOS/Android 设备；Flutter 只发现不受项目支持的 macOS 和 Chrome 目标。

Relevant Files: `AGENTS.md`, `README.md`, `docs/openapi/README.md`, `docs/openapi/app-openapi.json`, `docs/adr/ADR-004-app-api-data-boundary.md`, `lib/app/bindings/app_binding.dart`, `lib/core/network`, `lib/core/storage`, `lib/features/auth`, `lib/features/content`, `lib/features/device`, `lib/features/feedback`, `lib/features/profile`, `lib/features/rhythm`, `lib/features/training`, `lib/features/version`, `lib/features/video`。
