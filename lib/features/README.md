# features 目录

按业务域组织的功能模块根目录。

每个 Feature 遵循统一分层：

- `domain/`：不可变模型、业务规则和 Repository 抽象，不依赖 Flutter 或插件。
- `data/`：远端 API、BLE、本地缓存及 Repository 具体实现，负责 IO 和错误转换。
- `presentation/`：Page、GetxController 和 UI 组件，只处理展示、路由和事件编排。

依赖方向为 `presentation -> domain <- data`。新增功能先定义领域契约，再实现数据源与
展示层，最后由 `app` 组装具体依赖；禁止跨 Feature 直接导入其 `data` 实现。

当前远端 API 按变化原因拆分为 `auth`、`device`、`rhythm`、`training`、`video`、`profile`、
`content`、`feedback`、`version` 和 `init`。`init` 只编排启动配置前置条件，配置缓存仍归
`content/data`；设备远端目录/绑定与本地 BLE 会话 Repository 保持分离。
