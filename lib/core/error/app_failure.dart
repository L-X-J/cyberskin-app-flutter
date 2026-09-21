/// 应用稳定失败类型：用于 Repository 与视图模型之间传递可识别错误。
enum FailureCode {
  /// 远程或本地数据源不可访问。
  network,

  /// 响应或持久化数据不符合约定契约。
  invalidData,

  /// 当前设备不支持请求的能力。
  unsupported,

  /// 命令或业务流程执行期间 BLE 会话中断。
  sessionLost,

  /// 无法归入更具体分类的失败。
  unknown,
}

/// 含稳定错误码、可安全展示消息和可选原始原因的异常。
final class AppFailure implements Exception {
  /// 创建应用失败对象。
  const AppFailure({required this.code, required this.message, this.cause});

  /// 供 UI 和遥测映射使用的稳定分类。
  final FailureCode code;

  /// 可安全展示给用户或写入日志的失败描述。
  final String message;

  /// 导致该失败的原始异常，可为空。
  final Object? cause;

  @override
  String toString() => 'AppFailure(${code.name}): $message';
}
