# rhythm/domain/entities 目录

包含用户节奏与开放片段协议模型。

片段当前同时兼容扁平通道字段和历史 `channels` 包装，因此在执行前保持不可变原始 JSON；
真正的硬件指令解释仍归协议/控制数据边界。

文件职责：

- `rhythm.dart`：定义不可变的 `Rhythm` 节奏模型和保留开放 JSON 的 `RhythmSegment` 值对象。
