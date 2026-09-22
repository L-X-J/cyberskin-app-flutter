// 启动配置、CMS 页面和广告位查询的领域访问抽象。
import '../../../../core/result/result.dart';
import '../entities/app_content.dart';

/// 内容与启动配置数据的领域访问入口。
abstract interface class ContentRepository {
  /// 读取本地缓存的启动配置；没有有效缓存时返回 `null`。
  Future<AppConfiguration?> readCachedConfiguration();

  /// 返回本地记录的最后一次成功刷新日期。
  Future<DateTime?> readLastRefreshAt();

  /// 读取本地记录的最后一次应用启动时间。
  Future<DateTime?> readLastLaunchAt();

  /// 记录本次应用启动时间。
  Future<void> writeLastLaunchAt(DateTime value);

  /// 请求远端启动配置，并在成功后覆盖本地缓存。
  Future<Result<AppConfiguration>> refreshConfiguration();

  /// 按页面代码获取一个 CMS 页面。
  Future<Result<CmsPage>> getCmsPage(String code);

  /// 获取在线广告位列表。
  Future<Result<List<AppAdvertisement>>> listAdvertisements();
}
