# training/data 目录

- `training_remote_repository.dart`：列表只读摘要，详情解码文件 URL 与最多 3 段短预览。`loadProgram` 仅在 Start 后调用，共享 `CommonProgramFileCache` 下载/缓存完整 JSON，并核对时间轴、段数和总秒数；错误转换为 Result。业务执行仍由 domain 公共编译器负责。
