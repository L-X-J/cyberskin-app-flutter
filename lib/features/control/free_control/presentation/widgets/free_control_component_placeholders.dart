// 自由控制页面各个组件的视觉占位。
// 按照设计稿规范实现卡片容器、毛玻璃样式、渐变色彩与占位信息。
// 满足需求：“你可以先用组件，展位，无需实现，那些组件。后续我们挨个组件去实现。”

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../domain/entities/free_control_layout.dart';

/// 自由控制组件占位基类/通用卡片
final class FreeControlComponentPlaceholder extends StatelessWidget {
  const FreeControlComponentPlaceholder({
    super.key,
    required this.config,
    this.height,
  });

  final FreeControlComponentConfig config;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return switch (config.type) {
      FreeControlComponentType.heat => _HeatPlaceholder(config: config),
      FreeControlComponentType.suck => _SuckPlaceholder(config: config),
      FreeControlComponentType.telescopic => _TelescopicPlaceholder(
        config: config,
      ),
      FreeControlComponentType.vibration => _VibrationPlaceholder(
        config: config,
      ),
      FreeControlComponentType.mode => _ModePlaceholder(config: config),
      FreeControlComponentType.oneClickClimax => _OneClickClimaxPlaceholder(
        config: config,
      ),
    };
  }
}

/// 基础暗紫渐变容器，模拟设计稿深紫/毛玻璃质感
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
// 1. Heat 加热占位组件
// ─────────────────────────────────────────────────────────────────────────────

final class _HeatPlaceholder extends StatelessWidget {
  const _HeatPlaceholder({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    // 判断是 1x1 开关卡还是 1x2 横向条卡
    if (config.isFullWidth) {
      return _buildCardBase(
        height: 80,
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
            // 模拟橙色火焰按钮
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
            // 模拟开关
            _buildMockSwitch(
              activeColor: Colors.deepOrange.shade400,
              isOn: false,
            ),
          ],
        ),
      );
    }

    // 1x1 小方卡
    return _buildCardBase(
      height: 90,
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
// 2. Suck 吸附/吮吸占位组件
// ─────────────────────────────────────────────────────────────────────────────

final class _SuckPlaceholder extends StatelessWidget {
  const _SuckPlaceholder({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    // 2x2 多档或带模式列表模式
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
            // 模式选择芯片列表
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

    // 1x1 开关卡
    return _buildCardBase(
      height: 90,
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
// 3. Telescopic 伸缩占位组件 (垂直滑块 3x1 / 水平条 1x2)
// ─────────────────────────────────────────────────────────────────────────────

final class _TelescopicPlaceholder extends StatelessWidget {
  const _TelescopicPlaceholder({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    final isVertical = config.rows >= 2 || config.cols == 1;

    if (isVertical) {
      // 垂直滑块卡（类似设计图中的 Telescopic 3x1）
      return _buildCardBase(
        height: 250,
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
            if (config.variableSpeedSupported)
              const Text(
                'Variable Speed\n82%',
                style: TextStyle(
                  fontSize: AppTypography.size10,
                  color: AppColors.textMuted,
                  height: 1.2,
                ),
              )
            else
              Text(
                'Gear ${config.gearCurrent ?? 4} / ${config.gearMax ?? 6}',
                style: const TextStyle(
                  fontSize: AppTypography.size11,
                  color: AppColors.textMuted,
                ),
              ),
            const Spacer(),
            // 垂直大滑条胶囊
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
                    // 填充高度动画或渐变条
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
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    // 水平横向条（1x2）
    return _buildCardBase(
      height: 90,
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
              if (config.variableSpeedSupported) ...[
                const SizedBox(width: 6),
                const Text(
                  'Variable Speed',
                  style: TextStyle(
                    fontSize: AppTypography.size10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
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
          // 水平胶囊进度条
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
// 4. Vibration 震动占位组件 (垂直滑块 3x1 / 水平条 1x2)
// ─────────────────────────────────────────────────────────────────────────────

final class _VibrationPlaceholder extends StatelessWidget {
  const _VibrationPlaceholder({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    final isVertical = config.rows >= 2 || config.cols == 1;

    if (isVertical) {
      // 垂直滑块卡（类似设计图中的 Vibration 3x1）
      return _buildCardBase(
        height: 250,
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
            if (config.variableSpeedSupported)
              const Text(
                'Variable Speed\n12%',
                style: TextStyle(
                  fontSize: AppTypography.size10,
                  color: AppColors.textMuted,
                  height: 1.2,
                ),
              )
            else
              Text(
                'Gear ${config.gearCurrent ?? 2} / ${config.gearMax ?? 6}',
                style: const TextStyle(
                  fontSize: AppTypography.size11,
                  color: AppColors.textMuted,
                ),
              ),
            const Spacer(),
            // 垂直大滑条胶囊
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
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    // 水平横向条（1x2）
    return _buildCardBase(
      height: 90,
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
              if (config.variableSpeedSupported) ...[
                const SizedBox(width: 6),
                const Text(
                  'Variable Speed',
                  style: TextStyle(
                    fontSize: AppTypography.size10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
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
// 5. Mode 模式选择占位组件
// ─────────────────────────────────────────────────────────────────────────────

final class _ModePlaceholder extends StatelessWidget {
  const _ModePlaceholder({required this.config});

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
// 6. OneClickClimax 一键高潮占位组件
// ─────────────────────────────────────────────────────────────────────────────

final class _OneClickClimaxPlaceholder extends StatelessWidget {
  const _OneClickClimaxPlaceholder({required this.config});

  final FreeControlComponentConfig config;

  @override
  Widget build(BuildContext context) {
    return _buildCardBase(
      height: 96,
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
                // 模拟波形
                SizedBox(
                  height: 24,
                  width: 120,
                  child: CustomPaint(painter: _WavePainter()),
                ),
              ],
            ),
          ),
          // 电源开启圆按钮
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
// 辅助视觉元素函数与组件
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
