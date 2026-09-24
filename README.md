# Cyberskin App

Cyberskin App 是面向 iOS / Android 的 Flutter 客户端。产品需求和设备协议位于 `docs/`，当前实现先提供可运行的应用壳、领域边界和协议基础，后续按业务域接入真实 API、BLE 和本地缓存。

## 开发环境

- Flutter：通过 FVM 固定为 `3.47.5`，见 `.fvmrc`。
- Dart：使用 Flutter 发行版自带 SDK。
- 平台：iOS / Android；UI 文案按 PRD 使用英文。

常用命令：

```bash
fvm flutter pub get
fvm dart format lib test integration_test
fvm flutter analyze
fvm flutter test
```

真实 App API 联调测试默认跳过，避免把 CI 绑定到本地服务；需要验证全部 Repository
请求链路时显式传入联调地址：

```bash
CYBERSKIN_LIVE_API_BASE_URL=http://192.168.1.11:8090 fvm flutter test \
  test/features/api/repository_live_api_test.dart
```

该测试使用开发环境的 mock OAuth fixture 和固定邮箱验证码，并会在结束后清理创建的节奏
与设备绑定。

如果 FVM 报告无法写入安装目录的引擎缓存，先修复本机 FVM 目录权限，再重新执行命令；该错误不应通过修改项目代码绕过。

## 架构

```text
lib/
├── app/                    # 启动、依赖组装、路由、全局壳
├── core/                   # 错误、结果、协议、主题、通用控件
├── README.md               # lib 目录职责与依赖边界
└── features/
    ├── auth/               # 登录与会话
    ├── device/             # 设备列表、能力、连接状态
    ├── control/            # 自由控制与全局运行状态
    ├── rhythm/             # 片段式自定义节奏
    ├── training/           # 训练课程与运行
    ├── video/              # 官方、浏览器、本地视频
    ├── profile/            # 用户资料
    ├── content/            # 启动配置、CMS 页面和广告位
    ├── feedback/           # 用户反馈与预签名附件上传
    ├── version/            # App 版本检查
    └── init/               # 启动配置前置校验与首屏跳转
```

`lib` 下每个目录都提供 `README.md`，用于说明该目录的职责、直接子目录和直接文件；每个
Dart 文件的职责也应在所在目录 README 中列出，`.dart` 文件的职责及 Dart doc 注释统一使用中文。

每个 Feature 使用：

- `domain`：不可变模型、业务规则、Repository 抽象；不依赖 Flutter 或插件。
- `data`：API、BLE、本地存储和 Repository 实现；负责 IO 与错误转换。
- `presentation`：Page、GetxController、UI 状态；只负责展示、路由和用户事件。

GetX 是项目默认的状态管理、依赖注入和路由编排方案：共享状态使用 `GetxController` + 按变化原因拆分的独立 `Rx`，依赖由 `Bindings` 注入，路由由 `GetMaterialApp` / `GetPage` 管理，API 客户端使用 GetX `GetConnect`。`Obx` / `GetX` 应下沉到原子级、实际依赖对应 Rx 的最小组件，只订阅直接需要的字段，避免整页、整列或无关兄弟组件重建；引入其他状态管理或路由方案必须先记录 ADR。

数据向下流动：`Repository -> GetxController -> View`。事件向上流动：`View -> GetxController -> Repository`。完整约束见 `AGENTS.md`。

## App API 文档

App 接口的静态 OpenAPI 3.1 文档位于 [docs/openapi/app-openapi.json](docs/openapi/app-openapi.json)，覆盖后端 `App接口` 分组的 `/app/v1/**` 接口、请求/响应 schema、统一 `{ code, msg, data }` 响应和鉴权声明。导出、更新、鉴权补齐及校验流程见 [docs/openapi/README.md](docs/openapi/README.md)。

该 JSON 是后端 SpringDoc 的导出快照，不是接口定义真相源；契约以 Controller、BO、VO 及其注解为准。当前 29 个 App API 操作均通过 Feature `data` 层的 Repository 访问，基础地址由 `--dart-define=CYBERSKIN_API_BASE_URL=...` 注入，禁止硬编码生产地址或直接在页面调用 API。

共享网络层严格区分 HTTP 状态与业务响应 `code`：仅 `code == 200` 为成功，HTTP 或业务
401 都会清理安全存储中的 token/clientId。请求状态通过 `NetworkRequestMonitor` 以无敏感
数据的有界历史提供给页面或诊断使用。登录凭证使用 `flutter_secure_storage` 保存；预签名
对象存储的原始字节 PUT 是唯一使用 `package:http` 的传输例外。

统一日志由 `core/logging` 提供，使用缓冲文件输出并按大小轮转，默认保留最近 5 个归档文件。
Debug 模式默认显示并写入 API 交互汇总日志；Release 默认关闭，需通过
`--dart-define=CYBERSKIN_API_LOG_ENABLED=true` 显式开启。API 日志对凭证、验证码和个人信息
字段脱敏，文件上传/下载不记录参数和载荷；GetX 命名路由变化也会写入日志。

## UI 设计与响应式规范

涉及页面、组件、主题、字体、素材、布局、响应式或视觉测试的工作，从 [docs/ui/README.md](docs/ui/README.md) 开始。详细实现规则见 [ui-implementation-standard.md](docs/ui/ui-implementation-standard.md)，页面级布局使用 [page-spec-template.md](docs/ui/page-spec-template.md)，交付时按 [visual-acceptance.md](docs/ui/visual-acceptance.md) 验收。

## 协议边界

- `docs/BLE协议相关/智能成人设备 BLE 控制器 — 通用业务协议规范.md` 定义设备无关的 `t/v/s/h` 语义。
- `docs/BLE协议相关/CYBERSKIN 通用BLE 蓝牙协议.md` 定义 BLE UUID、命令字节和校验。
- `lib/core/protocol` 只负责稳定的值对象和帧编解码；具体型号映射放在 Feature 的 `data` 层 Adapter。

## 扩展流程

1. 阅读 PRD、相关协议和 `.codex/` 记忆。
2. 在 Feature 的 `domain` 定义模型、状态和接口。
3. 在 `data` 实现数据源、缓存和设备 Adapter。
4. 在 `presentation` 编写 GetxController 和页面，由 `app` 组装依赖。
5. 为领域规则、状态变化和关键流程添加测试，并运行格式化、分析和测试命令。

禁止在页面中拼接 BLE 指令、调用 API 或读取本地存储；禁止用全局可变单例隐藏依赖；禁止为相似代码创建跨业务域万能工具。
