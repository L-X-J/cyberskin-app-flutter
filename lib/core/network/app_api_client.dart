// 数据层共享的网络客户端配置与基础 JSON 请求能力。
import 'package:get/get.dart';

/// 供数据层 Repository 共用的 GetX HTTP 客户端。
///
/// 基础地址通过构建参数 `--dart-define=CYBERSKIN_API_BASE_URL=...` 注入，
/// 客户端和展示层均不得硬编码生产环境地址。
final class AppApiClient extends GetConnect {
  /// 创建客户端，并允许显式传入环境基础地址。
  AppApiClient({String? baseUrl}) : _configuredBaseUrl = baseUrl;

  final String? _configuredBaseUrl;

  @override
  void onInit() {
    super.onInit();
    final baseUrl =
        _configuredBaseUrl ??
        const String.fromEnvironment('CYBERSKIN_API_BASE_URL');
    if (baseUrl.isNotEmpty) {
      httpClient.baseUrl = baseUrl;
    }
    httpClient.timeout = const Duration(seconds: 15);
    httpClient.defaultContentType = 'application/json; charset=utf-8';
  }

  /// 通过 GetConnect 执行带泛型返回类型的 JSON GET 请求。
  Future<Response<T>> getJson<T>(String path, {Map<String, dynamic>? query}) =>
      get<T>(path, query: query);

  /// 通过 GetConnect 执行带泛型返回类型的 JSON POST 请求。
  Future<Response<T>> postJson<T>(String path, Object? body) =>
      post<T>(path, body);
}
