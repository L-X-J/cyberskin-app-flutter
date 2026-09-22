// 网络请求的轻量状态监控服务，不记录认证头或业务载荷。
import 'package:get/get.dart';

/// 单次网络请求的可安全观测快照。
final class NetworkRequestSnapshot {
  /// 创建请求快照。
  const NetworkRequestSnapshot({
    required this.operation,
    required this.method,
    required this.path,
    required this.startedAt,
    this.completedAt,
    this.httpStatus,
    this.businessCode,
    this.errorMessage,
  });

  /// 调用的稳定操作名。
  final String operation;

  /// HTTP 请求方法。
  final String method;

  /// 不含查询参数及敏感数据的 API 路径。
  final String path;

  /// 请求开始时间。
  final DateTime startedAt;

  /// 请求结束时间；进行中时为 `null`。
  final DateTime? completedAt;

  /// 收到的 HTTP 状态码。
  final int? httpStatus;

  /// 收到的后端业务码。
  final int? businessCode;

  /// 可安全记录的错误摘要；不包含请求体或凭证。
  final String? errorMessage;

  /// 请求耗时；进行中时为 `null`。
  Duration? get duration => completedAt?.difference(startedAt);

  /// 返回合并本次请求结束状态的新快照。
  NetworkRequestSnapshot complete({
    required int? httpStatus,
    required int? businessCode,
    String? errorMessage,
  }) => NetworkRequestSnapshot(
    operation: operation,
    method: method,
    path: path,
    startedAt: startedAt,
    completedAt: DateTime.now(),
    httpStatus: httpStatus,
    businessCode: businessCode,
    errorMessage: errorMessage,
  );
}

/// 给页面、诊断与测试使用的全局请求状态监控服务。
///
/// 该服务只保存固定数量的元数据快照，永不保存 Authorization、clientid、
/// 请求体或响应体，因此可以在开发诊断中安全观察并发、失败和耗时。
final class NetworkRequestMonitor extends GetxService {
  /// 创建请求监控服务。
  NetworkRequestMonitor({this.historyLimit = 50}) : assert(historyLimit > 0);

  /// 内存中最多保留的已完成请求数量。
  final int historyLimit;

  /// 当前进行中的请求数。
  final RxInt activeRequestCount = 0.obs;

  /// 最近开始或完成的请求快照。
  final Rxn<NetworkRequestSnapshot> latestRequest =
      Rxn<NetworkRequestSnapshot>();

  /// 最近完成的请求历史，最新项位于列表首位。
  final RxList<NetworkRequestSnapshot> history = <NetworkRequestSnapshot>[].obs;

  /// 记录请求开始并返回供结束调用的快照令牌。
  NetworkRequestSnapshot start({
    required String operation,
    required String method,
    required String path,
  }) {
    final snapshot = NetworkRequestSnapshot(
      operation: operation,
      method: method,
      path: path,
      startedAt: DateTime.now(),
    );
    activeRequestCount.value++;
    latestRequest.value = snapshot;
    return snapshot;
  }

  /// 完成一条已开始的请求并维护有界历史。
  void finish(
    NetworkRequestSnapshot started, {
    int? httpStatus,
    int? businessCode,
    String? errorMessage,
  }) {
    final completed = started.complete(
      httpStatus: httpStatus,
      businessCode: businessCode,
      errorMessage: errorMessage,
    );
    activeRequestCount.value = (activeRequestCount.value - 1)
        .clamp(0, 1 << 30)
        .toInt();
    latestRequest.value = completed;
    history.insert(0, completed);
    if (history.length > historyLimit) {
      history.removeRange(historyLimit, history.length);
    }
  }
}
