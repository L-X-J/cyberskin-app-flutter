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

- App 状态使用 GetX `GetxController` + `Rx`；路由和依赖使用 GetX；局部状态使用 `setState`。
- API 请求统一从 GetX `GetConnect` 客户端进入，业务代码仍通过 Repository 访问。
- API 基础地址通过 `--dart-define=CYBERSKIN_API_BASE_URL=...` 注入，不写入源码或文档中的环境常量。
- `Obx` 只包裹最小可变 Widget 子树，避免整页重建。
- Repository 是数据访问单一入口，错误转换为显式结果/领域错误。
- 领域模型不可变；测试文件以 `_test.dart` 结尾。
- 注释描述职责、契约与边界，不逐行复述实现；UI 文案仍以英文为准。
