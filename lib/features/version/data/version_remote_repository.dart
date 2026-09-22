// App 版本检查 API 的远端 Repository 实现。
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/result/result.dart';
import '../domain/entities/version_check.dart';
import '../domain/repositories/version_repository.dart';

/// VersionRepository 的 App API 实现。
final class VersionRemoteRepository extends BaseRemoteRepository
    implements VersionRepository {
  /// 创建版本检查远端 Repository。
  VersionRemoteRepository({
    required super.transport,
    required super.sessionStore,
  });

  @override
  Future<Result<VersionCheck>> check({String? platform, int? versionCode}) =>
      request<VersionCheck>(
        AppApiOperation.checkVersion,
        queryParameters: <String, Object?>{
          'platform': platform,
          'versionCode': versionCode,
        },
        decode: _decodeVersion,
      );

  /// 解码可为空的发布记录；功能布尔字段缺失时保持 fail-closed 默认值。
  VersionCheck _decodeVersion(Object? data) {
    final json = ApiJson.object(data);
    return VersionCheck(
      platform: ApiJson.string(json, 'platform'),
      versionName: ApiJson.string(json, 'versionName'),
      versionCode: ApiJson.integer(json, 'versionCode'),
      minimumSupportedVersion: ApiJson.integer(json, 'minSupportedVersion'),
      forceUpdate: ApiJson.boolean(json, 'forceUpdate') ?? false,
      releaseNotesEn: ApiJson.string(json, 'releaseNotesEn'),
      packageUrl: ApiJson.string(json, 'packageUrl'),
      publishedAt: _dateTime(ApiJson.string(json, 'publishedAt')),
      hasUpdate: ApiJson.boolean(json, 'hasUpdate') ?? false,
    );
  }

  /// 解码可选 ISO-8601 发布时间，拒绝已经提供但格式错误的值。
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
