# Cyberskin App 工程架构与协作规范

## 项目定位

Cyberskin App 是面向 iOS / Android 的 Flutter 客户端，负责账号、设备连接与控制、自定义节奏、训练、视频和用户资料等能力。动态设备能力、控制布局、模式名称和内容由后台配置驱动。

本文档是本仓库的架构 SSOT。实现与本文档冲突时，先核对 PRD、BLE 协议和现有运行行为，再更新文档或代码；不得静默引入第二套架构。

> Codex 在实质性代码工作前必须读取实际适用的指令链，并严格遵守其中的项目架构约束。

## 分层结构

```text
lib/
├── app/                    # 应用启动、依赖组装、路由和全局壳
├── core/                   # 与业务域无关的错误、结果、协议、主题和通用控件
└── features/<feature>/
    ├── data/               # API/BLE/本地数据源与 Repository 实现
    ├── domain/             # 不依赖 Flutter 的不可变模型、用例和 Repository 抽象
    └── presentation/       # Page、GetxController、UI 状态和交互编排
```

### 模块边界

- `presentation` 只负责展示、路由和把用户事件交给 GetxController；禁止写 HTTP、BLE 帧、持久化或业务规则。
- `GetxController` 负责 UI 状态和用例编排，只依赖 `domain` 中的 Repository / UseCase 抽象。
- `domain` 保存可复用业务规则和不可变模型，不依赖 Flutter、插件或具体网络实现。
- `data` 负责 API、BLE、本地缓存等 IO；Repository 是数据访问的唯一入口。
- `core` 只能承载跨业务域稳定的纯能力，例如 `Result`、错误类型、BLE 帧编解码和主题；禁止变成业务 `utils` 垃圾场。
- 禁止循环依赖。依赖方向只能是 `presentation -> domain <- data`，`app` 负责组装具体实现。

## 状态管理、路由与数据流

- 跨页面或会话状态使用 GetX `GetxController`；依赖通过 `Bindings` 注册，禁止在业务 Widget 中隐式创建全局依赖。
- 页面路由统一使用 `GetMaterialApp`、`GetPage` 和命名路由；页面跳转不直接依赖底层 Navigator 状态。
- API 客户端使用 GetX `GetConnect`，但只能位于 `core/network` 或 Feature 的 `data` 层；业务访问仍必须经过 Repository。
- 局部、短生命周期且不需要跨 Widget 共享的输入状态可以使用 `StatefulWidget` + `setState`。
- 共享状态拆分为多个独立 `Rx` 字段；`Obx` / `GetX` 只包住实际依赖该字段的最小 Widget 子树，禁止用一个大 `Obx` 包整页。
- 数据向下流动：`Repository -> GetxController -> View`；事件向上流动：`View -> GetxController -> Repository`。
- 模型使用不可变对象；更新通过替换 Rx 值或集合实例完成。
- Repository 捕获数据源异常并转换为显式 `Result` / 领域错误；View 不解析底层异常。

## App API 契约与文档

- App API 的接口定义真相源是后端 Controller、请求 BO、响应 VO 及其注解；运行时由 SpringDoc 生成文档。
- [App OpenAPI 静态文档](docs/openapi/README.md) 说明导出、重新生成、鉴权补齐和校验流程；[app-openapi.json](docs/openapi/app-openapi.json) 是 `App接口` 分组、`/app/v1/**` 的 OpenAPI 3.1 导出快照，不是手工维护的接口定义。
- App 契约发生新增、删除或字段/注解/校验变化时，必须按 `docs/openapi/README.md` 重新导出并校验，禁止只改静态 JSON 冒充契约更新。
- 客户端 API 访问必须使用 `core/network` 或 Feature `data` 层的 GetX `GetConnect` 客户端，基础地址由构建参数 `--dart-define=CYBERSKIN_API_BASE_URL=...` 注入；业务请求、响应转换和错误映射仍由 Repository 边界负责。

## UI 设计还原与响应式开发

- 凡涉及页面、组件、主题、字体、素材、布局、响应式或视觉测试的任务，修改前必须阅读 [UI 规范索引](docs/ui/README.md)、[实现规范](docs/ui/ui-implementation-standard.md)，以及目标页面或组件的布局约定。
- 完成 UI 任务后，必须按 [视觉验收规范](docs/ui/visual-acceptance.md) 核验并在交付中报告已验证项、截图位置和未验证项；非 UI 任务无需加载全部 UI 文档。
- 设计稿只定义其基准条件下的视觉结果。实现必须同时满足基准还原和约定的响应式行为；不得通过整页缩放、锁定方向或关闭文字缩放掩盖布局问题。
- 视觉参数的唯一代码真相源是 `lib/core/theme/` 及其后续明确的 token 文件；[设计 token 记录](docs/ui/design-tokens.md) 只记录来源、语义和落地状态，避免维护第二份易漂移的数值表。
- UI 仍遵循既有分层：页面和 Widget 只负责展示与交互，GetxController 编排状态，设备能力、控制布局和 BLE 指令不进入 UI 层。

## Cyberskin 领域约束

- UI 不写死设备型号、功能模块、档位、模式名称或控制页布局；这些信息来自设备能力模型与后台配置。
- 通用业务协议与设备专用 BLE 协议分离。新增设备必须新增 Adapter，不修改通用解析语义。
- BLE 原始帧必须经过协议值对象编解码和校验；禁止在 Widget 或 GetxController 中拼接十六进制字符串。
- 连接状态、运行状态和异常状态使用枚举；禁止用散落字符串表达状态。
- 离线控制和缓存策略属于 Repository / Service 边界，页面只消费统一状态。

## 命名、注释与测试

- 文件名使用 `snake_case.dart`；类型使用 `UpperCamelCase`；变量和方法使用 `lowerCamelCase`。
- `lib` 下所有 `.dart` 文件必须有文件职责注释；注释内容使用中文。对外类型、非显然函数、状态机、协议校验、缓存/重试/并发策略写中文 Dart doc 注释，解释原因、边界和契约，不复述代码。
- `lib` 下每个目录必须提供 `README.md`，说明目录职责、当前内容和边界；新增目录时应同步创建。
- 每个领域规则至少有单元测试；页面交互用 Widget test；跨平台真实 BLE/API 流程用 integration test。
- 测试文件统一放在 `test/` 或 `integration_test/`，命名以 `_test.dart` 结尾。
- 修改完成后至少运行 `dart format`、`flutter analyze` 和相关测试；涉及构建配置时补充 `flutter build` 或平台构建验证。

## 扩展规则

新增功能时按以下顺序：

1. 在 `features/<feature>/domain` 定义模型、状态和接口。
2. 在 `data` 实现远程、本地或 BLE 数据源，再由 Repository 暴露给领域层。
3. 在 `presentation` 定义 GetxController 和页面；通过 `app` 组装依赖。
4. 为领域规则、GetxController 和关键用户流程补测试。
5. 若边界、对外契约或扩展方式变化，同步更新 README、ADR 或 `.codex/` 中的唯一归属文件。

## 禁止事项

- 禁止在 Controller/Page/View 中写业务规则、SQL、HTTP 或 BLE。
- 禁止用全局可变单例隐藏依赖。
- 禁止为减少重复代码创建万能 `utils` 或跨业务域抽象。
- 禁止将后台配置复制成客户端硬编码常量。
- 禁止未经 ADR 记录引入新的状态管理、路由或网络架构。
