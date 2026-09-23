# core/result 目录

定义 Repository 边界的显式结果类型。

`result.dart` 使用密封类区分成功值与结构化失败，避免调用方依赖可空值或捕获任意底层
异常。Repository 应将数据源异常转换为 `Result`，控制器只消费统一结果；此目录不负责
日志、重试或 UI 提示。

文件职责：

- `result.dart`：定义 `Result<T>`、`Success<T>` 和 `Failure<T>`，统一表达领域访问成功值或 `AppFailure`。
