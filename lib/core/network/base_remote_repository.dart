// Repository 共享的 HTTP、统一业务响应与错误映射边界。
import '../error/app_failure.dart';
import '../result/result.dart';
import '../storage/session_credential_store.dart';
import 'api_envelope.dart';
import 'api_transport.dart';
import 'app_api_operation.dart';
import 'json_decoder.dart';

/// Feature 远端 Repository 的统一基类。
///
/// 它只处理稳定的跨域规则：HTTP 状态、`{code,msg,data}`、401 会话失效与
/// DTO 解析错误。路径、请求体与业务 DTO 映射必须留在各 Feature Repository。
abstract base class BaseRemoteRepository {
  /// 创建共享远端 Repository 基类。
  BaseRemoteRepository({required this.transport, required this.sessionStore});

  /// 当前 Repository 使用的可替换 HTTP 传输边界。
  final ApiTransport transport;

  /// 当前 Repository 使用的安全会话存储。
  final SessionCredentialStore sessionStore;

  /// 发起并映射一项有返回数据的 App API 请求。
  Future<Result<T>> request<T>(
    AppApiOperation operation, {
    required T Function(Object? data) decode,
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, Object?> queryParameters = const <String, Object?>{},
    Object? body,
  }) async {
    try {
      if (AppApiOperations.spec(operation).requiresAuthentication &&
          await sessionStore.read() == null) {
        return Result.failure(
          _failure(FailureCode.unauthorized, '尚未登录或登录已失效。'),
        );
      }
      final raw = await transport.send(
        operation,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        body: body,
      );
      if (raw.statusCode == 401) {
        await sessionStore.clear();
        return Result.failure(
          _failure(
            FailureCode.unauthorized,
            raw.statusText ?? '登录已失效。',
            httpStatus: raw.statusCode,
          ),
        );
      }
      ApiEnvelope<Object?> envelope;
      try {
        // 后端错误也可能带有标准 {code,msg,data} 包装；先解析它，
        // 才不会把业务提示丢失为泛化的 HTTP 网络错误。
        envelope = _decodeEnvelope(raw.body);
      } on FormatException {
        if (raw.statusCode == null ||
            raw.statusCode! < 200 ||
            raw.statusCode! >= 300) {
          return Result.failure(
            _failure(
              FailureCode.network,
              _sanitizeNetworkMessage(raw.statusText),
              httpStatus: raw.statusCode,
            ),
          );
        }
        rethrow;
      }
      if (raw.statusCode == null ||
          raw.statusCode! < 200 ||
          raw.statusCode! >= 300) {
        return Result.failure(
          _failure(
            FailureCode.business,
            envelope.message.isEmpty
                ? _sanitizeNetworkMessage(raw.statusText)
                : envelope.message,
            businessCode: envelope.code,
            httpStatus: raw.statusCode,
          ),
        );
      }
      if (envelope.code == 401) {
        await sessionStore.clear();
        return Result.failure(
          _failure(
            FailureCode.unauthorized,
            envelope.message.isEmpty ? '登录已失效。' : envelope.message,
            businessCode: envelope.code,
            httpStatus: raw.statusCode,
          ),
        );
      }
      if (envelope.isFailure) {
        return Result.failure(
          _failure(
            FailureCode.business,
            envelope.message.isEmpty ? '服务端拒绝了本次请求。' : envelope.message,
            businessCode: envelope.code,
            httpStatus: raw.statusCode,
          ),
        );
      }
      return Result.ok(decode(envelope.data));
    } on FormatException catch (error) {
      return Result.failure(
        _failure(FailureCode.invalidData, error.message, cause: error),
      );
    } on ArgumentError catch (error) {
      return Result.failure(
        _failure(
          FailureCode.invalidData,
          error.message?.toString() ?? '请求参数无效。',
          cause: error,
        ),
      );
    } on Object catch (error) {
      return Result.failure(
        _failure(FailureCode.network, '网络请求未能完成。', cause: error),
      );
    }
  }

  /// 发起无业务数据的 App API 请求。
  Future<Result<void>> requestVoid(
    AppApiOperation operation, {
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, Object?> queryParameters = const <String, Object?>{},
    Object? body,
  }) => request<void>(
    operation,
    decode: (_) {},
    pathParameters: pathParameters,
    queryParameters: queryParameters,
    body: body,
  );

  /// 验证并解码后端统一包装；`code` 缺失或类型错误必须视为契约异常。
  ApiEnvelope<Object?> _decodeEnvelope(Object? body) {
    final json = ApiJson.object(body, field: 'App API 响应');
    final code = ApiJson.requiredInteger(json, 'code');
    return ApiEnvelope<Object?>(
      code: code,
      message: ApiJson.string(json, 'msg') ?? '',
      data: json['data'],
    );
  }

  /// 统一创建跨 Feature 可识别的失败值，避免 Repository 泄漏 HTTP/JSON 细节。
  AppFailure _failure(
    FailureCode code,
    String message, {
    int? businessCode,
    int? httpStatus,
    Object? cause,
  }) => AppFailure(
    code: code,
    message: message,
    businessCode: businessCode,
    httpStatus: httpStatus,
    cause: cause,
  );

  /// 将传输层可能泄漏的底层 Raw Exception（如 SocketException）替换为用户可读的网络失败提示。
  String _sanitizeNetworkMessage(String? statusText) {
    if (statusText == null || statusText.trim().isEmpty) {
      return '网络请求失败。';
    }
    final message = statusText.trim();
    if (_isTechnicalException(message)) {
      return '网络请求失败，请检查网络设置。';
    }
    return message;
  }

  bool _isTechnicalException(String text) {
    final lower = text.toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('httpexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('timeoutexception') ||
        lower.contains('clientexception') ||
        lower.contains('formatexception') ||
        lower.contains('os error') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection reset') ||
        lower.contains('network is unreachable');
  }
}
