// 将标准打点列表转换为公共播放器输入，节奏与 Training 共用。
import '../../../../core/protocol/common_business_command.dart';
import '../entities/common_program_segment.dart';
import '../entities/device_program.dart';

/// 编译时间轴并投影完整恢复状态；不猜测设备对相对增减的物理步长。
final class CommonProgramCompiler {
  /// 业务层先校验型号能力和段数；此处统一处理时间轴、协议、空档和恢复状态。
  static DeviceProgram compile({
    required String source,
    required int deviceModelId,
    required Iterable<CommonProgramSegment> segments,
    required Iterable<CommonModule> modules,
    String? id,
    String? name,
    String? deviceModelName,
  }) {
    final owned = modules.toSet();
    final modes = <CommonModule, CommonInstruction>{};
    final levels = <CommonModule, CommonInstruction>{
      for (final module in owned)
        module: CommonInstruction(
          module: module,
          value: module == CommonModule.heat ? 'f' : 's',
          isMode: false,
        ),
    };
    final relative = <CommonModule>{};
    final steps = <DeviceProgramStep>[];
    var cursor = 0;
    for (final segment in segments) {
      if (segment.startSeconds < cursor) {
        throw const FormatException(
          'Program segments overlap or are out of order.',
        );
      }
      if (segment.startSeconds > cursor) {
        final stop = DeviceProgram.stopFor(owned);
        steps.add(
          DeviceProgramStep(
            duration: Duration(seconds: segment.startSeconds - cursor),
            commands: [stop],
          ),
        );
        modes.clear();
        relative.clear();
        levels
          ..clear()
          ..addEntries(
            stop.instructions.map((item) => MapEntry(item.module, item)),
          );
      }
      for (final instruction in segment.command.instructions) {
        if (!owned.contains(instruction.module)) {
          throw const FormatException(
            'Program uses an unsupported device module.',
          );
        }
        if (instruction.isMode) {
          modes[instruction.module] = instruction;
          levels.remove(instruction.module);
          relative.remove(instruction.module);
        } else if (const {'+', '-', 'c'}.contains(instruction.value)) {
          // 相对命令仍可执行；未获得明确强度前，不能宣称重连后可无损恢复。
          relative.add(instruction.module);
        } else {
          levels[instruction.module] = instruction;
          relative.remove(instruction.module);
        }
      }
      // 停止通道恢复时不能先重发模式，避免休息段瞬间启动电机。
      final resumeModes = modes.values
          .where(
            (instruction) => !const {
              's',
              'f',
              '0',
            }.contains(levels[instruction.module]?.value),
          )
          .toList();
      steps.add(
        DeviceProgramStep(
          duration: Duration(seconds: segment.durationSeconds),
          commands: [segment.command],
          resumable: relative.isEmpty,
          resumeCommands: [
            if (resumeModes.isNotEmpty)
              CommonBusinessCommand(
                isModeCommand: true,
                instructions: resumeModes,
              ),
            if (levels.isNotEmpty)
              CommonBusinessCommand(
                isModeCommand: false,
                instructions: levels.values.toList(),
              ),
          ],
        ),
      );
      cursor = segment.endSeconds;
    }
    return DeviceProgram(
      source: source,
      id: id,
      name: name,
      deviceModelId: deviceModelId,
      deviceModelName: deviceModelName,
      modules: owned,
      steps: steps,
    );
  }
}
