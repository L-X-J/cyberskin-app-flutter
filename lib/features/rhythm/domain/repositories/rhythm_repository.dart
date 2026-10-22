// 自定义节奏 CRUD 的领域访问抽象。
import '../../../../core/result/result.dart';
import '../entities/rhythm.dart';

/// 新建节奏请求。
final class RhythmCreateRequest {
  /// 创建节奏新增请求。
  RhythmCreateRequest({
    required this.deviceModelId,
    required this.name,
    required List<RhythmSegment> segments,
  }) : segments = List<RhythmSegment>.unmodifiable(segments);

  /// 适用设备型号主键。
  final int deviceModelId;

  /// 节奏名称。
  final String name;

  /// 最多 30 条片段协议。
  final List<RhythmSegment> segments;
}

/// 更新节奏请求；`null` 字段表示保持原值。
final class RhythmUpdateRequest {
  /// 创建部分更新请求。
  RhythmUpdateRequest({
    this.deviceModelId,
    this.name,
    List<RhythmSegment>? segments,
  }) : segments = segments == null
           ? null
           : List<RhythmSegment>.unmodifiable(segments);

  /// 新的设备型号主键。
  final int? deviceModelId;

  /// 新的节奏名称。
  final String? name;

  /// 新的完整片段列表。
  final List<RhythmSegment>? segments;
}

/// 用户自定义节奏的领域访问入口。
abstract interface class RhythmRepository {
  /// 列出当前用户的节奏元数据、统计和前 3 段快照，可按型号过滤。
  Future<Result<List<Rhythm>>> list({int? deviceModelId});

  /// 获取节奏详情；应用装配的缓存 Repository 同时下载/读取完整 JSON。
  Future<Result<Rhythm>> getById(int id);

  /// 创建一条节奏。
  Future<Result<Rhythm>> create(RhythmCreateRequest request);

  /// 更新一条节奏。
  Future<Result<Rhythm>> update(int id, RhythmUpdateRequest request);

  /// 删除一条节奏。
  Future<Result<void>> delete(int id);
}
