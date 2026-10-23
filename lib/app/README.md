# app 目录

应用组装层，负责启动根组件、路由注册、依赖注入和所有一级页面共享的应用壳。

- `bindings/`：GetX 应用级与路由级依赖绑定。
- `widgets/`：应用壳层共享组件，例如底部导航和全局控制区域。
- `app_routes.dart`：顶层命名路由表。
- `floating_control_controller.dart`：应用级悬浮控件的路由策略、几何边界和会话内拖动位置。
- `/home` 是匿名可浏览主页；`/profile` 通过统一认证 Middleware 保护，`/login` 是认证入口。
- `app_route_logger.dart`：将命名路由变化适配到统一日志边界，不持久化路由参数。
- `init_route_transition.dart`：初始化页离场、说明书页进入和自由控制页共享标题衔接的路由动画实现。
- `cyberskin_app.dart`：根组件与全局主题、路由、初始绑定的组装入口。

全局设备快捷控件只挂载一次：路由观察者选择固定、可拖动或隐藏策略，页面壳报告可用内容区域，控制器约束位置，悬浮宿主读取设备会话状态并转发操作。首页重置拖动位置；未登记页面及模态路由默认隐藏。

此目录可以引用具体 Feature 实现进行装配，但不得承载 Feature 业务规则或数据访问逻辑。

- `app_route_visibility.dart`：页面可见性观察器，只发布当前顶层页面，不承载业务导航。
- `route_auth_middleware.dart`：应用命名路由的集中认证保护。
- `playback_session_notifier.dart`：订阅公共播放引擎快照，通过 `cyberskin/now_playing` 通道驱动 iOS Live Activity（灵动岛 + 锁屏）和 Android MediaStyle 通知；不持有设备或业务状态。
