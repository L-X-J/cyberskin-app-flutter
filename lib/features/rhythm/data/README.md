# rhythm/data 目录

`rhythm_remote_repository.dart` 实现当前用户节奏的列表、详情、创建、更新和删除 API。

后续本地持久化和设备命令 Adapter 仍在此层实现。该层负责序列化、缓存策略与错误转换，
不得承载节奏编辑规则或页面状态。
