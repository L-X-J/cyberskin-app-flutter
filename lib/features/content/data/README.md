# content/data 目录

包含 ContentRepository 的 App API 实现、启动配置本地缓存和 JSON 到领域模型的映射。

`content_configuration_cache.dart` 使用 SharedPreferences 保存启动配置和当天刷新日期；
`content_remote_repository.dart` 只在远端成功后覆盖缓存。这里处理 `config`、`cms` 和
`ads` 的传输契约，不得承载初始化页面策略或展示逻辑。
