// 首页聚合内容访问边界。
import '../../../../core/result/result.dart';
import '../entities/home_content.dart';

/// 首页内容的领域访问入口。
abstract interface class HomeRepository {
  /// 无型号时查询全部已发布课程；后端负责稳定排序及每类三条限制。
  Future<Result<HomeContent>> getHome({int? deviceModelId});
}
