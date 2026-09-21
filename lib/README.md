# lib 目录

应用源码根目录，采用 `app / core / features` 结构组织 Flutter 客户端。

- `app/`：应用启动、依赖组装、路由和全局页面壳。
- `core/`：跨业务域稳定复用的错误、结果、协议、主题和通用能力。
- `features/`：按业务域拆分的功能模块，每个模块再按 `domain / data / presentation` 分层。

依赖方向以 `presentation -> domain <- data` 为准，具体实现由 `app` 组装；禁止在
展示层直接访问 API、BLE 或持久化。详细架构约束见仓库根目录 `AGENTS.md`。
