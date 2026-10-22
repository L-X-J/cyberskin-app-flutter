// 节奏缓存保存在安全存储中，以登录会话隔离，避免跨账号读取。
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/storage/session_credential_store.dart';

/// 安全存储中的会话隔离缓存；登录变化后旧缓存不可见。
final class RhythmLocalStore {
  /// 创建实例；依赖及初始状态由调用方提供。
  RhythmLocalStore(this.credentials, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  /// 用于检查请求前后登录身份是否发生变化。
  final SessionCredentialStore credentials;
  final FlutterSecureStorage _storage;

  /// 读取当前会话身份；只允许安全存储内部使用，不写日志。
  Future<String?> owner() async {
    try {
      return (await credentials.read())?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// 仅返回匹配当前会话的缓存，损坏或身份不符时视为未命中。
  Future<Object?> read(String key, String? owner) async {
    if (owner == null || await this.owner() != owner) return null;
    try {
      final text = await _storage.read(key: 'cyberskin.rhythm.program_v3.$key');
      if (text == null) return null;
      final json = jsonDecode(text) as Map;
      if (await this.owner() != owner) return null;
      return json['owner'] == owner ? json['data'] : null;
    } catch (_) {
      return null;
    }
  }

  /// 仅在原请求所属会话仍有效时缓存，缓存失败不覆盖远端成功。
  Future<void> write(String key, String? owner, Object data) async {
    if (owner == null || await this.owner() != owner) return;
    try {
      await _storage.write(
        key: 'cyberskin.rhythm.program_v3.$key',
        value: jsonEncode({'owner': owner, 'data': data}),
      );
    } catch (_) {
      /* 缓存失败不能把已经成功的云端写入报告为失败。 */
    }
  }
}
