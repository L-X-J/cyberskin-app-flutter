// 训练路由首帧摘要与入口 Hero 身份，不携带可变播放会话。
import '../domain/entities/training.dart';

/// 详情首帧数据与 Hero 标识；完整程序由 Repository 查询。
final class TrainingRouteArguments {
  /// 创建详情首帧数据与 Hero 标识；完整程序由 Repository 查询。
  const TrainingRouteArguments({this.summary, required this.titleHeroTag});

  /// 当前预览课程摘要，首帧可由路由提供。
  final TrainingSummary? summary;

  /// 从列表或首页传入的标题转场标签。
  final String titleHeroTag;

  /// 为同一课程的不同入口生成独立转场身份。
  static String titleTag(String entry, int? id) => 'training-title:$entry:$id';

  /// 首页 Training mode 标题到训练列表的转场身份。
  static const headingHeroTag = 'training-heading:home';
}
