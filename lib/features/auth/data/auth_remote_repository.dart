// 认证 App API 的 GetConnect Repository 实现与会话持久化。
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/result/result.dart';
import '../../../core/storage/session_credential_store.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

/// AuthRepository 的 App API 实现。
final class AuthRemoteRepository extends BaseRemoteRepository
    implements AuthRepository {
  /// 创建认证远端 Repository。
  AuthRemoteRepository({required super.transport, required super.sessionStore});

  @override
  Future<Result<void>> sendEmailCode(String email) => requestVoid(
    AppApiOperation.sendEmailCode,
    body: <String, Object?>{'email': email},
  );

  @override
  Future<Result<AppUser>> loginWithEmail(EmailLoginRequest request) => _login(
    AppApiOperation.emailLogin,
    <String, Object?>{'email': request.email, 'code': request.code},
  );

  @override
  Future<Result<AppUser>> loginWithGoogle(String idToken) => _login(
    AppApiOperation.googleLogin,
    <String, Object?>{'idToken': idToken},
  );

  @override
  Future<Result<AppUser>> loginWithApple(AppleLoginRequest request) =>
      _login(AppApiOperation.appleLogin, <String, Object?>{
        'identityToken': request.identityToken,
        if (request.email != null) 'email': request.email,
        if (request.fullName != null) 'fullName': request.fullName,
      });

  @override
  Future<Result<AppUser>> currentUser() =>
      request<AppUser>(AppApiOperation.currentUser, decode: _decodeUser);

  @override
  Future<Result<void>> logout() async {
    final result = await requestVoid(AppApiOperation.logout);
    await sessionStore.clear();
    return result;
  }

  /// 调用第三方或邮箱登录接口，并且仅在完整登录响应通过校验后持久化凭证。
  Future<Result<AppUser>> _login(
    AppApiOperation operation,
    Map<String, Object?> body,
  ) async {
    final result = await request<_LoginPayload>(
      operation,
      body: body,
      decode: _decodeLogin,
    );
    if (result case Success<_LoginPayload>(:final value)) {
      await sessionStore.save(value.credentials);
      return Result.ok(value.user);
    }
    return Result.failure(result.failureOrNull!);
  }

  /// 解码登录响应，确保 token、clientId 和有效期完整后才允许保存会话。
  _LoginPayload _decodeLogin(Object? data) {
    final json = ApiJson.object(data);
    final token = ApiJson.requiredString(json, 'token');
    final clientId = ApiJson.requiredString(json, 'clientId');
    return _LoginPayload(
      credentials: SessionCredentials(accessToken: token, clientId: clientId),
      user: _decodeUser(json['user']),
    );
  }

  /// 将用户 JSON 转换为不可变领域模型，兼容后端历史布尔编码。
  AppUser _decodeUser(Object? data) {
    final json = ApiJson.object(data, field: 'user');
    return AppUser(
      id: ApiJson.integer(json, 'id'),
      nickname: ApiJson.string(json, 'nickname'),
      avatarUrl: ApiJson.string(json, 'avatarUrl'),
      email: ApiJson.string(json, 'email'),
      profileCompleted: ApiJson.boolean(json, 'profileCompleted') ?? false,
      status: ApiJson.string(json, 'status'),
      lastLoginAt: _dateTime(ApiJson.string(json, 'lastLoginAt')),
      registerChannel: ApiJson.string(json, 'registerChannel'),
    );
  }

  /// 解码可选 ISO-8601 时间；已提供但无法解析的值属于服务端契约错误。
  DateTime? _dateTime(String? value) {
    if (value == null) {
      return null;
    }
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw const FormatException('日期字段格式无效。');
    }
    return parsed.toUtc();
  }
}

/// 仅在认证数据层传递的登录响应解码结果，隔离令牌不进入 presentation。
final class _LoginPayload {
  /// 创建已验证的登录载荷。
  const _LoginPayload({required this.credentials, required this.user});

  /// 需要安全存储的登录凭证。
  final SessionCredentials credentials;

  /// 可以安全返回给调用方的当前用户。
  final AppUser user;
}
