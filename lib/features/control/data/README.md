# control/data 目录

自由控制功能的数据层预留目录，当前尚无实现。

后续用于设备控制 Repository、BLE Adapter 和命令执行状态转换。该层负责把领域控制意图
映射为协议命令、处理连接异常并返回统一 `Result`，不得包含页面状态或 Widget 逻辑。
