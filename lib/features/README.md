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

Feature 目录职责：

- `auth/`：账号、验证码、第三方登录、当前用户和登出。
- `content/`：启动配置、功能开关、CMS 页面和广告位。
- `control/`：设备运行会话、暂停/继续和全局快捷控制。
- `device/`：设备摘要、能力模型、设备目录、用户绑定和本地会话设备。
- `feedback/`：反馈内容、附件预签名上传和提交确认。
- `init/`：启动时读取配置、决定阻塞或后台刷新，并导航到主应用。
- `profile/`：用户资料查询和更新。
- `rhythm/`：自定义节奏的读取、创建、更新和删除。
- `training/`：已发布训练课程及其详情。
- `version/`：服务端版本检查结果。
- `video/`：官方视频目录，以及后续浏览器/本地视频扩展边界。

Feature 根目录当前不直接放 Dart 文件；实现按三个子目录归属。新增业务时先选择正确
Feature，再按 `domain -> data -> presentation` 的依赖顺序扩展，跨 Feature 只依赖对方的
领域契约，不直接导入对方的 `data` 实现。
