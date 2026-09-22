// 训练课程领域模型与开放阶段协议值对象。

/// 已发布训练课程摘要。
final class TrainingSummary {
  /// 创建训练课程摘要。
  const TrainingSummary({
    this.id,
    this.nameEn,
    this.coverUrl,
    this.totalSeconds,
    this.stageCount,
    this.intensity,
    this.sort,
    this.deviceModelId,
  });

  /// 课程主键。
  final int? id;

  /// 英文课程名称。
  final String? nameEn;

  /// 封面地址。
  final String? coverUrl;

  /// 总时长（秒）。
  final int? totalSeconds;

  /// 阶段数量。
  final int? stageCount;

  /// 开放的强度字符串。
  final String? intensity;

  /// 服务端排序值。
  final int? sort;

  /// 适用设备型号主键。
  final int? deviceModelId;
}

/// 一条可前向兼容的训练阶段协议。
final class TrainingStage {
  /// 创建训练阶段并冻结开放协议内容。
  TrainingStage(Map<String, dynamic> payload)
    : payload = Map<String, dynamic>.unmodifiable(payload);

  /// 原始阶段协议 JSON。
  final Map<String, dynamic> payload;
}

/// 一条训练 customMode 的稳定打点数据。
final class TrainingCustomMode {
  /// 创建 customMode 打点，并保留未知字段。
  TrainingCustomMode({
    this.range,
    this.description,
    this.commandData,
    required Map<String, dynamic> additionalProperties,
  }) : additionalProperties = Map<String, dynamic>.unmodifiable(
         additionalProperties,
       );

  /// 协议 `start-end` 字段。
  final String? range;

  /// 协议 `des` 字段。
  final String? description;

  /// 可交由 CommonBusinessCommand 验证的命令文本。
  final String? commandData;

  /// 未知扩展字段。
  final Map<String, dynamic> additionalProperties;
}

/// 已发布训练课程详情。
final class TrainingDetail {
  /// 创建训练详情。
  TrainingDetail({
    required this.summary,
    this.purposeHtml,
    List<TrainingStage> stages = const <TrainingStage>[],
    List<TrainingCustomMode> customModes = const <TrainingCustomMode>[],
  }) : stages = List<TrainingStage>.unmodifiable(stages),
       customModes = List<TrainingCustomMode>.unmodifiable(customModes);

  /// 共享的课程摘要。
  final TrainingSummary summary;

  /// 已发布课程说明 HTML。
  final String? purposeHtml;

  /// 开放的阶段协议列表。
  final List<TrainingStage> stages;

  /// 结构稳定的 customMode 打点列表。
  final List<TrainingCustomMode> customModes;
}
