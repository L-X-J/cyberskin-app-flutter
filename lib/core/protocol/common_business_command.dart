/// 通用业务协议中与具体设备无关的模块键。
enum CommonModule {
  /// 伸缩通道。
  telescopic('t'),

  /// 振动通道。
  vibration('v'),

  /// 吸附通道。
  suck('s'),

  /// 加热通道。
  heat('h');

  const CommonModule(this.key);

  /// 协议序列化时使用的模块键。
  final String key;

  /// 将协议模块键解析为枚举值。
  static CommonModule fromKey(String key) => switch (key) {
    't' => CommonModule.telescopic,
    'v' => CommonModule.vibration,
    's' => CommonModule.suck,
    'h' => CommonModule.heat,
    _ => throw FormatException('Unknown common module: $key'),
  };
}

/// 通用业务协议中的单条规范化指令。
final class CommonInstruction {
  /// 创建规范化指令。
  const CommonInstruction({
    required this.module,
    required this.value,
    required this.isMode,
  });

  /// 指令目标模块。
  final CommonModule module;

  /// 逻辑操作符或数值。
  final String value;

  /// 在 `CM->` 模式下，[value] 是否为模式编号。
  final bool isMode;

  @override
  String toString() => '${module.key}:$value';
}

/// 已完成解析与校验的通用业务协议命令。
final class CommonBusinessCommand {
  /// 创建已验证的命令对象。
  const CommonBusinessCommand({
    required this.isModeCommand,
    required this.instructions,
  });

  /// 解析单行命令，例如 `t:20|v:+` 或 `CM->t:2|v:3`。
  factory CommonBusinessCommand.parse(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Command cannot be empty');
    }

    final isModeCommand = normalized.startsWith('CM->');
    final body = isModeCommand ? normalized.substring(4) : normalized;
    final tokens = body.split('|');
    if (tokens.any((token) => token.isEmpty)) {
      throw const FormatException('Command contains an empty instruction');
    }

    final instructions = <CommonInstruction>[];
    for (final token in tokens) {
      final separator = token.indexOf(':');
      if (separator <= 0 || separator == token.length - 1) {
        throw FormatException('Invalid instruction: $token');
      }

      final module = CommonModule.fromKey(token.substring(0, separator));
      final value = token.substring(separator + 1);
      _validateValue(module, value, isModeCommand);
      instructions.add(
        CommonInstruction(
          module: module,
          value: value,
          isMode: isModeCommand && int.tryParse(value) != null,
        ),
      );
    }

    return CommonBusinessCommand(
      isModeCommand: isModeCommand,
      instructions: List.unmodifiable(instructions),
    );
  }

  /// 命令是否使用 `CM->` 模式前缀。
  final bool isModeCommand;

  /// 按协议顺序保存且不可变的指令列表。
  final List<CommonInstruction> instructions;

  @override
  String toString() =>
      '${isModeCommand ? 'CM->' : ''}${instructions.join('|')}';

  /// 按模块、命令模式和值类型校验协议约束。
  static void _validateValue(
    CommonModule module,
    String value,
    bool isModeCommand,
  ) {
    final numericValue = int.tryParse(value);
    if (numericValue != null) {
      if (isModeCommand) {
        if (numericValue < 1 || numericValue > 100) {
          throw FormatException('Mode must be between 1 and 100: $value');
        }
        if (module == CommonModule.heat) {
          throw const FormatException('Heat does not support modes');
        }
      } else {
        if (module != CommonModule.telescopic &&
            module != CommonModule.vibration) {
          throw FormatException(
            'Numeric intensity is not supported for ${module.key}',
          );
        }
        if (numericValue < 0 || numericValue > 100) {
          throw FormatException('Intensity must be between 0 and 100: $value');
        }
      }
      return;
    }

    final allowedOperators = switch (module) {
      CommonModule.suck => const {'s', 'o', 'f', 'c', 'u', 'd'},
      CommonModule.heat => const {'o', 'f'},
      CommonModule.telescopic ||
      CommonModule.vibration => const {'+', '-', 's', 'm', 'o', 'f', 'c'},
    };
    if (!allowedOperators.contains(value)) {
      throw FormatException('Unknown operation for ${module.key}: $value');
    }
  }
}
