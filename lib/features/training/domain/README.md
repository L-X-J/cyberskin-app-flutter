# training/domain

- `entities/`：课程摘要与完整详情；customMode 是唯一执行输入。
- `repositories/`：课程列表与详情的显式 Result 边界。
- `services/`：TrainingProgram 校验 200 段上限、能力／模式、时间轴与发布统计，并转换公共程序。

此层不依赖 Flutter、GetX 或 BLE 插件。
