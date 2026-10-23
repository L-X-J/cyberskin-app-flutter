// 训练课程查询的领域访问抽象。
import '../../../../core/result/result.dart';
import '../entities/training.dart';

/// 训练课程的领域访问入口。
abstract interface class TrainingRepository {
  /// 获取已发布训练课程列表。
  Future<Result<List<TrainingSummary>>> listTrainings({int? deviceModelId});

  /// 获取详情元数据及至多 3 段预览，不下载完整文件。
  Future<Result<TrainingDetail>> getTraining(int id);

  /// 用户打开课程目的时读取公开 HTML，不随详情请求下载正文。
  Future<Result<String>> loadPurpose(String url);

  /// 用户明确 Start 后下载或读取有效文件缓存，绝不把短预览当完整程序。
  Future<Result<TrainingDetail>> loadProgram(TrainingDetail metadata);
}
