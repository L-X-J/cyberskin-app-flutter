# control/domain/entities

跨业务控制领域的不可变实体，不依赖 Flutter 或业务持久化 DTO。

- `device_program.dart`：公共 `DeviceProgram` 和 `DeviceProgramStep`；冻结并校验通用指令、持续时间、恢复指令和通道所有权。节奏与 Training 在自己的领域适配为该模型。

- `common_program_segment.dart`：标准 `start-end/des/command_data` 打点解析、严格协议校验、JSON 往返及时间定位，Rhythm 与 Training 共用。
