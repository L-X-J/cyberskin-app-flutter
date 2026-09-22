# training/data 目录

`training_remote_repository.dart` 实现已发布课程列表与详情查询。

后续本地缓存、进度记录和设备执行 Adapter 仍归此层。该层负责数据转换与失败映射，不得
承载课程调度规则或 UI 状态。
