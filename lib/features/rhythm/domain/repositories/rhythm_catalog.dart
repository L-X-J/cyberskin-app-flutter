// 节奏可选择的已绑定型号及其能力访问边界。
import '../../../../core/result/result.dart';
import '../entities/rhythm_program.dart';

/// 已绑定设备去重后的可选择型号。
final class RhythmModel {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmModel(this.id, this.name);

  /// 服务端型号主键。
  final int id;

  /// 用户可见名称。
  final String name;
}

/// 节奏页面使用的型号与能力访问接口。
abstract interface class RhythmCatalog {
  /// 当前账号已绑定型号的可选择列表。
  Future<Result<List<RhythmModel>>> models();

  /// 所选型号支持的通道和模式。
  Future<Result<List<RhythmChannelCapability>>> capabilities(int modelId);
}
