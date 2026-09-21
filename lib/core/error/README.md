# core/error 目录

定义可跨 Feature 复用的稳定错误模型。

当前 `app_failure.dart` 提供失败分类和安全错误载体，用于 Repository 向控制器传递统一
错误语义。此目录不解析 HTTP 响应、不转换 BLE 帧，也不包含页面文案策略；各数据源负责
把底层异常映射为这里的领域错误。
