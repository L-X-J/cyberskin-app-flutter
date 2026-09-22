// App 登录凭证的安全持久化边界与 flutter_secure_storage 实现。
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API 鉴权请求所需的不可变凭证集合。
final class SessionCredentials {
  /// 创建会话凭证。
  const SessionCredentials({
    required this.accessToken,
    required this.clientId,
    required this.expiresAt,
  });

  /// 放入 Bearer Authorization 的 Sa-Token。
  final String accessToken;

  /// 后端要求同时发送的 App 客户端标识。
  final String clientId;

  /// 凭证的绝对失效时间。
  final DateTime expiresAt;

  /// 当前凭证是否已失效。
  bool get isExpired => !expiresAt.isAfter(DateTime.now());
}

/// 登录凭证的跨域存取抽象，便于 Repository 测试替换。
abstract interface class SessionCredentialStore {
  /// 读取完整且未过期的会话；无会话或过期时返回 `null`。
  Future<SessionCredentials?> read();

  /// 持久化一组新登录凭证。
  Future<void> save(SessionCredentials credentials);

  /// 删除本地会话，登出和 401 时都必须调用。
  Future<void> clear();
}

/// 通过系统 Keychain/Keystore 持久化登录凭证的默认实现。
final class SecureSessionCredentialStore implements SessionCredentialStore {
  /// 创建安全凭证存储；测试可注入替代 [FlutterSecureStorage]。
  SecureSessionCredentialStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// 安全存储内的 token 键。
  static const String _tokenKey = 'cyberskin.app_api.token';

  /// 安全存储内的 clientId 键。
  static const String _clientIdKey = 'cyberskin.app_api.client_id';

  /// 安全存储内的绝对过期时间键。
  static const String _expiresAtKey = 'cyberskin.app_api.expires_at';

  /// 底层 Keychain/Keystore 访问器；仅由本实现持有，避免凭证泄漏到业务层。
  final FlutterSecureStorage _storage;

  @override
  Future<SessionCredentials?> read() async {
    final values = await _storage.readAll();
    final token = values[_tokenKey];
    final clientId = values[_clientIdKey];
    final expiresAtRaw = values[_expiresAtKey];
    final expiresAt = expiresAtRaw == null
        ? null
        : DateTime.tryParse(expiresAtRaw);
    if (token == null ||
        token.isEmpty ||
        clientId == null ||
        clientId.isEmpty ||
        expiresAt == null) {
      await clear();
      return null;
    }
    final credentials = SessionCredentials(
      accessToken: token,
      clientId: clientId,
      expiresAt: expiresAt.toUtc(),
    );
    if (credentials.isExpired) {
      await clear();
      return null;
    }
    return credentials;
  }

  @override
  Future<void> save(SessionCredentials credentials) async {
    await clear();
    await _storage.write(key: _tokenKey, value: credentials.accessToken);
    await _storage.write(key: _clientIdKey, value: credentials.clientId);
    await _storage.write(
      key: _expiresAtKey,
      value: credentials.expiresAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _clientIdKey);
    await _storage.delete(key: _expiresAtKey);
  }
}
