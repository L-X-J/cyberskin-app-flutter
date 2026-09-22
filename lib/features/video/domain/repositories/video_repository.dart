// 官方视频查询的领域访问抽象。
import '../../../../core/result/result.dart';
import '../entities/official_video.dart';

/// 官方视频数据的领域访问入口。
abstract interface class VideoRepository {
  /// 获取官方视频分页结果。
  Future<Result<OfficialVideoPage>> listOfficialVideos({
    int pageNumber = 1,
    int pageSize = 20,
  });
}
