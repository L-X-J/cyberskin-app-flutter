# content/domain/repositories 目录

包含内容查询 Repository 抽象。

接口只暴露领域模型、刷新时间和 `Result`，不暴露 HTTP、GetConnect、SharedPreferences 或
JSON 类型。启动配置的缓存读写由 ContentRepository 统一封装。
