// 自由控制页面各个组件的视觉占位。
// 优先使用与 webadmin 完全一致的原生模块设计切图进行高保真展示，并附带优雅的占位兜底。

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/free_control_layout.dart';

/// 自由控制组件占位组件：渲染真实模块切图或高保真原生卡片
final class FreeControlComponentPlaceholder extends StatelessWidget {
  const FreeControlComponentPlaceholder({
    super.key,
    required this.config,
    this.height,
  });

  final FreeControlComponentConfig config;
  final double? height;

  /// 根据 variant 获取对应的切图资源路径（与 webadmin ComponentPreview.vue 保持完全一致）
  String? get _assetImagePath => switch (config.variant) {
    // Heat
    'heat_toggle_1x1' => 'assets/images/device_modules/heat/heat-a.png',
    'heat_bar_1x2' => 'assets/images/device_modules/heat/heat-b.png',

    // Suck
    'suck_toggle_1x1' => 'assets/images/device_modules/suck/suck-a.png',
    'suck_multi_2x2' => 'assets/images/device_modules/suck/suck-b.png',

    // Telescopic (Thrust)
    'telescopic_mode_3x1' => 'assets/images/device_modules/thrust/thrust-a.png',
    'telescopic_mode_1x2' => 'assets/images/device_modules/thrust/thrust-b.png',
    'telescopic_variable_3x1' =>
      'assets/images/device_modules/thrust/thrust-c.png',
    'telescopic_variable_1x2' =>
      'assets/images/device_modules/thrust/thrust-d.png',

    // Vibration
    'vibration_mode_3x1' =>
      'assets/images/device_modules/vibration/vibration-a.png',
    'vibration_mode_1x2' =>
      'assets/images/device_modules/vibration/vibration-b.png',
    'vibration_variable_3x1' =>
      'assets/images/device_modules/vibration/vibration-c.png',
    'vibration_variable_1x2' =>
      'assets/images/device_modules/vibration/vibration-d.png',

    _ => null,
  };

  /// 依据 Figma 规格与 WebAdmin 的宽高比
  /// 单行单列（1x1）：172x105 -> 172 / 105
  /// 三行单列（3x1）：172x312 -> 172 / 312
  /// 单行双列（1x2）：358x135 -> 358 / 135
  /// 双行双列（2x2）：358x231 -> 358 / 231
  double get _aspectRatio => switch (config.variant) {
    'heat_toggle_1x1' || 'suck_toggle_1x1' => 172 / 105,
    'heat_bar_1x2' ||
    'telescopic_mode_1x2' ||
    'telescopic_variable_1x2' ||
    'vibration_mode_1x2' ||
    'vibration_variable_1x2' => 358 / 135,
    'telescopic_mode_3x1' ||
    'telescopic_variable_3x1' ||
    'vibration_mode_3x1' ||
    'vibration_variable_3x1' => 172 / 312,
    'suck_multi_2x2' || 'climax_2x2' || 'mode_2x2' => 358 / 231,
    _ => config.isFullWidth ? 358 / 135 : 172 / 105,
  };

  @override
  Widget build(BuildContext context) {
    final imagePath = _assetImagePath;

    if (imagePath != null) {
      return AspectRatio(
        aspectRatio: _aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            imagePath,
            fit: BoxFit.fill,
            errorBuilder: (_, __, ___) => _buildFallbackWidget(context),
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

    if (isVertical) {
      return _buildCardBase(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.vibration_rounded,
                  size: 16,
                  color: Color(0xFFD13BD8),
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
                  ? 'Variable Speed\n12%'
                  : 'Gear ${config.gearCurrent ?? 2} / ${config.gearMax ?? 6}',
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
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF7A1D85), Color(0xFFE447D0)],
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
                Icons.vibration_rounded,
                size: 16,
                color: Color(0xFFD13BD8),
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
                    ? 'Gear 62%'
                    : 'Gear ${config.gearCurrent ?? 2} / ${config.gearMax ?? 6}',
                style: const TextStyle(
                  fontSize: AppTypography.size12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHorizontalSlider(
            percent: 0.62,
            gradient: const LinearGradient(
              colors: [Color(0xFFE47B33), Color(0xFF9E43DA)],
            ),
          ),
        ],
      ),
    );
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
