# control/domain/repositories 目录

自由控制领域 Repository 抽象预留目录，当前尚无实现。

当控制数据访问形成稳定契约时在此声明接口。接口只表达领域语义和统一结果，不暴露 HTTP、
BLE 特征值、数据库 API 或具体 Adapter 类型；实现放在 `control/data`。
