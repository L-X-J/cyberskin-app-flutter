# core 目录

跨业务域稳定复用的基础能力目录。

- `error/`：稳定领域错误类型。
- `network/`：网络客户端基础配置。
- `protocol/`：通用业务协议与 BLE 帧值对象。
- `result/`：Repository 边界的显式成功/失败结果。
- `storage/`：本地持久化能力的预留边界。
- `theme/`：应用主题与视觉 token。
- `widgets/`：跨业务域通用组件的预留边界。

`core` 只承载语义稳定、无具体业务编排的能力，禁止演变为万能工具集合。Feature 专属
模型、校验和 IO 逻辑必须保留在对应 Feature 内。
