# ADR-001：采用按功能组织的 GetX 分层

状态：Accepted

## 背景

Cyberskin App 同时包含账户、设备、节奏、训练和视频等业务域，设备能力与页面布局还由后台配置驱动。项目会大量使用 AI 编程，需要让每次增量修改都能定位到明确边界。

## 决策

采用 `app / core / features` 顶层结构；每个 Feature 内按 `presentation / domain / data` 分层。GetxController 仅依赖 Domain 中的接口，具体 Repository 和 Service 在 App 组装。

## 结果

- 页面不会直接依赖 HTTP、BLE 或本地存储。
- 新设备通过新增 Adapter 扩展，不修改通用业务协议。
- 领域模型和规则可以脱离 Flutter 做单元测试。
- 结构变化必须同步 `AGENTS.md` 与本 ADR。
