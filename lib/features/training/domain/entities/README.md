# training/domain/entities 目录

- `training.dart`：不可变课程摘要、文件身份、详情短预览及完整 JSON 打点。`previewSegments` 至多三段且与下载后的 `customModes` 分离，不能用于完整播放；`TrainingCustomMode.toProgramSegment()` 对接公共协议与编译器。不再读取 stages 旧格式。
