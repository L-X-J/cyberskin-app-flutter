# rhythm

自定义节奏模块：云端 CRUD、会话隔离缓存、能力驱动的片段编辑及跨页面设备执行。

- `data/`：远端 CRUD、安全缓存和共享 BLE/原生后台能力的适配实现。
- `domain/`：不依赖 Flutter 的节奏模型、访问接口与执行状态机。
- `presentation/`：GetX 状态编排与节奏界面，不执行 HTTP、缓存 IO 或 BLE 帧拼接。

入口路由与依赖由 `app/` 组装。界面验收及运行边界见 `docs/ui/pages/rhythm.md`。
