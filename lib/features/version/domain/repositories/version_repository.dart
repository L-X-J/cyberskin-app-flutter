// App 版本检查的领域访问抽象。
import '../../../../core/result/result.dart';
import '../entities/version_check.dart';

/// App 版本检查数据的领域访问入口。
abstract interface class VersionRepository {
  /// 查询指定平台及当前版本的可用升级信息。
  Future<Result<VersionCheck>> check({String? platform, int? versionCode});
}
