// 自定义节奏领域模型与开放片段协议值对象。

import '../../../control/domain/entities/common_program_segment.dart';

/// 自定义节奏持久化打点，严格沿用公共样例的三个字段。
final class RhythmSegment {
  /// 校验并冻结标准打点，不兼容旧结构。
  RhythmSegment(Map<String, dynamic> payload)
    : program = CommonProgramSegment.fromJson(payload);

  /// 公共协议值对象，训练数据也可转换为同一类型。
  final CommonProgramSegment program;

  /// API / JSON 文件的规范结构，不包含通道编辑草稿。
  Map<String, dynamic> get payload => Map.unmodifiable(program.toJson());
}

/// 用户保存的一条自定义节奏。
final class Rhythm {
  /// 创建自定义节奏。
  Rhythm({
    this.id,
    this.deviceModelId,
    this.name,
    this.segmentCount,
    this.programUrl,
    this.programDownloadUrl,
    this.totalSeconds,
    this.createTime,
    this.deviceModelName,
    List<RhythmSegment> segments = const <RhythmSegment>[],
    List<RhythmSegment>? previewSegments,
  }) : segments = List<RhythmSegment>.unmodifiable(segments),
       previewSegments = List<RhythmSegment>.unmodifiable(
         previewSegments ?? segments.take(3),
       );

  /// 节奏主键。
  final int? id;

  /// 节奏适用的设备型号主键。
  final int? deviceModelId;

  /// 节奏展示名称。
  final String? name;

  /// 创建日期用于列表徽标。
  final DateTime? createTime;

  /// 适用型号名，不依赖设备当前是否绑定。
  final String? deviceModelName;

  /// 后端生成的稳定 JSON 文件地址，也是完整文件的磁盘缓存键。
  final String? programUrl;

  /// 详情接口提供的短时签名下载地址，只在内存使用，不持久化。
  final String? programDownloadUrl;

  /// 数据库保存的前 3 段短快照；与完整播放片段分开，避免误播快照。
  final List<RhythmSegment> previewSegments;

  /// 后端根据打点时间轴派生的总秒数。
  final int? totalSeconds;

  /// 后端统计的片段数。
  final int? segmentCount;

  /// 从完整 JSON 文件解析的播放片段；列表元数据中此字段为空。
  final List<RhythmSegment> segments;

  /// 播放只接受完整程序，不能把前 3 段预览误当作全部内容。
  bool get hasCompleteProgram =>
      segments.isNotEmpty &&
      (segmentCount == null || segmentCount == segments.length);

  /// 完整 JSON 下载成功后装配新的不可变详情，保留原元数据身份。
  Rhythm withProgram(List<RhythmSegment> values) => Rhythm(
    id: id,
    deviceModelId: deviceModelId,
    name: name,
    deviceModelName: deviceModelName,
    createTime: createTime,
    programUrl: programUrl,
    programDownloadUrl: programDownloadUrl,
    segmentCount: segmentCount,
    totalSeconds: totalSeconds,
    previewSegments: previewSegments,
    segments: values,
  );
}
