# rhythm/domain/services

自定义节奏到公共播放领域的适配，不维护第二套计时器或命令队列。

- `rhythm_playback.dart`：保留节奏页面的快照与操作 API；将结构化片段转换为 `DeviceProgram`，委托应用级 `DeviceProgramPlayback` 执行。旧页面操作只影响对应的节奏会话。

公共播放器契约和 Training 接入见 `control/domain/services/README.md`。
