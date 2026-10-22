# control/domain/services

跨业务的公共协议播放层，不依赖 Flutter、GetX、Rhythm 或 Training 实体。

- `common_program_compiler.dart`：标准打点时间轴转为 `DeviceProgram`；校验顺序/重叠、停止空档、投影各通道完整恢复状态。
- `device_program_playback.dart`：统一串行发令、单调计时、暂停恢复、编辑互斥、手动接管、断连/心跳中断、账号失效和平台后台资源生命周期。

## 数据与协议边界

保存结构以 `docs/BLE协议相关/program_data_sample.json` 为准，单条只有 `start-end`、`des`、`command_data`。指令语法以《通用业务协议规范》v1.2 为准。

- Rhythm 保存请求的 `segments` 和 JSON 文件都使用标准三字段。后端上传完整 JSON；数据库保存稳定 `program_url`、可信对象定位、前3段 `preview_segments_json` 与总时长/段数。列表不下载文件；详情返回短时签名地址，由 `control/data/CommonProgramFileCache` 下载、解析并缓存最多30天。`CachedRhythmRepository`核对完整文件与统计后才装配播放数据，不把短快照当作完整程序；会话隔离的v3元数据缓存不保存完整内容或签名。
- Training 目前仍在 `published_custom_mode_json` 保存内联 JSON，未在本次迁移范围内。App 的 `TrainingCustomMode.toProgramSegment()` 将其转换为相同的 `CommonProgramSegment`。
- `RhythmStep` 只是编辑器草稿，duration/channel 对象不再进入 API 或数据库；播放直接消费保存的通用指令。具体 BLE 帧仍由 SDK Adapter 生成。

## Training 接入

`AppBinding` 注册唯一的 `DeviceProgramPlayback`。Training 完成型号与模式能力校验后，使用同一实例：

```dart
final program = CommonProgramCompiler.compile(
  source: 'training',
  id: detail.summary.id?.toString(),
  deviceModelId: detail.summary.deviceModelId!,
  name: detail.summary.nameEn,
  modules: supportedModules,
  segments: detail.customModes.map((item) => item.toProgramSegment()),
);
if (await playback.start(program)) {
  final sessionProgram = playback.snapshot.program!;
  await playback.pause(expectedProgram: sessionProgram);
  await playback.resume(expectedProgram: sessionProgram);
  await playback.stop(expectedProgram: sessionProgram);
}
```

- `source + id + deviceModelId` 区分业务记录，未保存的数据按实例身份匹配。页面操作带 `expectedProgram`，防止旧页面的延迟操作影响后来启动的其他会话。
- 每个打点进入时只发一次原始 `command_data`；心跳和倒计时不重复发令。编译器保留之前片段仍启用的状态，恢复时发送完整投影；停止通道不先发模式以免休息段短暂运动。
- 普通数字表示 t/v 的0–100百分比，`CM->` 数字表示1–100模式号；单条同模块不能同时表达模式和数字速度。支持模式与普通操作符混合，例如 `CM->t:2|v:+`。
- 相对 `+/-/c` 可以原样执行。其结果无法由设备无关协议确定，未被后续明确值覆盖时标记 `resumable=false`；暂停/中断后明确提示结束并重启，禁止盲目重放相对操作。若业务已有可信的完整目标状态，可自行构造 `DeviceProgramStep.resumeCommands`，允许安全恢复。
- 公共编译器允许按输入顺序的非重叠区间；空档停止本会话通道。Rhythm 额外要求从00:00连续、1–30段、每段1–1200秒；Training 可保留自己的条数和时间轴限制。
- `modules` 是本会话接管的设备支持模块，必须由型号能力提供。暂停/结束停止这些模块，加热使用 `h:f`。

## 运行边界

会话绑定原物理设备的型号和地址；断连或连续5秒无通知后保留进度，必须显式恢复，不补发挂起期间积压的片段。停止失败不报告已结束。退出账号作废旧队列；编辑期间阻止所有来源恢复和手动控制，离开编辑器不自动续跑。

所有来源共享现有 Android 服务和 iOS BLE background mode。原生通道名 `cyberskin/rhythm_background` 为兼容保留，进程终止后不自动恢复。设备后台连续性需用户手动验证。
