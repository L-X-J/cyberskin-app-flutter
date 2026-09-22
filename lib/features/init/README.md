# init Feature

应用启动初始化业务域，负责在进入主应用前保证启动配置可用，并执行每日后台刷新策略。

初始化页面只依赖 `ContentRepository`，不直接请求 HTTP 或读取本地存储。启动配置缓存仍由
`content/data` 负责；初始化层只编排阻塞、后台刷新和导航。
