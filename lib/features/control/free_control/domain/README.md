# Free Control Domain

## 目录职责与边界

自由控制的纯领域规则：布局模型解析与模块操作到通用业务协议语义指令的映射。
不依赖 Flutter、GetX、SDK 或网络；指令只产出 `CommonBusinessCommand`，由控制器交给
`DeviceCommandRepository` 下发。

## 目录与文件

- `entities/free_control_layout.dart`：后台布局与模块配置模型。模块缺失 `gearMax` / `modes` 时按
  类型从 `supportedActions` 补齐（后台布局编辑器只持久化 `type/variant/row/col/order`），模块字段优先。
- `free_control_command_mapper.dart`：模块操作 → 语义指令。分档与无级变速共用 `t:` / `v:` 0–100
  逻辑强度（第 N 档 = `round(N / gearMax × 100)`），上报功率按同一比例反算档位；
  吮吸/加热开关为 `s:o|f`、`h:o|f`；吮吸模式为 `CM->s:{下标+1}`（协议不允许普通 `s:{数字}`）。
