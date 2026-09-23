# content/domain/repositories 目录

文件职责：

- `content_repository.dart`：定义读取缓存、记录启动/刷新时间、刷新配置、查询 CMS 页面和广告位的领域契约。

包含内容查询 Repository 抽象。

接口只暴露领域模型、刷新时间和 `Result`，不暴露 HTTP、GetConnect、SharedPreferences 或
JSON 类型。启动配置的缓存读写由 ContentRepository 统一封装。
