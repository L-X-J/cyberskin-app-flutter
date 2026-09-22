// App API 统一响应包装与严格字段解码规则。

/// App 后端统一 `{ code, msg, data }` 响应的不可变包装。
final class ApiEnvelope<T> {
  /// 创建已完成字段解码的响应包装。
  const ApiEnvelope({required this.code, required this.message, this.data});

  /// App 后端约定的成功业务码。
  static const int successCode = 200;

  /// 后端业务状态码。
  final int code;

  /// 后端返回的业务说明；为空时使用空字符串。
  final String message;

  /// 由调用方映射后的业务数据；无数据接口为 `null`。
  final T? data;

  /// 当前响应是否代表业务成功，而非仅 HTTP 成功。
  bool get isSuccess => code == successCode;

  /// 当前响应是否代表业务失败。
  bool get isFailure => !isSuccess;
}
