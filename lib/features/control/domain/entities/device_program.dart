// 将不同业务的数据统一为不可变的通用业务协议时间序列，不保存 BLE 帧。
import '../../../../core/protocol/common_business_command.dart';

/// 一段持续执行的协议指令；进入与恢复分开，防止重复执行相对增减。
final class DeviceProgramStep {
  /// 冻结并校验命令。含 + / - 时需显式提供不含相对增减的恢复指令。
  ///
  /// commands 只在进入片段时发送一次；resumeCommands 只在暂停或中断后发送。
  /// 未提供恢复指令时，仅允许没有相对增减的命令自动复用。
  /// 恢复指令应覆盖该时点完整的输出状态，包括此前片段仍启用的通道。
  DeviceProgramStep({
    required this.duration,
    required Iterable<CommonBusinessCommand> commands,
    Iterable<CommonBusinessCommand>? resumeCommands,
    this.resumable = true,
  }) : commands = _freezeCommands(commands),
       resumeCommands = _freezeCommands(resumeCommands ?? commands) {
    if (_hasRelativeAdjustment(this.resumeCommands)) {
      throw const FormatException(
        'Relative commands need explicit absolute resume commands.',
      );
    }
    if (duration.inMilliseconds <= 0) {
      throw const FormatException(
        'A playback segment needs a positive duration.',
      );
    }
  }

  /// 是否已具备完整恢复参数；相对命令不能在缺少实际结果时盲目重放。
  final bool resumable;

  /// 当前片段的持续时间，使用单调时钟计时。
  final Duration duration;

  /// 进入本片段时依次发送的通用业务指令。
  final List<CommonBusinessCommand> commands;

  /// 暂停或异常后恢复本片段的完整指令，不重放相对增减。
  final List<CommonBusinessCommand> resumeCommands;

  static bool _hasRelativeAdjustment(List<CommonBusinessCommand> commands) =>
      commands.any(
        (command) => command.instructions.any(
          (instruction) => instruction.value == '+' || instruction.value == '-',
        ),
      );

  static List<CommonBusinessCommand> _freezeCommands(
    Iterable<CommonBusinessCommand> commands,
  ) => List.unmodifiable(
    commands.map((command) {
      // 构造器本身允许未冻结的 instructions；重新解析后才能交给长生命周期会话。
      final parsed = CommonBusinessCommand.parse(command.toString());
      final modules = <CommonModule>{};
      if (parsed.instructions.any(
        (instruction) => !modules.add(instruction.module),
      )) {
        throw const FormatException('A command contains duplicate modules.');
      }
      return parsed;
    }),
  );
}

/// 自定义节奏、训练等业务共用的播放输入；各业务保留自己的持久化 DTO。
final class DeviceProgram {
  /// 创建并校验完整时间序列。业务片段数量、模式可用性由各自适配层校验。
  DeviceProgram({
    required this.source,
    required this.deviceModelId,
    required Iterable<CommonModule> modules,
    required Iterable<DeviceProgramStep> steps,
    this.id,
    this.name,
    this.deviceModelName,
  }) : modules = Set.unmodifiable(modules),
       steps = List.unmodifiable(steps) {
    if (source.isEmpty || this.steps.isEmpty || this.modules.isEmpty) {
      throw const FormatException(
        'A playback program needs a source, modules and segments.',
      );
    }
    for (final step in this.steps) {
      for (final command in [...step.commands, ...step.resumeCommands]) {
        if (command.instructions.any(
          (instruction) => !this.modules.contains(instruction.module),
        )) {
          throw const FormatException(
            'A command uses a module outside this program.',
          );
        }
      }
    }
    stopCommand = stopFor(this.modules);
  }

  /// 来源命名空间，例如 rhythm / training，防止相同数字 ID 串用会话。
  final String source;

  /// 来源业务的主键；草稿为空时只按本实例身份匹配。
  final String? id;

  /// 适用设备型号，执行前必须匹配当前设备。
  final int deviceModelId;

  /// 用户可见的播放名称。
  final String? name;

  /// 适用型号名称，用于不匹配时的提示。
  final String? deviceModelName;

  /// 本会话拥有的通道；暂停、结束时全部停止，加热使用 h:f。
  final Set<CommonModule> modules;

  /// 已校验且冻结的有序片段。
  final List<DeviceProgramStep> steps;

  /// 按本会话通道生成的停止指令，不向设备下发未拥有的通道。
  late final CommonBusinessCommand stopCommand;

  /// 相同业务记录可以返回活动会话；不同来源或型号不得视为同一记录。
  bool matches(DeviceProgram other) =>
      identical(this, other) ||
      (id != null &&
          id == other.id &&
          source == other.source &&
          deviceModelId == other.deviceModelId);

  /// 由调用方提供设备支持的模块，复用协议的停止语义。
  static CommonBusinessCommand stopFor(Iterable<CommonModule> modules) =>
      CommonBusinessCommand.parse(
        modules
            .toSet()
            .map(
              (module) =>
                  '${module.key}:${module == CommonModule.heat ? 'f' : 's'}',
            )
            .join('|'),
      );
}
