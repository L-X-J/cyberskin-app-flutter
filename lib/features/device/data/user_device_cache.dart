// 用户绑定设备列表的本地缓存边界与 SharedPreferences 实现。
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/user_device_repository.dart';

/// 用户绑定设备列表的磁盘持久化抽象。
abstract interface class UserDeviceCache {
  /// 读取缓存列表；缺失或损坏时返回 `null`。
  Future<List<UserDevice>?> read();

  /// 覆盖写入最新列表。
  Future<void> write(List<UserDevice> devices);

  /// 清除缓存；注销时由缓存装饰器调用。
  Future<void> clear();
}

/// 使用 SharedPreferences 持久化用户绑定设备列表的默认实现。
final class SharedPreferencesUserDeviceCache implements UserDeviceCache {
  SharedPreferencesUserDeviceCache({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  static const String _key = 'cyberskin.device.user_devices_v1';

  final Future<SharedPreferences> Function() _preferencesLoader;

  @override
  Future<List<UserDevice>?> read() async {
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((item) => _decode(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(List<UserDevice> devices) async {
    final preferences = await _preferencesLoader();
    await preferences.setString(
      _key,
      jsonEncode(devices.map(_encode).toList()),
    );
  }

  @override
  Future<void> clear() async {
    final preferences = await _preferencesLoader();
    await preferences.remove(_key);
  }

  Map<String, Object?> _encode(UserDevice d) => <String, Object?>{
    'id': d.id,
    'deviceModelId': d.deviceModelId,
    'customName': d.customName,
    'boundAt': d.boundAt?.toUtc().toIso8601String(),
    'name': d.modelName,
    'iconUrl': d.iconUrl,
    'hwUid': d.hardwareUid,
  };

  UserDevice _decode(Map<String, dynamic> json) => UserDevice(
    id: _int(json['id']),
    deviceModelId: _int(json['deviceModelId']),
    customName: json['customName'] as String?,
    boundAt: _dateTime(json['boundAt'] as String?),
    modelName: json['name'] as String?,
    iconUrl: json['iconUrl'] as String?,
    hardwareUid: json['hwUid'] as String?,
  );

  int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v');

  DateTime? _dateTime(String? v) =>
      v == null ? null : DateTime.tryParse(v)?.toUtc();
}
