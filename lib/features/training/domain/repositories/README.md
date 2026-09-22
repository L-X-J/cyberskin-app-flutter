# training/domain/repositories 目录

包含已发布训练课程列表和详情的 Repository 抽象。

后续进度和运行状态可在保持该边界的前提下扩展；接口不暴露 API 响应、数据库记录或设备
命令结构，实现由 `training/data` 提供。
