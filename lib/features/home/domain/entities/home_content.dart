// 首页一次聚合请求的不可变内容模型。
import '../../../content/domain/entities/app_content.dart';
import '../../../training/domain/entities/training.dart';

/// 首页仅消费课程摘要与广告；完整训练程序由详情请求加载。
final class HomeContent {
  /// 创建首页课程摘要与广告的不可变聚合。的实例。
  HomeContent({
    required Iterable<TrainingSummary> trainings,
    required Iterable<AppAdvertisement> advertisements,
  }) : trainings = List.unmodifiable(trainings),
       advertisements = List.unmodifiable(advertisements);

  /// 已成功加载的课程摘要；刷新失败保留旧数据。
  final List<TrainingSummary> trainings;

  /// 当前有效的广告摘要，顺序由服务端确定。
  final List<AppAdvertisement> advertisements;
}
