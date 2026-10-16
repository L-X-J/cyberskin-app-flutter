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
                    id: _positive(item, 'id'),
                    titleEn: ApiJson.requiredString(item, 'titleEn'),
                    coverUrl: _httpUrl(item, 'coverUrl'),
                    videoUrl: _httpUrl(item, 'videoUrl'),
                    durationSeconds: _positive(item, 'durationSec'),
                    sort: ApiJson.integer(item, 'sort'),
                    videoWidth: _positive(item, 'videoWidth'),
                    videoHeight: _positive(item, 'videoHeight'),
                    videoCoverWidth: _positive(item, 'videoCoverWidth'),
                    videoCoverHeight: _positive(item, 'videoCoverHeight'),
                  ),
                )
                .toList(growable: false),
    );
  }

  /// 上架内容必须带正数尺寸，避免用猜测比例掩盖服务端契约缺失。
  int _positive(Map<String, dynamic> json, String key) {
    final value = ApiJson.requiredInteger(json, key);
    if (value <= 0) throw FormatException('$key must be positive.');
    return value;
  }

  /// 播放元数据必须一次提供可用网络地址，不以占位资源掩盖错误数据。
  String _httpUrl(Map<String, dynamic> json, String key) {
    final value = ApiJson.requiredString(json, key);
    final uri = Uri.tryParse(value);
    if (uri == null || !['http', 'https'].contains(uri.scheme) || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
      throw FormatException('$key must be an HTTP(S) URL.');
    }
    return value;
  }
}
