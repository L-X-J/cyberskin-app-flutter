// 自由控制连续变速胶囊通用控件（Variable Capsule Control）；
// 基于 Canvas 自绘深度还原设备无级变速控制卡片视觉规范，支持横向（1x2）与纵向（3x1）双重布局、
// 震动（电光紫）与伸缩等通道主题、动态速度/百分比解析、水平/垂直触控选值与手势拖拽、
// SVG 级高保真多层内发光漫反射与平滑物理缓动动画。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/free_control_layout.dart';

/// 连续变速胶囊组件视觉主题配置
final class VariableCapsuleTheme {
  /// 创建连续变速胶囊视觉主题。
  const VariableCapsuleTheme({
    required this.icon,
    required this.iconColor,
    required this.cardGradientColors,
    required this.cardBorderColor,
    required this.trackGradientColors,
    required this.capsuleBorderColor,
    required this.liquidGradientColors,
    this.liquidGradientStops,
    required this.innerGlowColor,
    required this.ambientGlowColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.valueLabelColor,
    required this.valuePercentColor,
    this.scaleMaxColor = const Color(0xFF7E87F8),
    this.scaleMinColor = Colors.white,
    this.scaleBarGradientColors = const [Color(0xFFCECECE), Color(0xFFFFFFFF)],
  });

  /// 顶部标题图标
  final IconData icon;

  /// 图标色值
  final Color iconColor;

  /// 外层卡片渐变色 [顶左色, 中间色, 底右色] 或 [顶色, 底色]
  final List<Color> cardGradientColors;

  /// 外层卡片边框色值
  final Color cardBorderColor;

  /// 胶囊未激活槽位渐变色
  final List<Color> trackGradientColors;

  /// 胶囊外壳半透描边轮廓色值（Frosted Glass Rim）
  final Color capsuleBorderColor;

  /// 激活流体线性渐变色值（对应 SVG paint0_linear）
  final List<Color> liquidGradientColors;

  /// 激活流体渐变 stops（可选）
  final List<double>? liquidGradientStops;

  /// 深度漫反射主体内阴影色值（对应 SVG feGaussianBlur stdDeviation="13" 与 feColorMatrix 0.6 白）
  final Color innerGlowColor;

  /// 广域环境漫反射柔雾色值
  final Color ambientGlowColor;

  /// 标题文字颜色
  final Color titleColor;

  /// 副标题文字颜色（如 "Variable Speed"）
  final Color subtitleColor;

  /// 数值前缀标签文字颜色（如 "Gear"）
  final Color valueLabelColor;

  /// 数值百分比文字颜色（如 "62 %" 或 "12%"）
  final Color valuePercentColor;

  /// 纵向刻度最大值标签颜色（如 "100%"）
  final Color scaleMaxColor;

  /// 纵向刻度最小值标签颜色（如 "0%"）
  final Color scaleMinColor;

  /// 纵向刻度细条渐变色
  final List<Color> scaleBarGradientColors;

  /// 震动横向无级变速主题规范（深度还原 vibration-d.png 与 tmp/img_rectangle_110_3.svg）
  static const VariableCapsuleTheme vibrationHorizontal = VariableCapsuleTheme(
    icon: Icons.vibration_rounded,
    iconColor: Color(0xFFA8AEFF), // 软粉紫靛蓝
    cardGradientColors: [
      Color(0xFF1B1838), // 顶左沉稳暗靛紫
      Color(0xFF281C46), // 中右紫罗兰暗晕
      Color(0xFF0F0E17), // 底部近黑
    ],
    cardBorderColor: Color(0x29A4B5FC), // 半透靛青边框
    trackGradientColors: [
      Color(0xFF181026), // 槽位左侧深暗紫
      Color(0xFF231636), // 槽位右侧深暗紫茄色
    ],
    capsuleBorderColor: Color(0x8C9894BB), // 0xFF9894BB with alpha 0.55
    liquidGradientColors: [
      Color(0xFFB5A9EA), // SVG paint0: offset 1 浅紫罗兰高光（左端）
      Color(0xFF4A3BBD), // SVG paint0: offset 0 饱和电光紫（右端）
    ],
    liquidGradientStops: null,
    innerGlowColor: Colors.white, // SVG filter0_i: feColorMatrix 0.6 白
    ambientGlowColor: Color(0xFFE5DEFF),
    titleColor: Colors.white,
    subtitleColor: Color(0xFFDADADA), // AppColors.textSecondary
    valueLabelColor: Colors.white,
    valuePercentColor: Colors.white,
  );

  /// 震动横向别名，保持向前兼容
  static const VariableCapsuleTheme vibration = vibrationHorizontal;

  /// 震动纵向无级变速主题规范（深度还原 vibration-c.png 规范）
  static const VariableCapsuleTheme vibrationVertical = VariableCapsuleTheme(
    icon: Icons.vibration_rounded,
    iconColor: Color(0xFFDDB4FF), // 浅粉紫罗兰
    cardGradientColors: [
      Color(0xFF5E5070), // 顶侧紫罗兰暗色
      Color(0xFF422B80), // 底侧沉稳靛紫
    ],
    cardBorderColor: Color(0x29B5A4D0),
    trackGradientColors: [
      Color(0xFF2E1E46), // 槽位顶部深暗紫
      Color(0xFF382758), // 槽位底部深紫茄色
    ],
    capsuleBorderColor: Color(0x8C9894BB),
    liquidGradientColors: [
      Color(0xFF4A3BBD), // 顶部平切边缘电光紫
      Color(0xFFB5A9EA), // 底部胶囊端浅紫罗兰高光
    ],
    liquidGradientStops: null,
    innerGlowColor: Colors.white,
    ambientGlowColor: Color(0xFFE5DEFF),
    titleColor: Colors.white,
    subtitleColor: Color(0xFFC7BED9),
    valueLabelColor: Colors.white,
    valuePercentColor: Colors.white,
    scaleMaxColor: Color(0xFF7E87F8), // 100% 浅紫靛蓝
    scaleMinColor: Colors.white, // 0% 纯白
    scaleBarGradientColors: [Color(0xFFCECECE), Color(0xFFFFFFFF)],
  );

  /// 伸缩横向无级变速主题规范（深度还原 thrust-d.png 规范）
  static const VariableCapsuleTheme telescopic = VariableCapsuleTheme(
    icon: Icons.swap_vert_rounded,
    iconColor: Color(0xFFDBA8FF), // 软粉兰花浅紫
    cardGradientColors: [
      Color(0xFF231B4D),
      Color(0xFF3B276F),
      Color(0xFF121021),
    ],
    cardBorderColor: Color(0x29A4B5FC),
    trackGradientColors: [Color(0xFF1D1432), Color(0xFF281845)],
    capsuleBorderColor: Color(0x8C9894BB),
    liquidGradientColors: [
      Color(0xFFE3B5E8), // 粉紫
      Color(0xFF63A799), // 湖水青绿
    ],
    liquidGradientStops: null,
    innerGlowColor: Colors.white,
    ambientGlowColor: Color(0xFFD5F0E8),
    titleColor: Colors.white,
    subtitleColor: Color(0xFFDADADA),
    valueLabelColor: Colors.white,
    valuePercentColor: Colors.white,
  );

  /// 伸缩纵向无级变速主题规范（深度还原 thrust-c.png）。
  static const VariableCapsuleTheme telescopicVertical = VariableCapsuleTheme(
    icon: Icons.swap_vert_rounded,
    iconColor: Color(0xFFAAB0FF),
    cardGradientColors: [Color(0xFF242254), Color(0xFF332D8B)],
    cardBorderColor: Color(0x29A4B5FC),
    trackGradientColors: [Color(0xFF302B78), Color(0xFF312A7F)],
    capsuleBorderColor: Color(0x8C9894BB),
    liquidGradientColors: [Color(0xFF3F55B9), Color(0xFFA6ADEB)],
    liquidGradientStops: null,
    innerGlowColor: Colors.white,
    ambientGlowColor: Color(0xFFD5DEFF),
    titleColor: Colors.white,
    subtitleColor: Color(0xFFE0E0E8),
    valueLabelColor: Colors.white,
    valuePercentColor: Colors.white,
    scaleMaxColor: Color(0xFF8D98FF),
    scaleMinColor: Colors.white,
    scaleBarGradientColors: [Color(0xFFD3D3D3), Color(0xFFFFFFFF)],
  );

  /// 伸缩横向无级变速主题规范（对应 thrust-d.png 与 img_rectangle_110_2.svg）。
  static const VariableCapsuleTheme telescopicHorizontalVariable =
      VariableCapsuleTheme(
        icon: Icons.swap_vert_rounded,
        iconColor: Color(0xFFE6B4F0),
        cardGradientColors: [
          Color(0xFF272265),
          Color(0xFF4A2F8D),
          Color(0xFF111022),
        ],
        cardBorderColor: Color(0x29A4B5FC),
        trackGradientColors: [Color(0xFF34226A), Color(0xFF41277D)],
        capsuleBorderColor: Color(0x8C9894BB),
        liquidGradientColors: [Color(0xFFDB8DDC), Color(0xFF60A78F)],
        liquidGradientStops: null,
        innerGlowColor: Colors.white,
        ambientGlowColor: Color(0xFFD5F0E8),
        titleColor: Colors.white,
        subtitleColor: Color(0xFFE0DCE8),
        valueLabelColor: Colors.white,
        valuePercentColor: Colors.white,
      );
}

/// 通用连续无级变速胶囊控制卡片组件
final class VariableCapsuleControl extends StatefulWidget {
  /// 创建通用连续变速胶囊控制组件。
  const VariableCapsuleControl({
    super.key,
    required this.config,
    this.orientation = Axis.horizontal,
    this.theme = VariableCapsuleTheme.vibration,
    this.initialPercentage,
    this.fallbackPercentage,
    this.onValueChanged,
    this.height,
  });

  /// 模块配置
  final FreeControlComponentConfig config;

  /// 控件方向（横向 Axis.horizontal 对齐 1x2 规格；竖向 Axis.vertical 对齐 3x1 规格）
  final Axis orientation;

  /// 视觉主题（震动 / 伸缩）
  final VariableCapsuleTheme theme;

  /// 初始百分比（0 ~ 100）；未指定时优先读取 config.gearCurrent，横向默认 62%，纵向默认 12%
  final int? initialPercentage;

  /// 未提供设备值时使用的设计稿基准百分比。
  final int? fallbackPercentage;

  /// 数值变动回调（回传 0 ~ 100 整数百分比）
  final ValueChanged<int>? onValueChanged;

  /// 外部约束的固定高度（横向默认 135.0 dp，纵向未指定时由 AspectRatio 355/172 约束）
  final double? height;

  @override
  State<VariableCapsuleControl> createState() => _VariableCapsuleControlState();
}

class _VariableCapsuleControlState extends State<VariableCapsuleControl>
    with SingleTickerProviderStateMixin {
  /// 当前百分比数值（0 ~ 100）
  late int _currentPercent;

  /// 上次触发触觉反馈的百分比点位（防止同一跨度内高频震动）
  int _lastHapticPercent = -1;

  /// 是否正在手势滑动拖拽中
  bool _isDragging = false;

  /// 液位平滑过渡动画控制器（用于点击触发的平滑过渡）
  late AnimationController _animController;
  late Animation<double> _levelAnimation;

  /// 当前绘制的动态液位百分比（拖拽时立即对齐，点击时平滑动画过渡）
  double get _displayPercent {
    if (_isDragging) {
      return _currentPercent.toDouble();
    }
    return _levelAnimation.value;
  }

  @override
  void initState() {
    super.initState();
    // 初始百分比：若传入 initialPercentage 则优先采用；若 config.gearCurrent > 1 则采用；
    // 否则在无级变速模式下对齐设计稿（横向 vibration-d 默认 62%，纵向 vibration-c 默认 12%）
    final fallbackDefault =
        widget.fallbackPercentage ??
        (widget.orientation == Axis.vertical ? 12 : 62);
    final initial =
        widget.initialPercentage ??
        (widget.config.gearCurrent != null && widget.config.gearCurrent! > 1
            ? widget.config.gearCurrent!
            : (widget.config.defaultValue > 1
                  ? widget.config.defaultValue
                  : fallbackDefault));
    _currentPercent = initial.clamp(0, 100);
    _lastHapticPercent = _currentPercent;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // 动画完成（填充过渡结束）时触发轻微震动反馈
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.selectionClick();
      }
    });

    _levelAnimation = Tween<double>(
      begin: _currentPercent.toDouble(),
      end: _currentPercent.toDouble(),
    ).animate(_animController);
  }

  @override
  void didUpdateWidget(covariant VariableCapsuleControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPercentage != null &&
        widget.initialPercentage != oldWidget.initialPercentage) {
      _animateToPercent(widget.initialPercentage!, notify: false);
    } else if (widget.config.gearCurrent != null &&
        widget.config.gearCurrent != oldWidget.config.gearCurrent) {
      _animateToPercent(widget.config.gearCurrent!, notify: false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// 点击模式：平滑动画过渡至目标百分比，并在过渡结束时触发触觉反馈
  void _animateToPercent(int newPercent, {bool notify = true}) {
    final clamped = newPercent.clamp(0, 100);
    if (clamped == _currentPercent && !_animController.isAnimating) {
      return;
    }

    _isDragging = false;
    final startVal = _displayPercent;

    setState(() {
      _currentPercent = clamped;
    });

    _animController.stop();
    _levelAnimation = Tween<double>(begin: startVal, end: clamped.toDouble())
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward(from: 0.0);

    if (notify) {
      widget.onValueChanged?.call(clamped);
    }
  }

  /// 水平滑动开始：进入即时连续填充拖拽模式
  void _handleHorizontalDragStart(Offset localPos, double capsuleWidth) {
    _isDragging = true;
    _animController.stop();
    _handleHorizontalDragUpdate(localPos, capsuleWidth);
  }

  /// 水平滑动更新：手指滑动至哪一位置即时跟随，每跨越 5% 产生一次轻微触觉反馈
  void _handleHorizontalDragUpdate(Offset localPos, double capsuleWidth) {
    if (capsuleWidth <= 0) return;
    final clampedX = localPos.dx.clamp(0.0, capsuleWidth);
    final ratio = clampedX / capsuleWidth;
    final targetPercent = (ratio * 100).round().clamp(0, 100);

    if (targetPercent == _currentPercent) {
      return;
    }

    setState(() {
      _currentPercent = targetPercent;
    });

    // 每跨越 5% 产生一次轻微触觉反馈，增强物理滑动质感
    if ((targetPercent % 5 == 0) && targetPercent != _lastHapticPercent) {
      _lastHapticPercent = targetPercent;
      HapticFeedback.selectionClick();
    }

    widget.onValueChanged?.call(targetPercent);
  }

  /// 纵向滑动开始：进入即时连续填充拖拽模式
  void _handleVerticalDragStart(Offset localPos, double capsuleHeight) {
    _isDragging = true;
    _animController.stop();
    _handleVerticalDragUpdate(localPos, capsuleHeight);
  }

  /// 纵向滑动更新：从底部向上计算百分比，每跨越 5% 产生一次轻微触觉反馈
  void _handleVerticalDragUpdate(Offset localPos, double capsuleHeight) {
    if (capsuleHeight <= 0) return;
    final clampedY = localPos.dy.clamp(0.0, capsuleHeight);
    final ratio = 1.0 - (clampedY / capsuleHeight);
    final targetPercent = (ratio * 100).round().clamp(0, 100);

    if (targetPercent == _currentPercent) {
      return;
    }

    setState(() {
      _currentPercent = targetPercent;
    });

    if ((targetPercent % 5 == 0) && targetPercent != _lastHapticPercent) {
      _lastHapticPercent = targetPercent;
      HapticFeedback.selectionClick();
    }

    widget.onValueChanged?.call(targetPercent);
  }

  /// 滑动结束：锁定当前数值
  void _handleDragEnd() {
    _isDragging = false;
    _animController.stop();
    _levelAnimation = AlwaysStoppedAnimation(_currentPercent.toDouble());
    setState(() {});
  }

  /// 水平点击胶囊区域计算目标百分比并平滑过渡
  void _handleHorizontalTap(Offset localPos, double capsuleWidth) {
    if (capsuleWidth <= 0) return;
    final clampedX = localPos.dx.clamp(0.0, capsuleWidth);
    final ratio = clampedX / capsuleWidth;
    final targetPercent = (ratio * 100).round().clamp(0, 100);
    _animateToPercent(targetPercent);
  }

  /// 纵向点击胶囊区域计算目标百分比并平滑过渡
  void _handleVerticalTap(Offset localPos, double capsuleHeight) {
    if (capsuleHeight <= 0) return;
    final clampedY = localPos.dy.clamp(0.0, capsuleHeight);
    final ratio = 1.0 - (clampedY / capsuleHeight);
    final targetPercent = (ratio * 100).round().clamp(0, 100);
    _animateToPercent(targetPercent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isHorizontal = widget.orientation == Axis.horizontal;
    final effectiveHeight = widget.height ?? (isHorizontal ? 135.0 : null);

    Widget card = Container(
      height: effectiveHeight,
      padding: isHorizontal
          ? const EdgeInsets.fromLTRB(14, 12, 15, 14)
          : const EdgeInsets.fromLTRB(16, 16, 16, 18),

      decoration: AppTheme.freeControlBoxDecoration,
      child: isHorizontal
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 顶部 Title、Subtitle 与右侧动态 Gear XX % 指示器
                _buildHorizontalHeader(theme),
                const SizedBox(height: 10),
                // 2. 下部核心横向全宽 Canvas 自绘无级变速发光胶囊
                Expanded(child: _buildHorizontalOperationSection(theme)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 顶部通道图标、Title 与 Subtitle
                _buildVerticalHeader(theme),
                const SizedBox(height: 12),
                // 2. 下部核心操作区（左侧刻度条 + 右侧百分比与 Canvas 自绘竖向胶囊）
                Expanded(child: _buildVerticalOperationSection(theme)),
              ],
            ),
    );

    if (effectiveHeight == null) {
      card = AspectRatio(
        aspectRatio: isHorizontal ? (358.0 / 135.0) : (172.0 / 355.0),
        child: card,
      );
    }

    return card;
  }

  /// 顶部标题栏（横向）：包含通道对应图标、标题、副标题，右侧带动态 Gear XX % 指示器（对齐 vibration-d.png）
  Widget _buildHorizontalHeader(VariableCapsuleTheme theme) {
    return Row(
      children: [
        // 左侧：通道图标与标题、副标题
        Expanded(
          child: Row(
            children: [
              Icon(theme.icon, size: 20, color: theme.iconColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.config.displayLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.titleColor,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Variable Speed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: theme.subtitleColor,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // 右侧：Gear  62 % 动态指示器（当前数值高亮白色粗体）
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
            children: [
              TextSpan(
                text: 'Gear  ',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: theme.valueLabelColor,
                ),
              ),
              TextSpan(
                text: '$_currentPercent %',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.valuePercentColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 顶部标题栏（纵向）：包含通道图标、标题、下方紧跟副标题（对齐 vibration-c.png）
  Widget _buildVerticalHeader(VariableCapsuleTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(theme.icon, size: 22, color: theme.iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.config.displayLabel,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.titleColor,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Variable Speed',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: theme.subtitleColor,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 横向全宽核心操作区域：自绘无级变速发光胶囊控件
  Widget _buildHorizontalOperationSection(VariableCapsuleTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;

        return GestureDetector(
          key: ValueKey('${widget.config.type.name}_variable_capsule_area'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) =>
              _handleHorizontalTap(details.localPosition, totalWidth),
          onHorizontalDragStart: (details) =>
              _handleHorizontalDragStart(details.localPosition, totalWidth),
          onHorizontalDragUpdate: (details) =>
              _handleHorizontalDragUpdate(details.localPosition, totalWidth),
          onHorizontalDragEnd: (_) => _handleDragEnd(),
          onHorizontalDragCancel: () => _handleDragEnd(),
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              return CustomPaint(
                painter: _HorizontalVariableCapsulePainter(
                  animatedPercent: _displayPercent,
                  theme: theme,
                ),
                size: Size(totalWidth, totalHeight),
              );
            },
          ),
        );
      },
    );
  }

  /// 纵向核心操作区域：左侧 100%/细条/0% 刻度 + 右侧百分比与自绘发光胶囊（对齐 vibration-c.png）
  Widget _buildVerticalOperationSection(VariableCapsuleTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左侧：100% 标签 + 细长白色发光条 + 0% 标签
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '100%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.scaleMaxColor,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Container(
                width: 8.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: theme.scaleBarGradientColors,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: Offset.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '0%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.scaleMinColor,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // 右侧：大号百分比数字（居中对齐胶囊上方）+ 竖向自绘发光胶囊
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  '$_currentPercent%',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: theme.valuePercentColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final capsuleWidth = constraints.maxWidth;
                    final capsuleHeight = constraints.maxHeight;

                    return GestureDetector(
                      key: ValueKey(
                        '${widget.config.type.name}_variable_capsule_area',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) => _handleVerticalTap(
                        details.localPosition,
                        capsuleHeight,
                      ),
                      onVerticalDragStart: (details) =>
                          _handleVerticalDragStart(
                            details.localPosition,
                            capsuleHeight,
                          ),
                      onVerticalDragUpdate: (details) =>
                          _handleVerticalDragUpdate(
                            details.localPosition,
                            capsuleHeight,
                          ),
                      onVerticalDragEnd: (_) => _handleDragEnd(),
                      onVerticalDragCancel: () => _handleDragEnd(),
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _VerticalVariableCapsulePainter(
                              animatedPercent: _displayPercent,
                              theme: theme,
                            ),
                            size: Size(capsuleWidth, capsuleHeight),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 横向无级变速胶囊本体及液位辉光 CustomPainter（深度还原 vibration-d.png 与 SVG img_rectangle_110_3.svg 规范）
final class _HorizontalVariableCapsulePainter extends CustomPainter {
  const _HorizontalVariableCapsulePainter({
    required this.animatedPercent,
    required this.theme,
  });

  /// 当前动态平滑百分比（0.0 ~ 100.0）
  final double animatedPercent;

  /// 对应的主题配色与渐变
  final VariableCapsuleTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final capsuleRect = Rect.fromLTWH(0, 0, size.width, size.height);
    // 胶囊圆角半径：严格对齐 SVG 规范（高度 78 时圆角 31 -> 31/78，自适应缩放）
    final radiusVal = (size.height * (31.0 / 78.0)).clamp(0.0, size.height / 2);
    final cornerRadius = Radius.circular(radiusVal);
    final capsuleRRect = RRect.fromRectAndRadius(capsuleRect, cornerRadius);

    // ─────────────────────────────────────────────────────────────────────────
    // 1. 裁剪至胶囊内部区域并绘制未激活槽位暗色背景
    // ─────────────────────────────────────────────────────────────────────────
    canvas.save();
    canvas.clipRRect(capsuleRRect);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: theme.trackGradientColors,
      ).createShader(capsuleRect);
    canvas.drawRect(capsuleRect, bgPaint);

    // ─────────────────────────────────────────────────────────────────────────
    // 2. 绘制激活发光流体（图层 1: 底色横向渐变 + 图层 2: 四周高保真漫反射内阴影）
    // ─────────────────────────────────────────────────────────────────────────
    final fillRatio = (animatedPercent / 100.0).clamp(0.0, 1.0);
    final fillWidth = size.width * fillRatio;

    if (fillWidth > 0.5) {
      final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
      final isFull = animatedPercent >= 100.0;

      // 构造当前横向填充区域的精准几何 Path（左侧为半径 31 圆角，右侧为竖向平切线；满格时右侧带圆角）
      // 深度复刻 SVG 路径：d="M0 31C0 13.8792 13.8792 0 31 0H204V78H31C13.8792 78 0 64.1208 0 47V31Z"
      final leftCapR = radiusVal.clamp(0.0, fillWidth / 2);
      final leftRadius = Radius.circular(leftCapR);
      final liquidRRect = RRect.fromRectAndCorners(
        fillRect,
        topLeft: leftRadius,
        bottomLeft: leftRadius,
        topRight: isFull ? cornerRadius : Radius.zero,
        bottomRight: isFull ? cornerRadius : Radius.zero,
      );
      final liquidPath = Path()..addRRect(liquidRRect);

      canvas.save();
      canvas.clipPath(liquidPath);

      // 图层 1：横向线性渐变底色（对应 SVG paint0_linear_184_726: 左 #B5A9EA -> 右 #4A3BBD）
      final baseGradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: theme.liquidGradientColors,
          stops: theme.liquidGradientStops,
        ).createShader(fillRect);
      canvas.drawRect(fillRect, baseGradientPaint);

      // 图层 2：四周深度漫反射内阴影（精准还原 SVG filter0_i_184_726: stdDeviation="13", feColorMatrix 0.6 白）
      final deepBlurSigma = (13.0 * (size.height / 78.0)).clamp(1.0, 50.0);
      final ambientBlurSigma = (24.0 * (size.height / 78.0)).clamp(1.0, 80.0);
      final bounds = fillRect.inflate(ambientBlurSigma * 3);
      final invertedPath = Path()
        ..addRect(bounds)
        ..addPath(liquidPath, Offset.zero)
        ..fillType = PathFillType.evenOdd;

      // 1) 主体内阴影漫反射（高亮白向内自然渗透）
      final deepShadowPaint = Paint()
        ..color = theme.innerGlowColor.withValues(alpha: 0.60)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, deepBlurSigma);
      canvas.drawPath(invertedPath, deepShadowPaint);

      // 2) 广域柔和环境光晕（淡粉紫氛围柔光融入流体中心）
      final ambientShadowPaint = Paint()
        ..color = theme.ambientGlowColor.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ambientBlurSigma);
      canvas.drawPath(invertedPath, ambientShadowPaint);

      canvas.restore();
    }

    canvas.restore();

    // ─────────────────────────────────────────────────────────────────────────
    // 3. 绘制胶囊外层玻璃反光与半透描边（Frosted Glass Rim）
    // ─────────────────────────────────────────────────────────────────────────
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = theme.capsuleBorderColor;

    canvas.drawRRect(capsuleRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _HorizontalVariableCapsulePainter oldDelegate) {
    return oldDelegate.animatedPercent != animatedPercent ||
        oldDelegate.theme != theme;
  }
}

/// 纵向无级变速胶囊本体及液位辉光 CustomPainter（深度还原 vibration-c.png 规范）
final class _VerticalVariableCapsulePainter extends CustomPainter {
  const _VerticalVariableCapsulePainter({
    required this.animatedPercent,
    required this.theme,
  });

  /// 当前动态平滑百分比（0.0 ~ 100.0）
  final double animatedPercent;

  /// 对应的主题配色与渐变
  final VariableCapsuleTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final capsuleRect = Rect.fromLTWH(0, 0, size.width, size.height);
    // 胶囊圆角半径：严格对齐设计稿 31/106 规格，自适应缩放
    final radiusVal = (size.width * (31.0 / 106.0)).clamp(0.0, size.width / 2);
    final cornerRadius = Radius.circular(radiusVal);
    final capsuleRRect = RRect.fromRectAndRadius(capsuleRect, cornerRadius);

    // ─────────────────────────────────────────────────────────────────────────
    // 1. 裁剪至胶囊内部区域并绘制未激活槽位暗色背景
    // ─────────────────────────────────────────────────────────────────────────
    canvas.save();
    canvas.clipRRect(capsuleRRect);

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: theme.trackGradientColors,
      ).createShader(capsuleRect);
    canvas.drawRect(capsuleRect, bgPaint);

    // ─────────────────────────────────────────────────────────────────────────
    // 2. 绘制激活发光流体（从底部向上填充，顶部平切，底部圆角与胶囊完全贴合）
    // ─────────────────────────────────────────────────────────────────────────
    final fillRatio = (animatedPercent / 100.0).clamp(0.0, 1.0);
    final fillHeight = size.height * fillRatio;

    if (fillHeight > 0.5) {
      final fillTopY = size.height - fillHeight;
      final fillRect = Rect.fromLTWH(0, fillTopY, size.width, fillHeight);
      final isFull = animatedPercent >= 100.0;

      // 构造当前填充区域的精准几何 Path（底部圆角与胶囊重合，顶部平切；满格时顶部带圆角）
      final bottomCapR = radiusVal.clamp(0.0, fillHeight / 2);
      final bottomRadius = Radius.circular(bottomCapR);
      final liquidRRect = RRect.fromRectAndCorners(
        fillRect,
        topLeft: isFull ? cornerRadius : Radius.zero,
        topRight: isFull ? cornerRadius : Radius.zero,
        bottomLeft: bottomRadius,
        bottomRight: bottomRadius,
      );
      final liquidPath = Path()..addRRect(liquidRRect);

      canvas.save();
      canvas.clipPath(liquidPath);

      // 图层 1：纵向线性渐变底色（顶部平切边缘电光紫 #4A3BBD -> 底部浅紫罗兰 #B5A9EA）
      final baseGradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.liquidGradientColors,
          stops: theme.liquidGradientStops,
        ).createShader(fillRect);
      canvas.drawRect(fillRect, baseGradientPaint);

      // 图层 2：四周深度漫反射内阴影（对应 SVG feGaussianBlur stdDeviation="13" 与 feColorMatrix 0.6 白）
      final deepBlurSigma = (13.0 * (size.width / 106.0)).clamp(1.0, 40.0);
      final ambientBlurSigma = (24.0 * (size.width / 106.0)).clamp(1.0, 60.0);
      final bounds = fillRect.inflate(ambientBlurSigma * 3);
      final invertedPath = Path()
        ..addRect(bounds)
        ..addPath(liquidPath, Offset.zero)
        ..fillType = PathFillType.evenOdd;

      // 1) 主体内阴影漫反射
      final deepShadowPaint = Paint()
        ..color = theme.innerGlowColor.withValues(alpha: 0.60)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, deepBlurSigma);
      canvas.drawPath(invertedPath, deepShadowPaint);

      // 2) 广域柔和环境光晕
      final ambientShadowPaint = Paint()
        ..color = theme.ambientGlowColor.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ambientBlurSigma);
      canvas.drawPath(invertedPath, ambientShadowPaint);

      canvas.restore();
    }

    canvas.restore();

    // ─────────────────────────────────────────────────────────────────────────
    // 3. 绘制胶囊外层玻璃半透描边（Frosted Glass Rim）
    // ─────────────────────────────────────────────────────────────────────────
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = theme.capsuleBorderColor;

    canvas.drawRRect(capsuleRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _VerticalVariableCapsulePainter oldDelegate) {
    return oldDelegate.animatedPercent != animatedPercent ||
        oldDelegate.theme != theme;
  }
}
