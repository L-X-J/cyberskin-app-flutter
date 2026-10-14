# Project Status

Last updated: 2026-10-13

Current Focus: 接入真实 BLE、视频播放器/本地选择、平台 OAuth；玻璃与模糊实机光学验收。

In Progress: Google/Apple OAuth 入口等待平台插件和控制台配置；玻璃、内阴影和模糊仍需 iOS/Android 实机光学对照。

Recently Completed: 主页已接入共享 BLE 自动发现、已知设备自动重连、首次发现确认/绑定和连接状态同步；修复 HomeController 加载状态未收敛。修复 AuthSubmitButton AnimatedContainer 有界/无界约束插值崩溃。重构液态玻璃按钮与分层渐变卡片并抽离 GradientStyle token。新增花形加载指示器、玻璃面层与主 Tab 导航，扩展 AppScaffold 布局。拆分主页连接/未连接视图，移除 home_widgets 集中文件。新增设备说明书页面及控制器，扩展设备主页卡片与标签。重构视频页布局，更新路由与资料页入口。优化 BaseRemoteRepository 错误处理与会话凭证存储。全仓库 flutter test 123 项通过，所有变更已按功能分组提交。

Next: 配置真实 Google/Apple 平台插件与后端 OAuth 环境变量；继续实现 BLE 插件、视频播放器/本地选择和后台能力模型。玻璃、模糊、默认字体与 MiSans 的差异仍需 iOS/Android 实机光学验收。真实联调使用 `CYBERSKIN_LIVE_API_BASE_URL`，不要提交固定服务地址或测试凭证。

Blockers: 真实 BLE/API 集成仍需设备与环境配置；当前机器已发现 iPhone 18 Pro 模拟器，可运行 UI 验证，但不能替代真实硬件联调。

Relevant Files: `lib/features/auth/presentation/auth_submit_button.dart`, `lib/app/widgets/`, `lib/core/widgets/`, `lib/features/device/presentation/`, `lib/features/home/presentation/`, `lib/features/video/presentation/`。

## BLE SDK integration (2026-10-12)

Created adjacent `cyberskin-device-sdk` with profile registry, generic/device2/device12/MetaCore/ring/Black Warrior/Explorer profiles, FlutterBluePlus scanning/GATT runtime, known-device persistence boundary, and event stream. Cyberskin maps backend BLE profile data, starts discovery from the home route, auto-reconnects remembered devices, surfaces first discoveries for confirmation, binds confirmed devices through the App API, persists remote IDs, and exposes semantic command Repository. The device route remains a secondary inspection/management entry. Physical-device validation remains outstanding.
