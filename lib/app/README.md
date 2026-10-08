# app 目录

应用组装层，负责启动根组件、路由注册、依赖注入和所有一级页面共享的应用壳。

- `bindings/`：GetX 应用级与路由级依赖绑定。
- `widgets/`：应用壳层共享组件，例如底部导航和全局控制区域。
- `app_routes.dart`：顶层命名路由表。
- `/home` 是匿名可浏览主页；`/device` 与 `/profile` 通过统一认证 Middleware 保护，`/login` 是认证入口。
- `app_route_logger.dart`：将命名路由变化适配到统一日志边界，不持久化路由参数。
- `init_route_transition.dart`：初始化页离场和设备页进入的路由动画实现。
- `cyberskin_app.dart`：根组件与全局主题、路由、初始绑定的组装入口。

此目录可以引用具体 Feature 实现进行装配，但不得承载 Feature 业务规则或数据访问逻辑。
