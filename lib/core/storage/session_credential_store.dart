// App 登录凭证的安全持久化边界与 flutter_secure_storage 实现。
import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API 鉴权请求所需的不可变凭证集合。
final class SessionCredentials {
  /// 创建会话凭证。
  const SessionCredentials({required this.accessToken, required this.clientId});

  /// 放入 Bearer Authorization 的 Sa-Token。
  final String accessToken;

  /// 后端要求同时发送的 App 客户端标识。
  final String clientId;
}

/// 登录凭证的跨域存取抽象，便于 Repository 测试替换。
abstract interface class SessionCredentialStore {
  /// 读取完整且未过期的会话；无会话或过期时返回 `null`。
  Future<SessionCredentials?> read();

  /// 持久化一组新登录凭证。
  Future<void> save(SessionCredentials credentials);

  /// 删除本地会话，登出和 401 时都必须调用。
  Future<void> clear();

  /// 凭证被清空时广播一次；`save` 不触发，用于区分「新登录」与「会话失效」。
  ///
  /// 传输层在 401 时只能看到存储边界，无法感知展示层会话；通过该事件让
  /// 上层把 `authenticated` 收敛为 `anonymous`，避免出现「凭证已删但仍显示
  /// 已登录」的分叉状态。
  Stream<void> get invalidated;
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

  /// 底层 Keychain/Keystore 访问器；仅由本实现持有，避免凭证泄漏到业务层。
  final FlutterSecureStorage _storage;

  /// 失效事件广播器；只承载「凭证被删除」信号，不暴露任何凭证内容。
  final StreamController<void> _invalidations =
      StreamController<void>.broadcast();

  @override
  Stream<void> get invalidated => _invalidations.stream;

  @override
  Future<SessionCredentials?> read() async {
    final values = await _storage.readAll();
    final token = values[_tokenKey];
    final clientId = values[_clientIdKey];
    if (token == null ||
        token.isEmpty ||
        clientId == null ||
        clientId.isEmpty) {
      await clear();
      return null;
    }
    return SessionCredentials(accessToken: token, clientId: clientId);
  }

  @override
  Future<void> save(SessionCredentials credentials) async {
    // 用私有删除避免触发失效事件：登录属于状态建立，不是会话失效。
    await _deleteKeys();
    await _storage.write(key: _tokenKey, value: credentials.accessToken);
    await _storage.write(key: _clientIdKey, value: credentials.clientId);
  }

  @override
  Future<void> clear() async {
    await _deleteKeys();
    if (!_invalidations.isClosed) {
      _invalidations.add(null);
    }
  }

  /// 仅删除底层键值，不广播；供 [save] 与 [clear] 共享。
  Future<void> _deleteKeys() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _clientIdKey);
  }
}
