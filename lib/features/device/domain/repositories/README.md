# device/domain/repositories 目录

设备领域 Repository 抽象预留目录，当前尚无实现。

现有简单契约仍位于 `device_repository.dart`。当设备连接、能力配置和缓存查询分别形成
稳定契约后再迁移或新增文件；接口不得暴露 HTTP、BLE 或数据库类型。
