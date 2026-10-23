// 弹窗广告远端 Repository：调用 GET /app/v1/ads/popup 并映射为领域实体。
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/result/result.dart';
import '../../../features/content/domain/entities/app_content.dart';
import '../domain/repositories/ad_repository.dart';

/// 通过统一响应包装读取弹窗广告列表。
final class AdRemoteRepository extends BaseRemoteRepository
    implements AdRepository {
  /// 创建弹窗广告远端 Repository 实例。
  AdRemoteRepository({required super.transport, required super.sessionStore});

  @override
  Future<Result<List<AppAdvertisement>>> fetchPopupAds() => request(
    AppApiOperation.popupAds,
    decode: (data) => ApiJson.objectList(data).map(
      (ad) => AppAdvertisement(
        id: ApiJson.integer(ad, 'id'),
        imageUrl: ApiJson.string(ad, 'imageUrl'),
        titleEn: ApiJson.string(ad, 'titleEn'),
        subtitleEn: ApiJson.string(ad, 'subtitleEn'),
        jumpType: ApiJson.string(ad, 'jumpType'),
        jumpTarget: ApiJson.string(ad, 'jumpTarget'),
        sort: ApiJson.integer(ad, 'sort'),
        position: ApiJson.string(ad, 'position'),
      ),
    ).toList(),
  );
}
