// 首页聚合接口的传输和 DTO 映射。
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/result/result.dart';
import '../../content/domain/entities/app_content.dart';
import '../../training/data/training_remote_repository.dart';
import '../domain/entities/home_content.dart';
import '../domain/repositories/home_repository.dart';

/// 通过统一响应包装读取首页聚合内容。
final class HomeRemoteRepository extends BaseRemoteRepository
    implements HomeRepository {
  /// 创建通过统一响应包装读取首页聚合内容。的实例。
  HomeRemoteRepository({required super.transport, required super.sessionStore});
  @override
  Future<Result<HomeContent>> getHome({int? deviceModelId}) => request(
    AppApiOperation.home,
    queryParameters: {'deviceModelId': ?deviceModelId},
    decode: (data) {
      final json = ApiJson.object(data);
      return HomeContent(
        trainings: ApiJson.objectList(json['trainings'])
            .map(TrainingRemoteRepository.decodeSummary),
        advertisements: ApiJson.objectList(json['advertisements']).map(
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
        ),
      );
    },
  );
}
