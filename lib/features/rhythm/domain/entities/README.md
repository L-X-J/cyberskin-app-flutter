# rhythm/domain/entities

不可变节奏快照、片段解析、型号能力及执行前校验。

- `rhythm.dart`：自定义节奏元数据、前3段预览与完整程序片段；分开建模以禁止误播快照，打点严格使用标准三字段。
- `rhythm_program.dart`：编辑器通道草稿、标准打点的编码/反解及连续时间轴重排；App 与后端均支持每段1–1200秒，旧 durationSec/channels 不再持久化。
