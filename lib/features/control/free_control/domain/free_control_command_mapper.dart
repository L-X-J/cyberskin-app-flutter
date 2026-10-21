// 自由控制模块操作到通用业务协议语义指令的映射规则；不依赖 Flutter、GetX 与 BLE 实现。

import 'dart:math' as math;

import '../../../../core/protocol/common_business_command.dart';
import 'entities/free_control_layout.dart';

/// 自由控制模块操作的语义指令映射。
///
/// 分档与无级变速共用通道逻辑强度（`t:` / `v:` 0–100）：第 N 档按
/// `round(N / gearMax × 100)` 换算，由设备适配层映射到硬件实际档位
/// （通用业务协议「0-100 逻辑百分比强度」）。设备上报的马达功率按同一比例反算回档位，
/// 使分档控件可以显示设备真实状态。
abstract final class FreeControlCommandMapper {
  /// 伸缩/震动通道的连续逻辑强度，[percent] 超界时裁剪到 0–100。
  static CommonBusinessCommand intensity(
    FreeControlComponentType type,
    int percent,
  ) => _single(_moduleOf(type), '${percent.clamp(0, 100)}');

  /// 分档控件选中第 [gear] 档时下发的逻辑强度。
  static CommonBusinessCommand gear(
    FreeControlComponentConfig config,
    int gear,
  ) => intensity(config.type, gearToPercent(config, gear));

  /// 吮吸/加热开关：开启为 `o`，关闭为 `f`。
  static CommonBusinessCommand toggle(FreeControlComponentType type, bool on) =>
      _single(_moduleOf(type), on ? 'o' : 'f');

  /// 吮吸模式切换；[modeNumber] 从 1 开始，等于后台模式列表下标 + 1。
  ///
  /// 协议只允许在 `CM->` 模式指令中为吮吸携带数字，普通 `s:2` 会被判为非法。
  static CommonBusinessCommand suckMode(int modeNumber) =>
      CommonBusinessCommand(
        isModeCommand: true,
        instructions: List.unmodifiable([
          CommonInstruction(
            module: CommonModule.suck,
            value: '${modeNumber.clamp(1, 100)}',
            isMode: true,
          ),
        ]),
      );

  /// 档位 → 逻辑强度百分比。gear 0 表示停止，直接返回 0。
  static int gearToPercent(FreeControlComponentConfig config, int gear) {
    if (gear <= 0) return 0;
    final max = _gearMax(config);
    final clamped = gear.clamp(config.gearMin, max);
    return (clamped * 100 / max).round().clamp(0, 100);
  }

  /// 逻辑强度百分比 → 档位。
  ///
  /// 功率为 0（设备停止）或负数（未知）时返回 `null`：分档控件没有“停止”档，
  /// 调用方应保留当前显示而不是跳到最低档。
  static int? gearFromPercent(FreeControlComponentConfig config, int percent) {
    if (percent <= 0) return null;
    final max = _gearMax(config);
    return (percent * max / 100).round().clamp(config.gearMin, max);
  }

  /// 后台可能下发 0 或小于 gearMin 的档位数，统一兜底，避免 clamp 区间倒置。
  static int _gearMax(FreeControlComponentConfig config) =>
      math.max(math.max(config.resolvedGearMax, config.gearMin), 1);

  static CommonBusinessCommand _single(CommonModule module, String value) =>
      CommonBusinessCommand(
        isModeCommand: false,
        instructions: List.unmodifiable([
          CommonInstruction(module: module, value: value, isMode: false),
        ]),
      );

  /// 组件类型到协议模块键的映射；模式卡与一键高潮不对应单一通道指令。
  static CommonModule _moduleOf(FreeControlComponentType type) =>
      switch (type) {
        FreeControlComponentType.telescopic => CommonModule.telescopic,
        FreeControlComponentType.vibration => CommonModule.vibration,
        FreeControlComponentType.suck => CommonModule.suck,
        FreeControlComponentType.heat => CommonModule.heat,
        FreeControlComponentType.mode ||
        FreeControlComponentType.oneClickClimax => throw ArgumentError.value(
          type,
          'type',
          'has no single-channel command',
        ),
      };
}
