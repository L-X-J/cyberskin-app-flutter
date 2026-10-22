# rhythm/domain/entities

不可变节奏快照、片段解析、型号能力及执行前校验。

- `rhythm.dart`：自定义节奏领域模型与开放片段协议值对象。
- `rhythm_program.dart`：节奏片段的类型化解析、设备能力与执行前校验；集中定义客户端 1–1200 整数秒边界，不依赖 Flutter。远端契约同步限制见 `docs/ui/pages/rhythm.md`。
