# profile/domain/repositories 目录

用户资料 Repository 抽象预留目录，当前尚无实现。

后续接口只描述资料读取、更新和错误语义，不暴露具体 HTTP 路径、存储键或 SDK 类型；
实现由 `profile/data` 提供并由 `app` 完成装配。
