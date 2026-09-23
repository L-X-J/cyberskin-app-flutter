# content/data 目录

包含 ContentRepository 的 App API 实现、启动配置本地缓存和 JSON 到领域模型的映射。

`content_configuration_cache.dart` 使用 SharedPreferences 保存启动配置和当天刷新日期；
`content_remote_repository.dart` 只在远端成功后覆盖缓存。这里处理 `config`、`cms` 和
`ads` 的传输契约，不得承载初始化页面策略或展示逻辑。

文件职责：

- `content_configuration_cache.dart`：定义启动配置缓存接口，并用 SharedPreferences 保存配置、最近刷新时间和最近启动时间。
- `content_remote_repository.dart`：访问配置、CMS 页面和广告位 API，将响应解码为领域模型，并在配置刷新成功后更新缓存。
