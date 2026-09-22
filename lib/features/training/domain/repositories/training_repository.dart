// 训练课程查询的领域访问抽象。
import '../../../../core/result/result.dart';
import '../entities/training.dart';

/// 训练课程的领域访问入口。
abstract interface class TrainingRepository {
  /// 获取已发布训练课程列表。
  Future<Result<List<TrainingSummary>>> listTrainings();

  /// 获取单个训练课程详情。
  Future<Result<TrainingDetail>> getTraining(int id);
}
