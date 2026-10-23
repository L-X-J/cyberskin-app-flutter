// 弹窗广告的 Repository 抽象，供 data 层实现、domain/presentation 层消费。
import '../../../../core/result/result.dart';
import '../../../content/domain/entities/app_content.dart';

/// 弹窗广告数据访问抽象。
abstract interface class AdRepository {
  /// 获取登录后弹窗广告列表（popup_after_login 位，online 且在投放窗口内）。
  Future<Result<List<AppAdvertisement>>> fetchPopupAds();
}
