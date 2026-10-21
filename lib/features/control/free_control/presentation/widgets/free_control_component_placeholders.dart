// 自由控制页面各个组件的分发器：按 variant 选择真实控件，绑定设备遥测与用户操作回调，
// 未实现的模块使用与 webadmin 一致的切图或占位兜底。

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../device/data/ble_runtime_status_log.dart';
import '../../domain/entities/free_control_layout.dart';
import '../free_control_controller.dart';
import 'heat_bar_control.dart';
import 'heat_toggle_control.dart';
import 'mode_multi_control.dart';
import 'suck_multi_control.dart';
import 'suck_toggle_control.dart';
import 'telescopic_horizontal_stepped_control.dart';
import 'telescopic_horizontal_variable_control.dart';
import 'telescopic_mode_switch_control.dart';
import 'telescopic_stepped_control.dart';
import 'telescopic_variable_control.dart';
import 'vibration_horizontal_stepped_control.dart';
import 'vibration_horizontal_variable_control.dart';
import 'vibration_mode_switch_control.dart';
import 'vibration_stepped_control.dart';
import 'vibration_variable_control.dart';

/// 自由控制组件占位组件：渲染真实模块切图或高保真原生卡片
final class FreeControlComponentPlaceholder extends StatelessWidget {
  /// 创建自由控制组件占位组件。
  const FreeControlComponentPlaceholder({
    super.key,
    required this.config,
    this.height,
    this.onToggle,
  });

  /// 组件配置
  final FreeControlComponentConfig config;

  /// 外部约束的固定高度
  final double? height;

  /// 可折叠卡片开关状态变化时通知外部（用于布局高度重算）。
  final ValueChanged<bool>? onToggle;

  /// 根据 variant 获取对应的切图资源路径（与 webadmin ComponentPreview.vue 保持完全一致）
  String? get _assetImagePath => switch (config.variant) {
    // Heat
    'heat_toggle_1x1' => 'assets/images/device_modules/heat/heat-a.png',
    'heat_bar_1x2' => 'assets/images/device_modules/heat/heat-b.png',

    // Suck
    'suck_toggle_1x1' => 'assets/images/device_modules/suck/suck-a.png',
    'suck_multi_2x2' => 'assets/images/device_modules/suck/suck-b.png',

    // Telescopic (Thrust)
    // 'telescopic_mode_3x1' 已由 TelescopicSteppedControl 原生 Canvas 实现
    // 'telescopic_mode_1x2' 已由 TelescopicHorizontalSteppedControl 原生 Canvas 实现
    'telescopic_mode_1x2' => 'assets/images/device_modules/thrust/thrust-b.png',
    // 'telescopic_mode_2x2' 已由 TelescopicModeSwitchControl 原生组件实现
    'telescopic_variable_3x1' =>
      'assets/images/device_modules/thrust/thrust-c.png',
    'telescopic_variable_1x2' =>
      'assets/images/device_modules/thrust/thrust-d.png',

    // Vibration
    // 'vibration_mode_3x1' 已由 VibrationSteppedControl 原生 Canvas 实现
    // 'vibration_mode_2x2' 已由 VibrationModeSwitchControl 原生组件实现
    'vibration_mode_3x1' =>
      'assets/images/device_modules/vibration/vibration-a.png',
    // 'vibration_mode_1x2' 已由 VibrationHorizontalSteppedControl 原生 Canvas 实现
    'vibration_mode_1x2' =>
      'assets/images/device_modules/vibration/vibration-b.png',
    // 'vibration_variable_3x1' 已由 VibrationVariableControl 原生 Canvas 实现
    'vibration_variable_3x1' =>
      'assets/images/device_modules/vibration/vibration-c.png',
    // 'vibration_variable_1x2' 已由 VibrationHorizontalVariableControl 原生 Canvas 实现
    'vibration_variable_1x2' =>
      'assets/images/device_modules/vibration/vibration-d.png',

    _ => null,
  };

  /// 依据 Figma 规格与 WebAdmin 的宽高比
  /// 单行单列（1x1）：172x105 -> 172 / 105
  /// 三行单列（3x1 模式）：172x312 -> 172 / 312
  /// 三行单列（3x1 变速）：172x355 -> 172 / 355
  /// 单行双列加热（1x2）：358x105 -> 358 / 105（高度与 1x1 保持 105 dp 一致）
  /// 单行双列伸缩/震动（1x2）：358x135 -> 358 / 135
  /// 双行双列（2x2）：358x231 -> 358 / 231
  double get _aspectRatio => switch (config.variant) {
    'heat_toggle_1x1' || 'suck_toggle_1x1' => 172 / 105,
    'heat_bar_1x2' => 358 / 105,
    'telescopic_mode_1x2' ||
    'telescopic_variable_1x2' ||
    'vibration_mode_1x2' ||
    'vibration_variable_1x2' => 358 / 135,
    'telescopic_mode_3x1' || 'vibration_mode_3x1' => 172 / 312,
    'telescopic_variable_3x1' || 'vibration_variable_3x1' => 172 / 355,
    'suck_multi_2x2' ||
    'climax_2x2' ||
    'mode_2x2' ||
    'telescopic_mode_2x2' ||
    'vibration_mode_2x2' => 358 / 231,
    _ =>
      config.isFullWidth
          ? (config.type == FreeControlComponentType.heat
                ? 358 / 105
                : 358 / 135)
          : 172 / 105,
  };

  /// 模块是否对应单一硬件通道（需要订阅遥测并下发指令）。
  bool get _isChannelModule => switch (config.type) {
    FreeControlComponentType.telescopic ||
    FreeControlComponentType.vibration ||
    FreeControlComponentType.suck ||
    FreeControlComponentType.heat => true,
    FreeControlComponentType.mode ||
    FreeControlComponentType.oneClickClimax => false,
  };

  @override
  Widget build(BuildContext context) {
    // 未注册控制器时（组件预览、独立 Widget 测试）只做静态展示，不订阅遥测也不下发指令。
    final controller = Get.isRegistered<FreeControlController>()
        ? Get.find<FreeControlController>()
        : null;
    if (controller == null || !_isChannelModule) {
      return _buildModule(context, null);
    }
    // 每个模块独立 Obx，只订阅自身通道的遥测字段，避免单通道上报重建整个网格。
    return Obx(() => _buildModule(context, controller));
  }

  /// 设备上报的吮吸原始状态 → 波纹动画状态；待机与未知都不播放。
  static SuckMotionState _suckMotionOf(int suckState) => switch (suckState) {
    2 => SuckMotionState.inhaling,
    3 => SuckMotionState.exhaling,
    _ => SuckMotionState.idle,
  };

  /// 按 variant 分发真实控件；[c] 为空时不绑定设备状态与回调。
  Widget _buildModule(BuildContext context, FreeControlController? c) {
    final type = config.type;
    // 分档/变速控件读取设备上报值。该读取对所有通道模块都会执行，也保证 Obx 至少订阅
    // connectedDevice，即使 variant 落入下方切图兜底分支也不会触发 GetX 的无订阅错误。
    //
    // 注意：上报值为 null 时回落到后台配置（gearCurrent / 默认百分比），
    // 设备停止（功率 0）或尚未上报时都会走这条回落路径。
    final reportedPercent = c?.reportedPercent(type);
    final reportedGear = c == null ? null : c.reportedGear(config);
    final steppedConfig = c == null
        ? config
        : config.withGearCurrent(reportedGear ?? config.gearCurrent);
    // 只读诊断：打印本次重建解析出的上报值与最终交给控件显示的值（不是发给 BLE 的指令），
    // 用于定位”控件显示回落到初始值”时到底是上报缺失还是控件内部状态被重置。
    if (c != null && kBleDiagnosticLog) {
      debugPrint(
        '[BLE:UI] ${config.type.name}/${config.variant} '
        '上报强度=${reportedPercent ?? '无'} 上报档位=${reportedGear ?? '无'} '
        '→ 显示档位=${steppedConfig.gearCurrent ?? '无'} '
        '显示百分比=${reportedPercent ?? '回退'}',
      );
    }
    final onToggle = c == null
        ? null
        : (bool on) => c.onToggleChanged(type, on);
    // 可折叠卡片的开关回调：先通知布局重算，再下发 BLE 指令。
    ValueChanged<bool>? _wrapToggle(ValueChanged<bool>? bleToggle) {
      if (this.onToggle == null && bleToggle == null) return null;
      return (bool on) {
        this.onToggle?.call(on);
        bleToggle?.call(on);
      };
    }
    final onGear = c == null
        ? null
        : (int gear) => c.onGearSelected(config, gear);
    final onIntensity = c == null
        ? null
        : (int percent) => c.onIntensityChanged(type, percent);

    // 加热 1x1 开关组件（已还原为原生可交互组件，对齐 heat-a.png）
    if (type == FreeControlComponentType.heat &&
        (config.variant == 'heat_toggle_1x1' ||
            (!config.isFullWidth && config.rows == 1))) {
      return HeatToggleControl(
        config: config,
        height: height,
        initialValue: c?.heatOn ?? false,
        onChanged: onToggle,
      );
    }

    // 加热 1x2 横向开关组件（已还原为原生可交互组件，对齐 heat-b.png）
    if (type == FreeControlComponentType.heat &&
        (config.variant == 'heat_bar_1x2' || config.isFullWidth)) {
      return HeatBarControl(
        config: config,
        height: height ?? 105.0,
        initialValue: c?.heatOn ?? false,
        onChanged: onToggle,
      );
    }

    // 吸附/吮吸 1x1 开关组件（已还原为原生可交互组件，对齐 suck-a.png）
    if (type == FreeControlComponentType.suck &&
        (config.variant == 'suck_toggle_1x1' ||
            (!config.isFullWidth && config.rows == 1))) {
      return SuckToggleControl(
        config: config,
        height: height,
        initialValue: c?.suckOn ?? true,
        onChanged: onToggle,
      );
    }

    // 吸附/吮吸 2x2 多模式组件（已还原为原生 Canvas 与动画组件，对齐 suck-b.png）
    if (type == FreeControlComponentType.suck &&
        (config.variant == 'suck_multi_2x2' ||
            (config.isFullWidth && config.rows >= 2))) {
      return SuckMultiControl(
        config: config,
        height: height ?? SuckMultiControl.estimatedHeight(config),
        initialValue: c?.suckOn ?? true,
        motionState: c == null
            ? SuckMotionState.idle
            : _suckMotionOf(c.suckState),
        onChanged: _wrapToggle(onToggle),
        onModeChanged: c == null
            ? null
            : (mode) => c.onSuckModeSelected(config, mode),
      );
    }

    // 伸缩 1x2 横向无级变速组件（已还原为 Canvas 原生自绘组件，对齐 thrust-d.png）
    if (type == FreeControlComponentType.telescopic &&
        (config.variant == 'telescopic_variable_1x2' ||
            (config.variableSpeedSupported &&
                config.rows == 1 &&
                config.cols >= 2))) {
      return TelescopicHorizontalVariableControl(
        config: config,
        height: height ?? 135.0,
        initialPercentage: c?.reportedPercent(type),
        onGearChanged: onIntensity,
      );
    }

    // 伸缩 3x1 竖向无级变速组件（已还原为 Canvas 原生自绘组件，对齐 thrust-c.png）
    if (type == FreeControlComponentType.telescopic &&
        (config.variant == 'telescopic_variable_3x1' ||
            (config.variableSpeedSupported &&
                config.rows >= 3 &&
                config.cols == 1))) {
      return TelescopicVariableControl(
        config: config,
        height: height,
        initialPercentage: c?.reportedPercent(type),
        onGearChanged: onIntensity,
      );
    }

    // 伸缩 3x1 竖向分档组件（已还原为 Canvas 原生自绘组件，对齐 thrust-a.png）
    if (type == FreeControlComponentType.telescopic &&
        (config.variant == 'telescopic_mode_3x1' ||
            (!config.variableSpeedSupported &&
                config.rows >= 3 &&
                config.cols == 1))) {
      return TelescopicSteppedControl(
        config: steppedConfig,
        height: height,
        onGearChanged: onGear,
      );
    }

    // 伸缩 1x2 横向分档组件（已还原为 Canvas 原生自绘组件，对齐 thrust-b.png）
    if (type == FreeControlComponentType.telescopic &&
        (config.variant == 'telescopic_mode_1x2' ||
            (!config.variableSpeedSupported &&
                config.rows == 1 &&
                config.cols >= 2))) {
      return TelescopicHorizontalSteppedControl(
        config: steppedConfig,
        height: height ?? 135.0,
        onGearChanged: onGear,
      );
    }

    // 震动 3x1 竖向分档组件（已还原为 Canvas 原生自绘组件，对齐 vibration-a.png）
    if (type == FreeControlComponentType.vibration &&
        (config.variant == 'vibration_mode_3x1' ||
            (!config.variableSpeedSupported &&
                config.rows >= 3 &&
                config.cols == 1))) {
      return VibrationSteppedControl(
        config: steppedConfig,
        height: height,
        onGearChanged: onGear,
      );
    }

    // 震动 3x1 竖向无级变速组件（已还原为 Canvas 原生自绘组件，对齐 vibration-c.png）
    if (type == FreeControlComponentType.vibration &&
        (config.variant == 'vibration_variable_3x1' ||
            (config.variableSpeedSupported &&
                config.rows >= 3 &&
                config.cols == 1))) {
      return VibrationVariableControl(
        config: config,
        height: height,
        initialPercentage: c?.reportedPercent(type),
        onGearChanged: onIntensity,
      );
    }

    // 震动 1x2 横向分档组件（已还原为 Canvas 原生自绘组件，对齐 vibration-b.png）
    if (type == FreeControlComponentType.vibration &&
        (config.variant == 'vibration_mode_1x2' ||
            (!config.variableSpeedSupported &&
                config.rows == 1 &&
                config.cols >= 2))) {
      return VibrationHorizontalSteppedControl(
        config: steppedConfig,
        height: height ?? 135.0,
        onGearChanged: onGear,
      );
    }

    // 震动 1x2 横向无级变速组件（已还原为 Canvas 原生自绘组件，对齐 vibration-d.png）
    if (type == FreeControlComponentType.vibration &&
        (config.variant == 'vibration_variable_1x2' ||
            (config.variableSpeedSupported &&
                config.rows == 1 &&
                config.cols >= 2))) {
      return VibrationHorizontalVariableControl(
        config: config,
        height: height ?? 135.0,
        initialPercentage: c?.reportedPercent(type),
        onGearChanged: onIntensity,
      );
    }

    // 伸缩 2x2 模式切换卡片
    if (type == FreeControlComponentType.telescopic &&
        config.variant == 'telescopic_mode_2x2') {
      return TelescopicModeSwitchControl(
        config: steppedConfig,
        height: height,
        initialValue: c != null,
        initialGear: reportedGear ?? steppedConfig.gearCurrent,
        onChanged: _wrapToggle(onToggle),
        onGearChanged: onGear,
      );
    }

    // 震动 2x2 模式切换卡片
    if (type == FreeControlComponentType.vibration &&
        config.variant == 'vibration_mode_2x2') {
      return VibrationModeSwitchControl(
        config: steppedConfig,
        height: height,
        initialValue: c != null,
        initialGear: reportedGear ?? steppedConfig.gearCurrent,
        onChanged: _wrapToggle(onToggle),
        onGearChanged: onGear,
      );
    }

    final imagePath = _assetImagePath;

    if (imagePath != null) {
      return AspectRatio(
        aspectRatio: _aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imagePath,
            fit: BoxFit.fill,
            errorBuilder: (_, _, _) => _buildFallbackWidget(context),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: _buildFallbackWidget(context),
    );
  }

  Widget _buildFallbackWidget(BuildContext context) {
    return switch (config.type) {
      FreeControlComponentType.heat => _HeatFallback(config: config),
      FreeControlComponentType.suck => _SuckFallback(config: config),
      FreeControlComponentType.telescopic => _TelescopicFallback(
        config: config,
      ),
      FreeControlComponentType.vibration => _VibrationFallback(config: config),
      FreeControlComponentType.mode => _ModeFallback(config: config),
      FreeControlComponentType.oneClickClimax => _OneClickClimaxFallback(
        config: config,
      ),
    };
  }
}

/// 基础暗紫渐变容器
Widget _buildCardBase({
  required Widget child,
  double? height,
  EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  Border? border,
  Gradient? gradient,
}) {
  return Container(
    height: height,
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.radiusXlLarge),
      gradient:
          gradient ??
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF38234D).withValues(alpha: 0.65),
              const Color(0xFF1E172E).withValues(alpha: 0.85),
            ],
          ),
      border:
          border ??
          Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Heat 加热兜底组件
// ─────────────────────────────────────────────────────────────────────────────

final class _HeatFallback extends StatelessWidget {
  const _HeatFallback({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    if (config.isFullWidth) {
      return _buildCardBase(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: Colors.amber.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      config.displayLabel,
                      style: const TextStyle(
                        fontSize: AppTypography.size14,
                        fontWeight: AppFontWeights.medium,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Not enabled',
                  style: TextStyle(
                    fontSize: AppTypography.size11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepOrange.withValues(alpha: 0.3),
                border: Border.all(color: Colors.deepOrange.shade400, width: 1),
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                size: 18,
                color: Colors.deepOrange.shade300,
              ),
            ),
            const SizedBox(width: 12),
            _buildMockSwitch(
              activeColor: Colors.deepOrange.shade400,
              isOn: false,
            ),
          ],
        ),
      );
    }

    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: Colors.amber.shade400,
              ),
              const SizedBox(width: 4),
              Text(
                config.displayLabel,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppFontWeights.medium,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          _buildMockSwitch(
            activeColor: Colors.deepOrange.shade400,
            isOn: false,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Suck 吸附/吮吸兜底组件
// ─────────────────────────────────────────────────────────────────────────────

final class _SuckFallback extends StatelessWidget {
  const _SuckFallback({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    if (config.isFullWidth && config.rows >= 2) {
      return _buildCardBase(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.album_outlined,
                  size: 16,
                  color: Colors.purple.shade300,
                ),
                const SizedBox(width: 6),
                Text(
                  config.displayLabel,
                  style: const TextStyle(
                    fontSize: AppTypography.size14,
                    fontWeight: AppFontWeights.medium,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _buildMockSwitch(
                  activeColor: const Color(0xFFD13BD8),
                  isOn: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip('Easy Mode', isSelected: true),
                _buildChip('Quick Mode', isSelected: false),
                _buildChip('one', isSelected: false),
                _buildChip('two', isSelected: false),
                _buildChip('three', isSelected: false),
              ],
            ),
          ],
        ),
      );
    }

    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.album_outlined,
                size: 16,
                color: Colors.purple.shade300,
              ),
              const SizedBox(width: 4),
              Text(
                config.displayLabel,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppFontWeights.medium,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          _buildMockSwitch(activeColor: const Color(0xFFD13BD8), isOn: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Telescopic 伸缩兜底组件
// ─────────────────────────────────────────────────────────────────────────────

final class _TelescopicFallback extends StatelessWidget {
  const _TelescopicFallback({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    final isVertical = config.rows >= 2 || config.cols == 1;

    if (isVertical && !config.variableSpeedSupported) {
      return TelescopicSteppedControl(config: config);
    }

    if (isVertical) {
      return _buildCardBase(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.swap_vert_rounded,
                  size: 16,
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    config.displayLabel,
                    style: const TextStyle(
                      fontSize: AppTypography.size14,
                      fontWeight: AppFontWeights.medium,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              config.variableSpeedSupported
                  ? 'Variable Speed\n82%'
                  : 'Gear ${config.gearCurrent ?? 4} / ${config.gearMax ?? 6}',
              style: const TextStyle(
                fontSize: AppTypography.size11,
                color: AppColors.textMuted,
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                width: 72,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  color: Colors.black.withValues(alpha: 0.35),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      width: 72,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF2654BE), Color(0xFF558EF4)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_vert_rounded,
                size: 16,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 4),
              Text(
                config.displayLabel,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppFontWeights.medium,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                config.variableSpeedSupported
                    ? 'Gear 22%'
                    : 'Gear ${config.gearCurrent ?? 4} / ${config.gearMax ?? 6}',
                style: const TextStyle(
                  fontSize: AppTypography.size12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHorizontalSlider(
            percent: 0.45,
            gradient: const LinearGradient(
              colors: [Color(0xFF8857E4), Color(0xFF67B5FD)],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Vibration 震动兜底组件
// ─────────────────────────────────────────────────────────────────────────────

final class _VibrationFallback extends StatelessWidget {
  const _VibrationFallback({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    final isVertical = config.rows >= 2 || config.cols == 1;

    if (isVertical && !config.variableSpeedSupported) {
      return VibrationSteppedControl(config: config);
    }

    if (isVertical) {
      return VibrationVariableControl(config: config);
    }

    if (config.variableSpeedSupported) {
      return VibrationHorizontalVariableControl(config: config);
    }

    return VibrationHorizontalSteppedControl(config: config);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Mode 模式兜底组件
// ─────────────────────────────────────────────────────────────────────────────

final class _ModeFallback extends StatelessWidget {
  const _ModeFallback({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    return _buildCardBase(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: Color(0xFFD13BD8),
              ),
              const SizedBox(width: 6),
              Text(
                config.displayLabel,
                style: const TextStyle(
                  fontSize: AppTypography.size14,
                  fontWeight: AppFontWeights.medium,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildPillButton('Stop', isOutlined: true),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPillButton('Default Mode', isOutlined: true),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildPillButton('Free Mode', isOutlined: true)),
              const SizedBox(width: 10),
              Expanded(child: _buildPillButton('Crazy Mode', isSelected: true)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'The free fantasy mode is ...',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. OneClickClimax 一键高潮兜底组件
// ─────────────────────────────────────────────────────────────────────────────

final class _OneClickClimaxFallback extends StatelessWidget {
  const _OneClickClimaxFallback({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    return _buildCardBase(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.flash_on_rounded,
                      size: 16,
                      color: Color(0xFFE447D0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      config.displayLabel,
                      style: const TextStyle(
                        fontSize: AppTypography.size14,
                        fontWeight: AppFontWeights.medium,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 24,
                  width: 120,
                  child: CustomPaint(painter: _WavePainter()),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A2B6D).withValues(alpha: 0.8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE447D0).withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.power_settings_new_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 辅助视觉元素
// ─────────────────────────────────────────────────────────────────────────────

Widget _buildMockSwitch({required Color activeColor, required bool isOn}) {
  return Container(
    width: 60,
    height: 32,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: isOn ? activeColor : const Color(0xFF41284A),
      border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
    ),
    child: Row(
      mainAxisAlignment: isOn ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (isOn)
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: Text(
              'ON',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
        if (!isOn)
          const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Text(
              'OFF',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
      ],
    ),
  );
}

Widget _buildHorizontalSlider({
  required double percent,
  required Gradient gradient,
}) {
  return Container(
    height: 34,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(17),
      color: Colors.black.withValues(alpha: 0.35),
      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              width: constraints.maxWidth * percent,
              height: 34,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: gradient,
              ),
            ),
          ],
        );
      },
    ),
  );
}

Widget _buildChip(String label, {required bool isSelected}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: isSelected
          ? const Color(0xFFD13BD8).withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.08),
      border: Border.all(
        color: isSelected
            ? const Color(0xFFD13BD8)
            : Colors.white.withValues(alpha: 0.15),
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 12,
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    ),
  );
}

Widget _buildPillButton(
  String text, {
  bool isSelected = false,
  bool isOutlined = false,
}) {
  return Container(
    height: 38,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(19),
      gradient: isSelected
          ? const LinearGradient(colors: [Color(0xFFD13BD8), Color(0xFF762BB5)])
          : null,
      color: isSelected ? null : Colors.white.withValues(alpha: 0.08),
      border: Border.all(
        color: isSelected
            ? Colors.transparent
            : Colors.white.withValues(alpha: 0.18),
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: Colors.white,
      ),
    ),
  );
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD13BD8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(15, size.height * 0.5)
      ..lineTo(25, size.height * 0.1)
      ..lineTo(35, size.height * 0.9)
      ..lineTo(45, size.height * 0.2)
      ..lineTo(55, size.height * 0.8)
      ..lineTo(65, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
