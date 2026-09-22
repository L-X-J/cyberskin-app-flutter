// 自定义节奏领域模型与开放片段协议值对象。

/// 一段可前向兼容的节奏控制协议。
///
/// 后端允许当前扁平通道字段和历史 `channels` 嵌套写法，因此只固定传输边界，
/// 由控制协议层在真正执行前解释具体通道语义。
final class RhythmSegment {
  /// 创建节奏片段并冻结其开放协议内容。
  RhythmSegment(Map<String, dynamic> payload)
    : payload = Map<String, dynamic>.unmodifiable(payload);

  /// 后端节奏协议的原始 JSON 对象。
  final Map<String, dynamic> payload;
}

/// 用户保存的一条自定义节奏。
final class Rhythm {
  /// 创建自定义节奏。
  Rhythm({
    this.id,
    this.deviceModelId,
    this.name,
    this.segmentCount,
    List<RhythmSegment> segments = const <RhythmSegment>[],
  }) : segments = List<RhythmSegment>.unmodifiable(segments);

  /// 节奏主键。
  final int? id;

  /// 节奏适用的设备型号主键。
  final int? deviceModelId;

  /// 节奏展示名称。
  final String? name;

  /// 后端统计的片段数。
  final int? segmentCount;

  /// 片段控制协议列表。
  final List<RhythmSegment> segments;
}
