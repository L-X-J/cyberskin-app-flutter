// GetConnect 传输适配器，统一装配鉴权头与请求状态监控。
import 'package:http/http.dart' as http;

import '../storage/session_credential_store.dart';
import 'app_api_client.dart';
import 'app_api_operation.dart';
import 'network_request_monitor.dart';

/// 与具体 HTTP 库解耦的原始响应值。
final class ApiRawResponse {
  /// 创建原始 HTTP 响应值。
  const ApiRawResponse({
    required this.statusCode,
    required this.body,
    this.statusText,
  });

  /// HTTP 状态码；连接异常时可为 `null`。
  final int? statusCode;

  /// GetConnect 解码后的响应体。
  final Object? body;

  /// HTTP 客户端提供的状态说明。
  final String? statusText;
}

/// Repository 使用的 HTTP 传输抽象，便于在单元测试中验证请求契约。
abstract interface class ApiTransport {
  /// 发送一个 OpenAPI 已登记的请求。
  Future<ApiRawResponse> send(
    AppApiOperation operation, {
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, Object?> queryParameters = const <String, Object?>{},
    Object? body,
  });
}

/// 生产环境的 GetConnect 传输实现。
final class GetConnectApiTransport implements ApiTransport {
  /// 创建 GetConnect 传输实现。
  GetConnectApiTransport({
    required this.client,
    required this.credentials,
    required this.monitor,
  });

  /// 已配置基础地址和超时的 GetConnect 客户端。
  final AppApiClient client;

  /// 受保护请求使用的安全会话存储。
  final SessionCredentialStore credentials;

  /// 不记录敏感数据的请求监控服务。
  final NetworkRequestMonitor monitor;

  @override
  Future<ApiRawResponse> send(
    AppApiOperation operation, {
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, Object?> queryParameters = const <String, Object?>{},
    Object? body,
  }) async {
    final spec = AppApiOperations.spec(operation);
    final path = _interpolatePath(spec.path, pathParameters);
    final started = monitor.start(
      operation: operation.name,
      method: spec.method.name.toUpperCase(),
      path: path,
    );
    try {
      final headers = await _headersFor(spec);
      final query = queryParameters.map(
        (key, value) => MapEntry(key, value?.toString()),
      )..removeWhere((_, value) => value == null);
      final response = switch (spec.method) {
        ApiHttpMethod.get => await client.get<dynamic>(
          path,
          query: query,
          headers: headers,
        ),
        ApiHttpMethod.post => await client.post<dynamic>(
          path,
          body,
          headers: headers,
        ),
        ApiHttpMethod.put => await client.put<dynamic>(
          path,
          body,
          headers: headers,
        ),
        ApiHttpMethod.delete => await client.delete<dynamic>(
          path,
          headers: headers,
        ),
      };
      final businessCode = _tryReadBusinessCode(response.body);
      monitor.finish(
        started,
        httpStatus: response.statusCode,
        businessCode: businessCode,
        errorMessage: !response.isOk
            ? response.statusText
            : businessCode != null && businessCode != 200
            ? '业务请求失败。'
            : null,
      );
      return ApiRawResponse(
        statusCode: response.statusCode,
        body: response.body,
        statusText: response.statusText,
      );
    } on Object catch (error) {
      monitor.finish(started, errorMessage: error.toString());
      rethrow;
    }
  }

  /// 对预签名地址使用原始字节 PUT；App JSON API 之外的唯一例外。
  ///
  /// GetConnect 会将 `List<int>` 视作 JSON 数据而非原始对象内容，因此这里使用
  /// `package:http` 保证对象存储收到的是原始字节流。
  Future<http.Response> putBytes(
    String url,
    List<int> bytes, {
    required String contentType,
  }) => http.put(
    Uri.parse(url),
    body: bytes,
    headers: <String, String>{'Content-Type': contentType},
  );

  /// 为受保护操作组装 Bearer token 与 `clientid`；公开操作不读取凭证。
  ///
  /// Repository 已在真正发送前拦截缺失会话。这里保留空头的防御分支，避免直接
  /// 使用传输层的调用方在凭证缺失时构造不完整或伪造的鉴权信息。
  Future<Map<String, String>> _headersFor(AppApiOperationSpec spec) async {
    if (!spec.requiresAuthentication) {
      return const <String, String>{};
    }
    final session = await credentials.read();
    if (session == null) {
      return const <String, String>{};
    }
    return <String, String>{
      'Authorization': 'Bearer ${session.accessToken}',
      'clientid': session.clientId,
    };
  }

  /// 替换 OpenAPI 路径占位符并编码单个参数，拒绝漏传的必填路径参数。
  String _interpolatePath(String path, Map<String, Object?> parameters) {
    return path.replaceAllMapped(RegExp(r'\{([^}]+)\}'), (match) {
      final name = match.group(1)!;
      final value = parameters[name];
      if (value == null) {
        throw ArgumentError.value(parameters, name, '缺少路径参数 $name。');
      }
      return Uri.encodeComponent(value.toString());
    });
  }

  /// 从尚未进入统一响应解析的响应体提取业务码，用于请求监控而非业务决策。
  int? _tryReadBusinessCode(Object? body) {
    if (body is Map) {
      final value = body['code'];
      if (value is int) {
        return value;
      }
      if (value is num && value == value.roundToDouble()) {
        return value.toInt();
      }
      if (value is String) {
        return int.tryParse(value);
      }
    }
    return null;
  }
}
