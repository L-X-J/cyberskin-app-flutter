// 官方视频 App API 的远端 Repository 实现。
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/result/result.dart';
import '../domain/entities/official_video.dart';
import '../domain/repositories/video_repository.dart';

/// VideoRepository 的 App API 实现。
final class VideoRemoteRepository extends BaseRemoteRepository
    implements VideoRepository {
  /// 创建视频远端 Repository。
  VideoRemoteRepository({
    required super.transport,
    required super.sessionStore,
  });

  @override
  Future<Result<OfficialVideoPage>> listOfficialVideos({
    int pageNumber = 1,
    int pageSize = 20,
  }) => request<OfficialVideoPage>(
    AppApiOperation.officialVideos,
    queryParameters: <String, Object?>{
      'pageNum': pageNumber,
      'pageSize': pageSize,
    },
    decode: _decodePage,
  );

  /// 解码官方视频分页包装及其不可变列表。
  OfficialVideoPage _decodePage(Object? data) {
    final json = ApiJson.object(data);
    final rows = json['rows'];
    return OfficialVideoPage(
      total: ApiJson.integer(json, 'total'),
      rows: rows == null
          ? const <OfficialVideo>[]
          : ApiJson.objectList(rows, field: 'rows')
                .map(
                  (item) => OfficialVideo(
                    id: ApiJson.integer(item, 'id'),
                    titleEn: ApiJson.string(item, 'titleEn'),
                    coverUrl: ApiJson.string(item, 'coverUrl'),
                    videoUrl: ApiJson.string(item, 'videoUrl'),
                    durationSeconds: ApiJson.integer(item, 'durationSec'),
                    sort: ApiJson.integer(item, 'sort'),
                  ),
                )
                .toList(growable: false),
    );
  }
}
