# rhythm

自定义节奏模块：云端 CRUD、会话隔离缓存、能力驱动的片段编辑及跨页面设备执行。

- `data/`：远端 CRUD、安全缓存和型号能力访问。
- `domain/`：不依赖 Flutter 的节奏模型、访问接口和公共播放适配。
- `presentation/`：GetX 状态编排与节奏界面，不执行 HTTP、缓存 IO 或 BLE 帧拼接。

入口路由与依赖由 `app/` 组装。界面验收及运行边界见 `docs/ui/pages/rhythm.md`。

播放使用 `control/domain/services/DeviceProgramPlayback` 的应用级单例；与 Training 共享执行模型、队列、暂停恢复及设备互斥。两种业务的持久化格式与接入约束见 `control/domain/services/README.md`。

保存格式严格为 `start-end/des/command_data`；后端保存 JSON 文件地址，App 不提交自定义文件 URL。时长/通道只属于编辑草稿。文件写入/读取失败作为保存/加载失败处理。

列表从数据库快照读取前3段及总时长/段数；详情由 Repository 下载完整 JSON 后才进入编辑/播放。公共 `control/data/CommonProgramFileCache` 以稳定URL缓存原文件最长30天，读取不续期，过期不离线降级。
