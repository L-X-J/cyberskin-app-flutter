// App 启动配置的本地 JSON 缓存边界与 SharedPreferences 实现。
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_content.dart';

/// 启动配置和当天刷新状态的本地存取抽象。
abstract interface class ContentConfigurationCache {
  /// 读取缓存的启动配置；缺失或损坏时返回 `null`。
  Future<AppConfiguration?> read();

  /// 覆盖写入最新启动配置。
  Future<void> write(AppConfiguration configuration);

  /// 返回本地记录的最后一次成功刷新日期。
  Future<DateTime?> readLastRefreshAt();

  /// 记录一次成功刷新时间。
  Future<void> writeLastRefreshAt(DateTime value);

  /// 读取本地记录的最后一次应用启动日期。
  Future<DateTime?> readLastLaunchAt();

  /// 记录本次应用启动日期，用于区分当天首次和非首次打开。
  Future<void> writeLastLaunchAt(DateTime value);
}

/// 使用 SharedPreferences 保存启动配置的默认实现。
final class SharedPreferencesContentConfigurationCache
    implements ContentConfigurationCache {
  /// 创建配置缓存；测试可注入替代 [SharedPreferences]。
  SharedPreferencesContentConfigurationCache({
    Future<SharedPreferences> Function()? preferencesLoader,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance;

  /// 配置 JSON 缓存键。
  static const String _configurationKey = 'cyberskin.content.app_configuration';

  /// 最后一次成功刷新时间缓存键。
  static const String _lastRefreshAtKey =
      'cyberskin.content.app_configuration_refreshed_at';

  /// 最后一次应用启动日期缓存键。
  static const String _lastLaunchAtKey = 'cyberskin.content.app_last_launch_at';

  final Future<SharedPreferences> Function() _preferencesLoader;

  @override
  Future<AppConfiguration?> read() async {
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(_configurationKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final json = jsonDecode(raw);
      if (json is! Map) {
        return null;
      }
      return _decodeConfiguration(Map<String, dynamic>.from(json));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(AppConfiguration configuration) async {
    final preferences = await _preferencesLoader();
    await preferences.setString(
      _configurationKey,
      jsonEncode(_encodeConfiguration(configuration)),
    );
  }

  @override
  Future<DateTime?> readLastRefreshAt() async {
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(_lastRefreshAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> writeLastRefreshAt(DateTime value) async {
    final preferences = await _preferencesLoader();
    await preferences.setString(
      _lastRefreshAtKey,
      value.toUtc().toIso8601String(),
    );
  }

  @override
  Future<DateTime?> readLastLaunchAt() async {
    final preferences = await _preferencesLoader();
    final raw = preferences.getString(_lastLaunchAtKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  Future<void> writeLastLaunchAt(DateTime value) async {
    final preferences = await _preferencesLoader();
    await preferences.setString(
      _lastLaunchAtKey,
      value.toUtc().toIso8601String(),
    );
  }

  /// 把领域配置编码为稳定的本地 JSON，避免缓存依赖临时 DTO。
  Map<String, Object?> _encodeConfiguration(AppConfiguration configuration) =>
      <String, Object?>{
        'configVersion': configuration.version,
        'agreements': configuration.agreements
            .map(
              (agreement) => <String, Object?>{
                'code': agreement.code,
                'title': agreement.title,
                'contentUrl': agreement.contentUrl,
              },
            )
            .toList(growable: false),
        'features': <String, Object?>{
          'emailLoginEnabled': configuration.features.emailLoginEnabled,
          'appleLoginEnabled': configuration.features.appleLoginEnabled,
          'googleLoginEnabled': configuration.features.googleLoginEnabled,
          'feedbackEnabled': configuration.features.feedbackEnabled,
          'officialVideoEnabled': configuration.features.officialVideoEnabled,
        },
      };

  /// 解码本地缓存；缓存字段均按 fail-closed 规则处理。
  AppConfiguration _decodeConfiguration(Map<String, dynamic> json) {
    final rawAgreements = json['agreements'];
    final rawFeatures = json['features'];
    final agreements = rawAgreements is List<dynamic>
        ? rawAgreements
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (item) => AppAgreement(
                  code: item['code'] as String?,
                  title: item['title'] as String?,
                  contentUrl: item['contentUrl'] as String?,
                ),
              )
              .toList(growable: false)
        : const <AppAgreement>[];
    final features = rawFeatures is Map<dynamic, dynamic>
        ? rawFeatures
        : const <String, dynamic>{};
    return AppConfiguration(
      version: json['configVersion'] as String?,
      agreements: agreements,
      features: AppFeatureFlags(
        emailLoginEnabled: features['emailLoginEnabled'] as bool? ?? false,
        appleLoginEnabled: features['appleLoginEnabled'] as bool? ?? false,
        googleLoginEnabled: features['googleLoginEnabled'] as bool? ?? false,
        feedbackEnabled: features['feedbackEnabled'] as bool? ?? false,
        officialVideoEnabled:
            features['officialVideoEnabled'] as bool? ?? false,
      ),
    );
  }
}
