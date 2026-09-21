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
    └── profile/            # 用户资料、隐私、反馈和版本
```

`lib` 下每个目录都提供 `README.md`，用于说明该目录的职责、当前内容和边界；`.dart`
文件的职责及 Dart doc 注释统一使用中文。

每个 Feature 使用：

- `domain`：不可变模型、业务规则、Repository 抽象；不依赖 Flutter 或插件。
- `data`：API、BLE、本地存储和 Repository 实现；负责 IO 与错误转换。
- `presentation`：Page、GetxController、UI 状态；只负责展示、路由和用户事件。

共享状态使用 GetX `GetxController` + `Rx`，依赖由 `Bindings` 注入，路由由 `GetMaterialApp` / `GetPage` 管理，API 客户端使用 GetX `GetConnect`。`Obx` 必须尽量贴近实际变化的组件，避免整页重建。

数据向下流动：`Repository -> GetxController -> View`。事件向上流动：`View -> GetxController -> Repository`。完整约束见 `AGENTS.md`。

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
