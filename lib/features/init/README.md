# init Feature

应用启动初始化业务域，负责在进入主应用前保证启动配置可用，并执行每日后台刷新策略。

初始化页面只依赖 `ContentRepository`，不直接请求 HTTP 或读取本地存储。启动配置缓存仍由
`content/data` 负责；初始化层只编排阻塞、后台刷新和导航。

目录与文件：

- `domain/`：初始化专属领域契约的预留边界；下含预留的 `repositories/`，当前无 Dart 文件。
- `presentation/`：`InitController` 和 `InitPage`，负责把启动策略转换为 UI 状态和导航；见 `presentation/README.md`。
- 当前 Feature 根目录无 Dart 文件；启动配置模型和缓存属于 `content` Feature。
