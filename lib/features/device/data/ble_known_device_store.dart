// BLE 已知物理设备标识的 SharedPreferences 实现。
import 'dart:convert';

import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 使用 SharedPreferences 保存 profile 到 remoteId 的映射。
final class SharedPreferencesKnownDeviceStore implements KnownDeviceStore {
  SharedPreferencesKnownDeviceStore(this._preferences);

  final SharedPreferences _preferences;
  static const String _key = 'cyberskin.ble.known_devices';

  Map<String, List<String>> _readAll() {
    final raw = _preferences.getString(_key);
    if (raw == null) return <String, List<String>>{};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, List<String>>{};
    return decoded.map(
      (key, value) => MapEntry(
        key.toString(),
        value is List
            ? value.map((item) => item.toString()).toList()
            : <String>[],
      ),
    );
  }

  Future<void> _writeAll(Map<String, List<String>> value) =>
      _preferences.setString(_key, jsonEncode(value));

  @override
  Future<Set<String>> readKnownRemoteIds(String profileKey) async =>
      Set<String>.from(_readAll()[profileKey] ?? const <String>[]);

  @override
  Future<void> remember(String profileKey, String remoteId) async {
    final values = _readAll();
    final ids = values.putIfAbsent(profileKey, () => <String>[]);
    if (!ids.contains(remoteId)) ids.add(remoteId);
    await _writeAll(values);
  }

  @override
  Future<void> forget(String profileKey, String remoteId) async {
    final values = _readAll();
    values[profileKey]?.remove(remoteId);
    await _writeAll(values);
  }
}
