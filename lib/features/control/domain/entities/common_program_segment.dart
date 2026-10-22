// 通用业务协议定时打点；与 program_data_sample.json 的三字段结构一致。
import '../../../../core/protocol/common_business_command.dart';

/// 节奏与 Training 共享的持久化打点值，不包含设备 BLE 帧或编辑器状态。
final class CommonProgramSegment {
  /// 校验标准时间范围、说明和单行指令，不接受旧 durationSec/channels 数据。
  factory CommonProgramSegment.fromJson(Map<String, dynamic> json) {
    if (json.length != 3 ||
        !json.keys.every(const {'start-end', 'des', 'command_data'}.contains)) {
      throw const FormatException(
        'A segment needs start-end, des and command_data.',
      );
    }
    final range = json['start-end'];
    final description = json['des'];
    final data = json['command_data'];
    if (range is! String ||
        description is! String ||
        data is! String ||
        description.trim().isEmpty ||
        description.length > 1000) {
      throw const FormatException('Invalid program segment fields.');
    }
    final match = RegExp(r'^(\d{2,6}):([0-5]\d)-(\d{2,6}):([0-5]\d)$')
        .firstMatch(range);
    if (match == null) {
      throw const FormatException('Use MM:SS-MM:SS for start-end.');
    }
    final start = int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
    final end = int.parse(match.group(3)!) * 60 + int.parse(match.group(4)!);
    if (end <= start) {
      throw const FormatException('Segment end must follow start.');
    }
    if (data.isEmpty || data.length > 200 || data.contains(RegExp(r'\s'))) {
      throw const FormatException(
        'command_data must be one line without spaces.',
      );
    }
    final command = CommonBusinessCommand.parse(data);
    final seen = <CommonModule>{};
    if (command.instructions.any(
      (instruction) => !seen.add(instruction.module),
    )) {
      throw const FormatException('Duplicate command module.');
    }
    return CommonProgramSegment._(start, end, description, command);
  }

  const CommonProgramSegment._(
    this.startSeconds,
    this.endSeconds,
    this.description,
    this.command,
  );

  /// 时间轴的起始秒数，包含该时点。
  final int startSeconds;

  /// 时间轴的结束秒数，不包含该时点。
  final int endSeconds;

  /// 展示说明，不参与指令解析。
  final String description;

  /// 严格按通用业务协议解析的单条命令。
  final CommonBusinessCommand command;

  /// 当前打点持续秒数。
  int get durationSeconds => endSeconds - startSeconds;

  /// 只输出样例规定的三个字段。
  Map<String, dynamic> toJson() => {
    'start-end': '${formatTime(startSeconds)}-${formatTime(endSeconds)}',
    'des': description,
    'command_data': command.toString(),
  };

  /// 修改前段时长或删除片段后，重建连续时间轴而不修改命令。
  CommonProgramSegment at(int start) => CommonProgramSegment._(
    start,
    start + durationSeconds,
    description,
    command,
  );

  /// 分钟至少两位；长时间轴不丢失百位分钟。
  static String formatTime(int seconds) {
    if (seconds < 0) throw const FormatException('Time cannot be negative.');
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
