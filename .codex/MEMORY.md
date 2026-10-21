# Project Memory

## Project Purpose

Cyberskin App 是面向美国男性用户的英文 Flutter 客户端，连接并控制由后台配置能力模型驱动的 BLE 智能设备，同时提供自定义节奏、训练、视频、账户和反馈功能。

## Architecture

- 使用 `app / core / features` 目录结构。
- Feature 内按 `presentation / domain / data` 分层。
- `presentation -> domain <- data`，具体依赖在 `app` 组装。
- 设备能力模型、控制布局、模式命名和内容由后台驱动；客户端不得写死型号能力。
- 通用业务协议与设备专用 BLE Adapter 分离，BLE 原始帧编解码归 `core/protocol`。

## Important Constraints

- 当前 PRD：`docs/Cyberskin_PRD_v1.1.0.md`。
- 通用 BLE 协议：`docs/BLE协议相关/CYBERSKIN 通用BLE 蓝牙协议.md`。
- 通用业务协议：`docs/BLE协议相关/智能成人设备 BLE 控制器 — 通用业务协议规范.md`。
- App API 静态 OpenAPI：`docs/openapi/app-openapi.json`，对应后端 `App接口` 分组与 `/app/v1/**`；导出工具和更新流程见 `docs/openapi/README.md`。该文件是 SpringDoc 快照，接口真相源仍是后端 Controller、BO、VO 及其注解。
- FVM 版本锁定为 Flutter `3.47.5`（`.fvmrc`）。
- UI 文案以英文为准；项目架构文档和协作规范使用中文。
- UI 实现入口为 `docs/ui/README.md`；设计稿基准与响应式行为需分别验收，视觉 token 的代码真相源为 `lib/core/theme/`。
- 项目 UI 统一使用 Flutter/Material 默认字体，不因 Figma 标注的 MiSans 建立自定义字体依赖；字体差异在视觉验收中记录。
- `lib` 下所有 `.dart` 文件使用中文文件职责注释和中文 Dart doc；所有目录必须提供说明职责与边界的 `README.md`。

## Conventions

- 公共液态玻璃按钮使用 `core/widgets/AppLiquidGlassButton`，基于 `flutter_liquid_glass_plus`。
  `highlighted` 与 `subtle` 对应已确认的双内阴影/单内阴影两款主题；业务页面只选择变体，
  不复制颜色或内阴影绘制。默认 standard 适配滚动表单，premium 仅用于支持 shader 的固定布局。
  tint 背景由变体绘制，`LGButton.custom` 保留玻璃外缘和交互；不要在其子树手绘填充/边框。
  默认 `LiquidGlassSettings` 使用 thickness 30、lightIntensity 0.65，以保证紧凑按钮仍有可见的
  包内轮廓；translucent 变体的填充为 `#1FFFFFFF`，不叠加设计未提供的上缘内高光。登录返回入口
  也必须复用该公共组件。视频页的本地选择/重试入口和资料页的重试/退出入口同样复用
  translucent 变体；认证页的 `Resend code` 保留为无实体背景的文本链接。契约见
  `docs/ui/components/liquid-glass-button.md`。

- 一级 Device / Video 导航与全局设备快捷 pill 由 `AppScaffold` 共同协调：常规宽度并排，
  横向空间或大字体不足时导航移到 pill 上方；页面滚动内容通过
  `AppScaffold.contentBottomPaddingOf` 预留 Dock 和系统底部安全区，背景保持铺满 viewport。

- App 状态使用 GetX `GetxController` + `Rx`；路由和依赖使用 GetX；局部状态使用 `setState`。
- API 请求统一从 GetX `GetConnect` 客户端进入，业务代码仍通过 Repository 访问。
- API 基础地址通过 `--dart-define=CYBERSKIN_API_BASE_URL=...` 注入，不写入源码或文档中的环境常量。
- 统一持久化日志位于 `lib/core/logging`，业务只依赖 `AppLog`；日志文件写入 Application
  Support/logs，使用有界异步队列和 2 MiB 轮转，默认保留 5 个归档文件。Debug 默认打开 API
  日志；Release/Profile 只有 `CYBERSKIN_API_LOG_ENABLED=true` 才打开。
- API 日志会脱敏 Authorization、clientid、token、邮箱、验证码、个人资料和对象存储字段；
  文件上传/下载必须使用文件传输标记，丢弃 URL query、参数和二进制载荷。GetX 命名路由通过
  `routingCallback` 记录前后路由但不记录 arguments。详见 `docs/adr/ADR-005-unified-logging.md`。
- App API 的 29 个 `/app/v1/**` 操作由 `core/network/app_api_operation.dart` 注册并由契约测试
  对照 OpenAPI 快照。`BaseRemoteRepository` 仅将 `{code,msg,data}` 的 `code == 200` 视为成功；
  HTTP 或业务 `401` 会清理安全会话。
- 登录 token、clientId 与到期时间存放于 `flutter_secure_storage`；请求监控只保存操作、方法、
  路径、状态和耗时，不保存载荷或凭证。预签名对象存储原始字节 PUT 是唯一使用 `package:http`
  的网络例外。
- `test/features/api/repository_live_api_test.dart` 在设置 `CYBERSKIN_LIVE_API_BASE_URL` 后执行
  全 Repository 真实请求，默认测试会跳过。开发后端启用 OAuth mock 与邮箱固定码 `123456`；
  测试创建的设备绑定会物理删除，节奏接口为软删除。
- 应用首屏为 `init`：启动时读取 `content` 的本地启动配置缓存。当天首次刷新或无缓存时，
  无缓存必须等待 `AppApiOperation.appConfig` 成功后才能进入设备页；已有配置时立即进入并在
  后台刷新。每次远端成功后由 `ContentRemoteRepository` 覆盖 SharedPreferences 缓存。
- 所有函数都必须有中文 Dart doc；函数内部稍复杂、非显然或有状态/并发/缓存语义的代码块，
  必须补充中文行内注释，说明原因、边界和失败策略，不能只给类或公开方法写注释。
- `Obx` 只包裹最小可变 Widget 子树，避免整页重建。
- 自由控制布局模块的后台存储只有 `type/variant/row/col/order`（WebAdmin `toPersistedLayout`），
  后端读路径不补能力字段；`gearMax` / `modes` 必须由客户端从 `supportedActions` 按类型合并
  （code 别名 `thrust|telescopic`、`vibration|vibrate`、`suck|suction`、`heat|heating`）。
  能力侧 `defaultValue` 是 0–100 逻辑值，不能当作模块档位序号；`gearMax <= 0` 表示不适用。
- 通用业务协议只允许 `t/v` 携带普通数字强度；吮吸模式必须写 `CM->s:N`，`s:N` 会被解析器拒绝。
- Repository 是数据访问单一入口，错误转换为显式结果/领域错误。
- 领域模型不可变；测试文件以 `_test.dart` 结尾。
- 注释描述职责、契约与边界，不逐行复述实现；UI 文案仍以英文为准。
