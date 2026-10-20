// 自由控制分档胶囊通用控件（Stepped Capsule Control）；
// 基于 Canvas 自绘深度还原设备控制卡片视觉规范，支持伸缩（电光蓝）与震动（电光洋红）等通道主题、
// 动态档位数解析、触控选档/手势拖拽、深层漫反射柔光雾与平滑物理缓动动画。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../domain/entities/free_control_layout.dart';

/// 分档胶囊组件视觉主题配置
final class SteppedCapsuleTheme {
  /// 创建分档胶囊视觉主题。
  const SteppedCapsuleTheme({
    required this.icon,
    required this.iconColor,
    required this.cardGradientColors,
    required this.cardBorderColor,
    required this.unlitSlotGradientColors,
    required this.unlitDividerColor,
    required this.liquidGradientColors,
    this.liquidGradientStops,
    required this.liquidDividerColor,
    required this.deepShadowColor,
    required this.ambientShadowColor,
    required this.capsuleBorderColor,
    required this.activeNumberColor,
    required this.activeNumberGlowColor,
    required this.inactiveNumberColor,
  });

  /// 顶部标题图标
  final IconData icon;

  /// 图标色值
  final Color iconColor;

  /// 外层卡片渐变色 [顶部色, 底部色]
  final List<Color> cardGradientColors;

  /// 外层卡片边框色
  final Color cardBorderColor;

  /// 胶囊未激活槽位渐变色
  final List<Color> unlitSlotGradientColors;

  /// 未激活槽位分割线色值
  final Color unlitDividerColor;

  /// 激活流体纵向线性渐变色值
  final List<Color> liquidGradientColors;

  /// 激活流体纵向渐变 stops（可选）
  final List<double>? liquidGradientStops;

  /// 激活流体内部的分割线色值
  final Color liquidDividerColor;

  /// 深层漫反射主体柔光色值（通常为白色或高亮色）
  final Color deepShadowColor;

  /// 外围氛围漫反射柔光色值（带色系倾向的淡雾色）
  final Color ambientShadowColor;

  /// 胶囊外壳描边轮廓色值
  final Color capsuleBorderColor;

  /// 当前激活档位数字颜色
  final Color activeNumberColor;

  /// 当前激活档位数字发光阴影色
  final Color activeNumberGlowColor;

  /// 未激活档位数字颜色
  final Color inactiveNumberColor;

  /// 伸缩通道（对齐 thrust-a.png）电光蓝主题规范
  static const SteppedCapsuleTheme telescopic = SteppedCapsuleTheme(
    icon: Icons.swap_vert_rounded,
    iconColor: Color(0xFFA5A4DE),
    cardGradientColors: [
      Color(0xFF2C276E), // 饱和紫靛蓝顶色
      Color(0xFF24205C), // 深邃紫靛蓝底色
    ],
    cardBorderColor: Color(0x299E9FC8), // 0xFF9E9FC8 with alpha 0.16
    unlitSlotGradientColors: [Color(0xFF3F4093), Color(0xFF3A3B8B)],
    unlitDividerColor: Color(0xFF28287F),
    liquidGradientColors: [
      Color(0xFF1A37A1), // SVG #1A37A1
      Color(0xFF1590DC), // SVG #1590DC
    ],
    liquidGradientStops: null,
    liquidDividerColor: Color(0x6B144D9C), // 0xFF144D9C with alpha 0.42
    deepShadowColor: Colors.white,
    ambientShadowColor: Color(0xFFC8E6FF),
    capsuleBorderColor: Color(0x8C9E9FC8), // 0xFF9E9FC8 with alpha 0.55
    activeNumberColor: Colors.white,
    activeNumberGlowColor: Color(0x80FFFFFF),
    inactiveNumberColor: Color(0xFF6B6AA4),
  );

  /// 震动通道（对齐 vibration-a.png）电光洋红紫主题规范
  static const SteppedCapsuleTheme vibration = SteppedCapsuleTheme(
    icon: Icons.vibration_rounded,
    iconColor: Color(0xFFFDC5FF),
    cardGradientColors: [
      Color(0xFF383371), // 顶色浓郁靛紫
      Color(0xFF2C275F), // 底色深邃紫
    ],
    cardBorderColor: Color(0x29B5A4D0),
    unlitSlotGradientColors: [Color(0xFF4C3D73), Color(0xFF423567)],
    unlitDividerColor: Color(0xFF382863),
    liquidGradientColors: [
      Color(0xFF9828B0), // 顶部浓郁洋红紫
      Color(0xFFBA45D0), // 中部饱和电光紫
      Color(0xFFE57BF3), // 底部高亮兰花粉
    ],
    liquidGradientStops: [0.0, 0.45, 1.0],
    liquidDividerColor: Color(0x618E21A4),
    deepShadowColor: Colors.white,
    ambientShadowColor: Color(0xFFFFDCFE),
    capsuleBorderColor: Color(0x8CB5A4D0),
    activeNumberColor: Colors.white,
    activeNumberGlowColor: Color(0x8CFDC5FF),
    inactiveNumberColor: Color(0xFF7A6A99),
  );

  /// 震动横向通道（对齐 vibration-b.png）电光靛青蓝主题规范
  static const SteppedCapsuleTheme vibrationHorizontal = SteppedCapsuleTheme(
    icon: Icons.vibration_rounded,
    iconColor: Color(0xFFA8AEFF), // 软粉紫靛蓝
    cardGradientColors: [
      Color(0xFF2B2A7E), // 顶左沉稳靛蓝
      Color(0xFF3B276F), // 底右深邃暗紫
    ],
    cardBorderColor: Color(0x29A4B5FC),
    unlitSlotGradientColors: [
      Color(0xFF493D83), // 未激活槽位左侧
      Color(0xFF4D3C70), // 未激活槽位右侧
    ],
    unlitDividerColor: Color(0xFF382870),
    liquidGradientColors: [
      Color(0xFF5868C6), // 左侧明朗电光青靛
      Color(0xFF4A5AB4), // 中部饱和电光蓝
      Color(0xFF2E3D9E), // 右侧深邃宝蓝
    ],
    liquidGradientStops: [0.0, 0.5, 1.0],
    liquidDividerColor: Color(0x521A2870),
    deepShadowColor: Colors.white,
    ambientShadowColor: Color(0xFFC5CBFF),
    capsuleBorderColor: Color(0x8C9894BB),
    activeNumberColor: Colors.white,
    activeNumberGlowColor: Color(0x80FFFFFF),
    inactiveNumberColor: Color(0xFF7E87F8),
  );

  /// 伸缩横向通道（对齐 thrust-b.png）电光紫罗兰主题规范
  static const SteppedCapsuleTheme telescopicHorizontal = SteppedCapsuleTheme(
    icon: Icons.swap_vert_rounded,
    iconColor: Color(0xFFDBA8FF), // 软粉兰花浅紫
    cardGradientColors: [
      Color(0xFF262568), // 顶左沉稳深紫靛
      Color(0xFF5C4E70), // 底右温暖暗紫茄色
    ],
    cardBorderColor: Color(0x29AFA4C8),
    unlitSlotGradientColors: [
      Color(0xFF504475), // 未激活槽位左侧暗紫
      Color(0xFF6A5A7B), // 未激活槽位右侧柔紫
    ],
    unlitDividerColor: Color(0xFF483A64),
    liquidGradientColors: [
      Color(0xFF5E4CCD), // 左侧浓郁电光紫蓝
      Color(0xFF7A65D2), // 中部饱和电光紫罗兰
      Color(0xFFA28DDB), // 右侧明亮高光紫
    ],
    liquidGradientStops: [0.0, 0.5, 1.0],
    liquidDividerColor: Color(0x5248388C),
    deepShadowColor: Colors.white,
    ambientShadowColor: Color(0xFFDACBFF),
    capsuleBorderColor: Color(0x8C9C96B7),
    activeNumberColor: Colors.white,
    activeNumberGlowColor: Color(0x80FFFFFF),
    inactiveNumberColor: Color(0xFF7E87F8),
  );
}

/// 通用分档胶囊控制组件
final class SteppedCapsuleControl extends StatefulWidget {
  /// 创建通用分档胶囊卡片组件。
  const SteppedCapsuleControl({
    super.key,
    required this.config,
    this.orientation = Axis.vertical,
    this.theme = SteppedCapsuleTheme.telescopic,
    this.onGearChanged,
    this.height,
  });

  /// 模块配置（包含后台下发的档位数 gearMax、当前档位 gearCurrent、标签等）
  final FreeControlComponentConfig config;

  /// 胶囊控件方向（竖向 Axis.vertical 对齐 3x1 规格；横向 Axis.horizontal 对齐 1x2 规格）
  final Axis orientation;

  /// 视觉主题（伸缩 / 震动）
  final SteppedCapsuleTheme theme;

  /// 档位变动回调
  final ValueChanged<int>? onGearChanged;

  /// 外部约束的固定高度
  final double? height;

  @override
  State<SteppedCapsuleControl> createState() => _SteppedCapsuleControlState();
}

class _SteppedCapsuleControlState extends State<SteppedCapsuleControl>
    with SingleTickerProviderStateMixin {
  /// 最小档位数（由后端能力配置驱动，默认 1）
  int get _gearMin => widget.config.gearMin;

  /// 最大档位数（由后端能力配置驱动，若未配置默认兜底 6 档）
  int get _gearMax => widget.config.gearMax ?? 6;

  /// 档位格子总数
  int get _totalSlots => (_gearMax - _gearMin + 1).clamp(1, 100);

  /// 当前选中的档位（_gearMin ~ _gearMax）
  late int _currentGear;

  /// 是否正在手势滑动拖拽中
  bool _isDragging = false;

  /// 液位平滑过渡动画控制器（用于点击触发的平滑过渡）
  late AnimationController _animController;
  late Animation<double> _levelAnimation;

  /// 当前实时绘制的液位值（拖拽时立即对齐到当前档位整数，杜绝残缺未填满现象）
  double get _displayLevel {
    if (_isDragging) {
      return _currentGear.toDouble();
    }
    return _levelAnimation.value;
  }

  @override
  void initState() {
    super.initState();
    // 初始档位：优先使用 gearCurrent，其次 defaultValue（服务端配置），兜底默认 3 档
    final initialGear = widget.config.gearCurrent ?? widget.config.defaultValue;
    _currentGear = initialGear.clamp(_gearMin, _gearMax);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // 动画完成（填充结束）时才触发点击震动反馈
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.selectionClick();
      }
    });

    _levelAnimation = Tween<double>(
      begin: _currentGear.toDouble(),
      end: _currentGear.toDouble(),
    ).animate(_animController);
  }

  @override
  void didUpdateWidget(covariant SteppedCapsuleControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.config.gearCurrent != null &&
        widget.config.gearCurrent != oldWidget.config.gearCurrent) {
      _animateToGear(widget.config.gearCurrent!, notify: false);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// 点击模式：平滑动画过渡至目标档位，并在填充完成时触发震动
  void _animateToGear(int newGear, {bool notify = true}) {
    final clamped = newGear.clamp(_gearMin, _gearMax);
    if (clamped == _currentGear && !_animController.isAnimating) {
      return;
    }

    _isDragging = false;
    final startVal = _displayLevel;

    setState(() {
      _currentGear = clamped;
    });

    _animController.stop();
    _levelAnimation = Tween<double>(begin: startVal, end: clamped.toDouble())
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward(from: 0.0);

    if (notify) {
      widget.onGearChanged?.call(clamped);
    }
  }

  /// 滑动开始：进入即时填充拖拽模式
  void _handleDragStart(Offset localPos, double capsuleHeight) {
    _isDragging = true;
    _animController.stop();
    _handleDragUpdate(localPos, capsuleHeight);
  }

  /// 滑动更新：手指处于哪个格子区间，就立即填充满该区间，且仅在跨档位时震动一次
  void _handleDragUpdate(Offset localPos, double capsuleHeight) {
    if (capsuleHeight <= 0) return;
    final clampedY = localPos.dy.clamp(0.0, capsuleHeight);
    final ratioFromBottom = 1.0 - (clampedY / capsuleHeight);
    final slotIndex = (ratioFromBottom * _totalSlots).ceil().clamp(
      1,
      _totalSlots,
    );
    final targetGear = _gearMin + slotIndex - 1;

    // 若手指仍在当前档位格子区间内，不重复触发震动与重绘
    if (targetGear == _currentGear) {
      return;
    }

    // 跨入新格子：立即填充满该区间并震动一次
    setState(() {
      _currentGear = targetGear;
    });

    HapticFeedback.selectionClick();
    widget.onGearChanged?.call(targetGear);
  }

  /// 滑动结束：确保档位完全锁定并对齐
  void _handleDragEnd() {
    _isDragging = false;
    _animController.stop();
    _levelAnimation = AlwaysStoppedAnimation(_currentGear.toDouble());
    setState(() {});
  }

  /// 点击胶囊区域计算目标档位并平滑过渡（竖向）
  void _handleTap(Offset localPos, double capsuleHeight) {
    if (capsuleHeight <= 0) return;
    final clampedY = localPos.dy.clamp(0.0, capsuleHeight);
    final ratioFromBottom = 1.0 - (clampedY / capsuleHeight);
    final slotIndex = (ratioFromBottom * _totalSlots).ceil().clamp(
      1,
      _totalSlots,
    );
    final targetGear = _gearMin + slotIndex - 1;
    _animateToGear(targetGear);
  }

  /// 水平滑动开始：进入即时填充拖拽模式
  void _handleHorizontalDragStart(Offset localPos, double capsuleWidth) {
    _isDragging = true;
    _animController.stop();
    _handleHorizontalDragUpdate(localPos, capsuleWidth);
  }

  /// 水平滑动更新：手指处于哪个格子区间，就立即填充满该区间，且仅在跨档位时震动一次
  void _handleHorizontalDragUpdate(Offset localPos, double capsuleWidth) {
    if (capsuleWidth <= 0) return;
    final clampedX = localPos.dx.clamp(0.0, capsuleWidth);
    final ratioFromLeft = clampedX / capsuleWidth;
    final slotIndex = (ratioFromLeft * _totalSlots).ceil().clamp(
      1,
      _totalSlots,
    );
    final targetGear = _gearMin + slotIndex - 1;

    // 若手指仍在当前档位格子区间内，不重复触发震动与重绘
    if (targetGear == _currentGear) {
      return;
    }

    // 跨入新格子：立即填充满该区间并震动一次
    setState(() {
      _currentGear = targetGear;
    });

    HapticFeedback.selectionClick();
    widget.onGearChanged?.call(targetGear);
  }

  /// 水平点击胶囊区域计算目标档位并平滑过渡
  void _handleHorizontalTap(Offset localPos, double capsuleWidth) {
    if (capsuleWidth <= 0) return;
    final clampedX = localPos.dx.clamp(0.0, capsuleWidth);
    final ratioFromLeft = clampedX / capsuleWidth;
    final slotIndex = (ratioFromLeft * _totalSlots).ceil().clamp(
      1,
      _totalSlots,
    );
    final targetGear = _gearMin + slotIndex - 1;
    _animateToGear(targetGear);
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
          : const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: AppTheme.freeControlBoxDecoration,
      child: isHorizontal
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. 顶部 Title 与右侧动态 Gear 档位指示
                _buildHorizontalHeader(theme),
                const SizedBox(height: 10),
                // 2. 下部核心横向全宽 Canvas 自绘发光胶囊
                Expanded(child: _buildHorizontalOperationSection(theme)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 顶部小 Title 区域
                _buildHeader(theme),
                const SizedBox(height: 16),
                // 2. 下部核心操作区域（左侧档位数字 + 右侧 Canvas 自绘胶囊光柱）
                Expanded(child: _buildOperationSection(theme)),
              ],
            ),
    );

    if (effectiveHeight == null) {
      card = AspectRatio(aspectRatio: 172.0 / 312.0, child: card);
    }

    return card;
  }

  /// 顶部标题栏（竖向）：包含通道对应图标与标题文本
  Widget _buildHeader(SteppedCapsuleTheme theme) {
    return Row(
      children: [
        Icon(theme.icon, size: 22, color: theme.iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.config.displayLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 顶部标题栏（横向）：包含通道对应图标与标题，右侧带动态 Gear X / Y 指示器（对齐 vibration-b.png）
  Widget _buildHorizontalHeader(SteppedCapsuleTheme theme) {
    return Row(
      children: [
        // 左侧：通道图标与标题（支持超长文本自适应收缩）
        Expanded(
          child: Row(
            children: [
              Icon(theme.icon, size: 20, color: theme.iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.config.displayLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
        // 右侧：Gear  X / Y 动态档位文本（当前档位高亮白色，最大档位淡紫）
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
            children: [
              const TextSpan(
                text: 'Gear  ',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: '$_currentGear',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: ' / ',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: theme.inactiveNumberColor,
                ),
              ),
              TextSpan(
                text: '$_gearMax',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: theme.inactiveNumberColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 横向全宽核心操作区域：自绘发光胶囊格子控件
  Widget _buildHorizontalOperationSection(SteppedCapsuleTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;

        return GestureDetector(
          key: ValueKey('${widget.config.type.name}_horizontal_capsule_area'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {},
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
              final animatedSlots = (_displayLevel - _gearMin + 1).clamp(
                0.0,
                _totalSlots.toDouble(),
              );
              return CustomPaint(
                painter: _HorizontalSteppedCapsulePainter(
                  totalSlots: _totalSlots,
                  animatedSlots: animatedSlots,
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

  /// 核心操作区域（竖向）：左侧对齐的数字档位与右侧全高自绘发光胶囊
  Widget _buildOperationSection(SteppedCapsuleTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左侧：gearMin ~ gearMax 档位数字（自上而下从 gearMax 到 gearMin，精确垂直居中于每个格子）
            SizedBox(
              width: 28,
              child: Column(
                children: List.generate(_totalSlots, (index) {
                  // 自上而下排列：顶部为 _gearMax，底部为 _gearMin
                  final gearNumber = _gearMax - index;
                  final isSelected = gearNumber == _currentGear;

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _animateToGear(gearNumber),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          style: TextStyle(
                            fontSize: isSelected ? 17 : 15,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected
                                ? theme.activeNumberColor
                                : theme.inactiveNumberColor,
                            shadows: isSelected
                                ? [
                                    BoxShadow(
                                      color: theme.activeNumberGlowColor,
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text('$gearNumber'),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(width: 8),
            // 右侧：全宽填充的自绘发光胶囊格子控件
            Expanded(
              child: GestureDetector(
                key: widget.config.type == FreeControlComponentType.telescopic
                    ? const ValueKey('telescopic_capsule_area')
                    : const ValueKey('vibration_capsule_area'),
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) {},
                onTapUp: (details) =>
                    _handleTap(details.localPosition, totalHeight),
                onVerticalDragStart: (details) =>
                    _handleDragStart(details.localPosition, totalHeight),
                onVerticalDragUpdate: (details) =>
                    _handleDragUpdate(details.localPosition, totalHeight),
                onVerticalDragEnd: (_) => _handleDragEnd(),
                onVerticalDragCancel: () => _handleDragEnd(),
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, _) {
                    final animatedSlots = (_displayLevel - _gearMin + 1).clamp(
                      0.0,
                      _totalSlots.toDouble(),
                    );
                    return CustomPaint(
                      painter: _SteppedCapsulePainter(
                        totalSlots: _totalSlots,
                        animatedSlots: animatedSlots,
                        theme: theme,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 胶囊本体及液位辉光 CustomPainter（深度还原 thrust-a.png 与 vibration-a.png 规范）
final class _SteppedCapsulePainter extends CustomPainter {
  const _SteppedCapsulePainter({
    required this.totalSlots,
    required this.animatedSlots,
    required this.theme,
  });

  /// 总档位（格子数）
  final int totalSlots;

  /// 当前动态平滑液位对应格数（0.0 ~ totalSlots）
  final double animatedSlots;

  /// 对应的主题配色与渐变
  final SteppedCapsuleTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final capsuleRect = Rect.fromLTWH(0, 0, size.width, size.height);
    // 胶囊圆角半径：严格对齐设计师 SVG 规格（宽 116，下部圆角 31 -> 31/116）
    final cornerRadius = Radius.circular(size.width * (31.0 / 116.0));
    final capsuleRRect = RRect.fromRectAndRadius(capsuleRect, cornerRadius);

    // ─────────────────────────────────────────────────────────────────────────
    // 1. 裁剪至胶囊内部区域并绘制未激活槽位底色
    // ─────────────────────────────────────────────────────────────────────────
    canvas.save();
    canvas.clipRRect(capsuleRRect);

    // 未激活槽位背景底色
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: theme.unlitSlotGradientColors,
      ).createShader(capsuleRect);
    canvas.drawRect(capsuleRect, bgPaint);

    // ─────────────────────────────────────────────────────────────────────────
    // 2. 绘制激活发光流体（图层 1: 底色线性渐变 + 图层 2: 边缘深层内漫反射柔雾）
    // ─────────────────────────────────────────────────────────────────────────
    final fillRatio = (animatedSlots / totalSlots).clamp(0.0, 1.0);
    final fillHeight = size.height * fillRatio;
    final fillTopY = size.height - fillHeight;

    if (fillHeight > 0.5) {
      final fillRect = Rect.fromLTWH(0, fillTopY, size.width, fillHeight);
      final isFull = animatedSlots >= totalSlots;

      // 构造当前填充区域的精准几何 Path（顶部平切，底部圆角与胶囊完全重合）
      final Path liquidPath;
      if (isFull) {
        liquidPath = Path()..addRRect(capsuleRRect);
      } else {
        liquidPath = Path()
          ..moveTo(0, fillTopY)
          ..lineTo(size.width, fillTopY)
          ..lineTo(size.width, size.height - cornerRadius.y)
          ..arcToPoint(
            Offset(size.width - cornerRadius.x, size.height),
            radius: cornerRadius,
          )
          ..lineTo(cornerRadius.x, size.height)
          ..arcToPoint(
            Offset(0, size.height - cornerRadius.y),
            radius: cornerRadius,
          )
          ..close();
      }

      canvas.save();
      canvas.clipPath(liquidPath);

      // 图层 1：底色纵向线性渐变
      final baseGradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: theme.liquidGradientColors,
          stops: theme.liquidGradientStops,
        ).createShader(fillRect);
      canvas.drawRect(fillRect, baseGradientPaint);

      // 图层 2：边缘深层漫反射（对齐 Figma 设计：大范围向内渗透 30%~35%）
      final deepBlurSigma = size.width * 0.22; // 核心漫反射层（深度向内弥散）
      final ambientBlurSigma = size.width * 0.35; // 外围超广角光雾过渡层
      final bounds = fillRect.inflate(ambientBlurSigma * 3);
      final invertedPath = Path()
        ..addRect(bounds)
        ..addPath(liquidPath, Offset.zero)
        ..fillType = PathFillType.evenOdd;

      // 1) 深层主体漫反射：高显色度向内渗透 30% 空间，与底色渐变充分融合
      final deepShadowPaint = Paint()
        ..color = theme.deepShadowColor.withValues(alpha: 0.82)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, deepBlurSigma);
      canvas.drawPath(invertedPath, deepShadowPaint);

      // 2) 超广域氛围光晕：柔和淡出至中间核心区域
      final ambientShadowPaint = Paint()
        ..color = theme.ambientShadowColor.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ambientBlurSigma);
      canvas.drawPath(invertedPath, ambientShadowPaint);

      canvas.restore();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. 绘制档位分隔线（横向暗线，将胶囊划分为 N 个等高格子）
    // ─────────────────────────────────────────────────────────────────────────
    const dividerThickness = 2.5;

    for (var i = 1; i < totalSlots; i++) {
      final dividerY = size.height * (1.0 - i / totalSlots);
      final isInsideFill = dividerY > fillTopY + 1.0;

      // 位于高亮液面内部时，使用对应色系的柔和半透线自然融入流体；未激活区域使用深暗线
      final dividerColor = isInsideFill
          ? theme.liquidDividerColor
          : theme.unlitDividerColor;

      final dividerPaint = Paint()
        ..color = dividerColor
        ..strokeWidth = dividerThickness
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(0, dividerY),
        Offset(size.width, dividerY),
        dividerPaint,
      );
    }

    canvas.restore();

    // ─────────────────────────────────────────────────────────────────────────
    // 4. 绘制胶囊外层玻璃反光与半透描边（Frosted Glass Rim）
    // ─────────────────────────────────────────────────────────────────────────
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = theme.capsuleBorderColor;

    canvas.drawRRect(capsuleRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SteppedCapsulePainter oldDelegate) {
    return oldDelegate.totalSlots != totalSlots ||
        oldDelegate.animatedSlots != animatedSlots ||
        oldDelegate.theme != theme;
  }
}

/// 横向胶囊本体及液位辉光 CustomPainter（深度还原 vibration-b.png 设计规范）
final class _HorizontalSteppedCapsulePainter extends CustomPainter {
  const _HorizontalSteppedCapsulePainter({
    required this.totalSlots,
    required this.animatedSlots,
    required this.theme,
  });

  /// 总档位（格子数）
  final int totalSlots;

  /// 当前动态平滑液位对应格数（0.0 ~ totalSlots）
  final double animatedSlots;

  /// 对应的主题配色与渐变
  final SteppedCapsuleTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final capsuleRect = Rect.fromLTWH(0, 0, size.width, size.height);
    // 胶囊圆角半径：严格对齐设计稿规格（高度 80 时圆角 31 -> 31/80，自适应缩放）
    final radiusVal = (size.height * (31.0 / 80.0)).clamp(0.0, size.height / 2);
    final cornerRadius = Radius.circular(radiusVal);
    final capsuleRRect = RRect.fromRectAndRadius(capsuleRect, cornerRadius);

    // ─────────────────────────────────────────────────────────────────────────
    // 1. 裁剪至胶囊内部区域并绘制未激活槽位底色
    // ─────────────────────────────────────────────────────────────────────────
    canvas.save();
    canvas.clipRRect(capsuleRRect);

    // 未激活槽位背景底色（横向渐变）
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: theme.unlitSlotGradientColors,
      ).createShader(capsuleRect);
    canvas.drawRect(capsuleRect, bgPaint);

    // ─────────────────────────────────────────────────────────────────────────
    // 2. 绘制激活发光流体（图层 1: 底色横向渐变 + 图层 2: 四周深层漫反射柔雾）
    // ─────────────────────────────────────────────────────────────────────────
    final fillRatio = (animatedSlots / totalSlots).clamp(0.0, 1.0);
    final fillWidth = size.width * fillRatio;

    if (fillWidth > 0.5) {
      final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
      final isFull = animatedSlots >= totalSlots;

      // 构造当前横向填充区域的精准几何 Path（左侧为圆角帽，右侧为竖向平切线）
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

      // 图层 1：横向线性渐变底色
      final baseGradientPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: theme.liquidGradientColors,
          stops: theme.liquidGradientStops,
        ).createShader(fillRect);
      canvas.drawRect(fillRect, baseGradientPaint);

      // 图层 2：四周深层漫反射（对齐 Figma 设计：大范围向内渗透 30%~35%）
      // 横向胶囊由于短轴在高度（height），漫反射以 height 作为基准空间
      final deepBlurSigma = size.height * 0.22;
      final ambientBlurSigma = size.height * 0.35;
      final bounds = fillRect.inflate(ambientBlurSigma * 3);
      final invertedPath = Path()
        ..addRect(bounds)
        ..addPath(liquidPath, Offset.zero)
        ..fillType = PathFillType.evenOdd;

      // 1) 深层主体漫反射：高显色度向内渗透 30% 空间，与底色渐变充分融合
      final deepShadowPaint = Paint()
        ..color = theme.deepShadowColor.withValues(alpha: 0.82)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, deepBlurSigma);
      canvas.drawPath(invertedPath, deepShadowPaint);

      // 2) 超广域氛围光晕：柔和淡出至中间核心区域
      final ambientShadowPaint = Paint()
        ..color = theme.ambientShadowColor.withValues(alpha: 0.38)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, ambientBlurSigma);
      canvas.drawPath(invertedPath, ambientShadowPaint);

      canvas.restore();
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. 绘制档位分隔线（纵向分割线，将胶囊划分为 N 个等宽格子）
    // ─────────────────────────────────────────────────────────────────────────
    const dividerThickness = 2.5;

    for (var i = 1; i < totalSlots; i++) {
      final dividerX = size.width * (i / totalSlots);
      final isInsideFill = dividerX < fillWidth - 1.0;

      final dividerColor = isInsideFill
          ? theme.liquidDividerColor
          : theme.unlitDividerColor;

      final dividerPaint = Paint()
        ..color = dividerColor
        ..strokeWidth = dividerThickness
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(dividerX, 0),
        Offset(dividerX, size.height),
        dividerPaint,
      );
    }

    canvas.restore();

    // ─────────────────────────────────────────────────────────────────────────
    // 4. 绘制胶囊外层玻璃反光与半透描边（Frosted Glass Rim）
    // ─────────────────────────────────────────────────────────────────────────
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = theme.capsuleBorderColor;

    canvas.drawRRect(capsuleRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _HorizontalSteppedCapsulePainter oldDelegate) {
    return oldDelegate.totalSlots != totalSlots ||
        oldDelegate.animatedSlots != animatedSlots ||
        oldDelegate.theme != theme;
  }
}
