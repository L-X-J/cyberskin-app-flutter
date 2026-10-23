// 训练执行前的完整性、型号能力和公共协议转换；不依赖 Flutter 或 BLE。
import '../../../../core/protocol/common_business_command.dart';
import '../../../control/domain/entities/device_program.dart';
import '../../../control/domain/services/common_program_compiler.dart';
import '../../../device/domain/repositories/device_catalog_repository.dart';
import '../entities/training.dart';

/// 训练仅执行从完整 JSON 文件加载的标准打点，短预览不能作为执行输入。
abstract final class TrainingProgram {
  /// 校验后冻结公共程序，空档由公共编译器生成停止段。
  static DeviceProgram compile(TrainingDetail detail, DeviceModelDetail model) {
    /// 当前预览课程摘要，首帧可由路由提供。
    final summary = detail.summary;

    /// 本轮列表筛选使用的型号；为空时不限制型号。
    final modelId = summary.deviceModelId;
    if (modelId == null || modelId != model.summary.id) {
      throw const FormatException('Training device model is unavailable.');
    }
    if (summary.id == null ||
        detail.customModes.isEmpty ||
        detail.customModes.length > 200) {
      throw const FormatException(
        'Training needs 1–200 valid segments. Please republish this course.',
      );
    }
    if (int.tryParse(summary.intensity ?? '') case final int intensity
        when intensity >= 1 && intensity <= 10) {
      // 强度只是发布的课程等级，不用于猜测设备速度。
    } else {
      throw const FormatException(
        'Training intensity must be 1–10. Please republish this course.',
      );
    }
    final actions = <CommonModule, Map<String, dynamic>>{};
    for (final action in model.supportedActions) {
      final module = switch ('${action['code']}'.toLowerCase()) {
        'thrust' || 'telescopic' || 't' => CommonModule.telescopic,
        'vibration' || 'vibrate' || 'v' => CommonModule.vibration,
        'suck' || 'suction' || 's' => CommonModule.suck,
        'heat' || 'heating' || 'h' => CommonModule.heat,
        _ => null,
      };
      if (module != null) actions[module] = action;
    }
    if (model.heatSupported) {
      actions.putIfAbsent(CommonModule.heat, () => const {});
    }
    if (actions.isEmpty) {
      throw const FormatException('Device capabilities are unavailable.');
    }
    final segments = detail.customModes
        .map((item) => item.toProgramSegment())
        .toList(growable: false);
    for (final segment in segments) {
      for (final instruction in segment.command.instructions) {
        final action = actions[instruction.module];
        if (action == null) {
          throw const FormatException(
            'Training uses an unsupported device module.',
          );
        }
        final mode = instruction.isMode
            ? int.tryParse(instruction.value)
            : null;
        if (mode != null && mode > ((action['modes'] as List?)?.length ?? 0)) {
          throw const FormatException(
            'A training mode is no longer available. Please republish this course.',
          );
        }
      }
    }
    final program = CommonProgramCompiler.compile(
      source: 'training',
      id: '${summary.id}',
      name: summary.nameEn,
      deviceModelId: modelId,
      deviceModelName: model.summary.name,
      segments: segments,
      modules: actions.keys,
    );

    /// 课程真实总秒数，用于计算统一进度。
    final total = program.steps.fold(
      0,
      (value, step) => value + step.duration.inSeconds,
    );
    if (summary.totalSeconds != total ||
        summary.stageCount != segments.length) {
      throw const FormatException(
        'Training metadata does not match its program. Please republish this course.',
      );
    }
    return program;
  }
}
