# Project Status

Last updated: 2026-10-09

Current Focus: 完成主页与视频页 UI 状态接入；继续接入真实 BLE、播放器和平台 OAuth。

In Progress: 主页已接入设备、型号、训练、广告和视频 Repository 的展示边界，未连接/已连接主页及 Official/Browser/Local 视频 UI 已实现。Google/Apple 入口等待平台插件和控制台配置；悬浮控件和主页内阴影/模糊仍需 iOS/Android 实机或模拟器人工视觉对照。

Recently Completed: 已完成匿名主页、会话资料、认证路由及设备连接状态占位模型。全局悬浮设备快捷控件已完成四态与连接中过渡态、路由策略和拖动边界。主页和视频页复用 Device / Video 导航，主页彩色卡片按设计要求用 Flutter 双层渐变和内阴影绘制，Ardot 设备与视频素材已进入 assets。

Next: 配置真实 Google/Apple 平台插件与后端 OAuth 环境变量；继续实现 BLE 插件、视频播放器/本地选择和后台能力模型。真实联调使用 `CYBERSKIN_LIVE_API_BASE_URL`，不要提交固定服务地址或测试凭证。

Blockers: 真实 BLE/API 集成仍需设备与环境配置；当前机器已发现 iPhone 18 Pro 模拟器，可运行 UI 验证，但不能替代真实硬件联调。

Relevant Files: `AGENTS.md`, `docs/ui/components/floating-device-control.md`, `lib/app/floating_control_controller.dart`, `lib/app/widgets/floating_device_control_overlay.dart`, `lib/features/control/domain/device_quick_control.dart`, `lib/features/control/presentation/widgets/device_control_pill.dart`, `lib/core/theme/app_device_control_style.dart`, `lib/features/auth`, `lib/features/device`。
