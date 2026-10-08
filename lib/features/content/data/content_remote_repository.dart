// 启动配置、CMS 页面和广告位 App API 的远端 Repository 实现。
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/result/result.dart';
import '../domain/entities/app_content.dart';
import '../domain/repositories/content_repository.dart';
import 'content_configuration_cache.dart';

/// ContentRepository 的 App API 实现。
final class ContentRemoteRepository extends BaseRemoteRepository
    implements ContentRepository {
  /// 创建内容远端 Repository。
  ContentRemoteRepository({
    required super.transport,
    required super.sessionStore,
    required this.configurationCache,
  });

  /// 启动配置的本地缓存，远端成功响应只在此 Repository 边界写入。
  final ContentConfigurationCache configurationCache;

  @override
  Future<AppConfiguration?> readCachedConfiguration() =>
      configurationCache.read();

  @override
  Future<DateTime?> readLastRefreshAt() =>
      configurationCache.readLastRefreshAt();

  @override
  Future<DateTime?> readLastLaunchAt() => configurationCache.readLastLaunchAt();

  @override
  Future<void> writeLastLaunchAt(DateTime value) =>
      configurationCache.writeLastLaunchAt(value);

  @override
  Future<Result<AppConfiguration>> refreshConfiguration() async {
    final result = await request<AppConfiguration>(
      AppApiOperation.appConfig,
      decode: _decodeConfiguration,
    );
    if (result case Success<AppConfiguration>(:final value)) {
      await configurationCache.write(value);
      await configurationCache.writeLastRefreshAt(DateTime.now().toUtc());
    }
    return result;
  }

  @override
  Future<Result<CmsPage>> getCmsPage(String code) => request<CmsPage>(
    AppApiOperation.cmsPage,
    pathParameters: <String, Object?>{'code': code},
    decode: _decodeCmsPage,
  );

  @override
  Future<Result<List<AppAdvertisement>>> listAdvertisements() =>
      request<List<AppAdvertisement>>(
        AppApiOperation.listAds,
        decode: (data) =>
            ApiJson.objectList(data)
                .map(_decodeAdvertisement)
                .toList(growable: false),
      );

  /// 解码启动配置，缺失的功能开关按 fail-closed 规则保持关闭。
  AppConfiguration _decodeConfiguration(Object? data) {
    final json = ApiJson.object(data);
    final agreements = json['agreements'];
    final featureJson = json['features'];
    return AppConfiguration(
      version: ApiJson.string(json, 'configVersion'),
      loggedIn: ApiJson.boolean(json, 'loggedIn') ?? false,
      agreements: agreements == null
          ? const <AppAgreement>[]
          : ApiJson.objectList(agreements, field: 'agreements')
                .map(
                  (item) => AppAgreement(
                    code: ApiJson.string(item, 'code'),
                    title: ApiJson.string(item, 'title'),
                    contentUrl: ApiJson.string(item, 'contentUrl'),
                  ),
                )
                .toList(growable: false),
      features: featureJson == null
          ? const AppFeatureFlags()
          : _decodeFeatures(ApiJson.object(featureJson, field: 'features')),
    );
  }

  /// 统一解码服务端可能返回的布尔兼容值。
  AppFeatureFlags _decodeFeatures(Map<String, dynamic> json) => AppFeatureFlags(
    emailLoginEnabled: ApiJson.boolean(json, 'emailLoginEnabled') ?? false,
    appleLoginEnabled: ApiJson.boolean(json, 'appleLoginEnabled') ?? false,
    googleLoginEnabled: ApiJson.boolean(json, 'googleLoginEnabled') ?? false,
    feedbackEnabled: ApiJson.boolean(json, 'feedbackEnabled') ?? false,
    officialVideoEnabled:
        ApiJson.boolean(json, 'officialVideoEnabled') ?? false,
  );

  /// 解码单个 CMS 页面，保留服务端为旧版本客户端提供的 HTML 回填字段。
  CmsPage _decodeCmsPage(Object? data) {
    final json = ApiJson.object(data);
    return CmsPage(
      id: ApiJson.integer(json, 'id'),
      code: ApiJson.string(json, 'code'),
      titleEn: ApiJson.string(json, 'titleEn'),
      contentUrl: ApiJson.string(json, 'contentUrl'),
      contentHtml: ApiJson.string(json, 'contentHtml'),
    );
  }

  /// 解码广告位的稳定字段；跳转类型保持开放字符串以便后台扩展。
  AppAdvertisement _decodeAdvertisement(Map<String, dynamic> json) =>
      AppAdvertisement(
        id: ApiJson.integer(json, 'id'),
        imageUrl: ApiJson.string(json, 'imageUrl'),
        titleEn: ApiJson.string(json, 'titleEn'),
        subtitleEn: ApiJson.string(json, 'subtitleEn'),
        jumpType: ApiJson.string(json, 'jumpType'),
        jumpTarget: ApiJson.string(json, 'jumpTarget'),
        sort: ApiJson.integer(json, 'sort'),
      );
}
