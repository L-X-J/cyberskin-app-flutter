# Project Status

Last updated: 2026-09-24

Current Focus: 完成匿名主页、会话状态和受保护路由；继续接入真实 BLE 与平台 OAuth。

In Progress: 登录页面已接入邮箱验证码 Repository；Google/Apple 入口等待平台插件和控制台配置。Flutter 测试 runner 受 FVM 引擎下载/环境限制尚未执行。

Recently Completed: 已完成 `loggedIn` 启动配置字段、公开但可携带会话的配置请求、`/home` 匿名主页、`/login` 邮箱验证码入口、`/profile` 会话资料页、集中认证 Middleware、设备连接状态占位模型和平台配置文档。后端受影响模块 Java 21 构建成功。

Next: 配置真实 Google/Apple 平台插件与后端 OAuth 环境变量；继续实现 BLE 插件、本地缓存和后台能力模型。真实联调使用 `CYBERSKIN_LIVE_API_BASE_URL`，不要提交固定服务地址或测试凭证。

Blockers: 集成测试入口已准备完成，但当前机器没有可用 iOS/Android 设备；Flutter 只发现不受项目支持的 macOS 和 Chrome 目标。

Relevant Files: `AGENTS.md`, `README.md`, `docs/openapi/README.md`, `docs/openapi/app-openapi.json`, `docs/adr/ADR-004-app-api-data-boundary.md`, `lib/app/bindings/app_binding.dart`, `lib/core/network`, `lib/core/storage`, `lib/features/auth`, `lib/features/content`, `lib/features/device`, `lib/features/feedback`, `lib/features/profile`, `lib/features/rhythm`, `lib/features/training`, `lib/features/version`, `lib/features/video`。
