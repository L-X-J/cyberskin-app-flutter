# rhythm/presentation/pages/info/widgets

详情页计时圆盘与片段叠放卡组；只负责展示，不控制设备。

- `rhythm_timer.dart`：运行页总剩余时间圆盘；计时数据完全由会话提供。
- `rhythm_segment_queue.dart`：按内容自然测高的重叠卡组；480ms 预览提升、旧卡上退淡出与新预览浮现；真实前向推进一次轻触，计时和重启不触发；减少动态效果立即更新。

- `rhythm_info_load_state.dart`：详情JSON/能力准备期间的加载提示及失败后的重试入口。
