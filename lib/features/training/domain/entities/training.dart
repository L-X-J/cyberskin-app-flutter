// 训练课程摘要、文件身份、短预览和完整程序的不可变领域模型。
import '../../../control/domain/entities/common_program_segment.dart';

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

  /// 后台发布的强度字符串，范围 1–10。
  final String? intensity;

  /// 服务端排序值。
  final int? sort;

  /// 总时长的分钟展示值，保留非整分钟，不使用示例中的固定时长。
  String get minutesLabel {
    final seconds = totalSeconds;
    if (seconds == null) return '—';
    return seconds % 60 == 0
        ? '${seconds ~/ 60}'
        : (seconds / 60).toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  }

  /// 适用设备型号主键。
  final int? deviceModelId;
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

  /// 转成与自定义节奏完全相同的公共打点值，供 CommonProgramCompiler 使用。
  CommonProgramSegment toProgramSegment() => CommonProgramSegment.fromJson({
    'start-end': range,
    'des': description,
    'command_data': commandData,
  });

  /// 未知扩展字段。
  final Map<String, dynamic> additionalProperties;
}

/// 已发布训练课程详情。
final class TrainingDetail {
  /// 创建训练详情。
  TrainingDetail({
    required this.summary,
    this.purposeSummary,
    this.purposeUrl,
    this.programUrl,
    this.programDownloadUrl,
    List<TrainingCustomMode> previewSegments = const [],
    List<TrainingCustomMode> customModes = const <TrainingCustomMode>[],
  }) : previewSegments = List.unmodifiable(previewSegments),
       customModes = List<TrainingCustomMode>.unmodifiable(customModes);

  /// 共享的课程摘要。
  final TrainingSummary summary;

  /// 已发布课程目的纯文本快照，最多 150 字。
  final String? purposeSummary;

  /// 已发布课程目的 HTML 的公开地址。
  final String? purposeUrl;

  /// 完整程序的稳定文件身份；签名地址刷新不改变缓存键。
  final String? programUrl;

  /// 详情签名地址，只在内存中使用。
  final String? programDownloadUrl;

  /// 至多前 3 段，只用于详情预览，绝不用于播放。
  final List<TrainingCustomMode> previewSegments;

  /// 下载完整 JSON 后装配，保留与文件对应的摘要版本。
  TrainingDetail withProgram(List<TrainingCustomMode> values) => TrainingDetail(
    summary: summary,
    purposeSummary: purposeSummary,
    purposeUrl: purposeUrl,
    programUrl: programUrl,
    programDownloadUrl: programDownloadUrl,
    previewSegments: previewSegments,
    customModes: values,
  );

  /// 仅从完整 JSON 读取的执行片段，详情预览时为空。
  final List<TrainingCustomMode> customModes;
}
