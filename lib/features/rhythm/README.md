# rhythm Feature

片段式自定义节奏业务域，负责节奏定义、编辑、保存和播放编排。

当前目录仅完成分层骨架。领域模型和 Repository 契约进入 `domain/`，API、本地缓存或
BLE 节奏下发进入 `data/`，页面与 Controller 进入 `presentation/`；节奏不得在 UI 中
转换为设备命令。
