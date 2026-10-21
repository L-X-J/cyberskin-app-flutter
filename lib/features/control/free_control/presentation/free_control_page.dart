// 自由控制主页面：根据后端返回的数据动态排列组件。
// 支持类似 CoordinatorLayout 的可折叠悬浮头部与高斯模糊背景。

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/widgets/app_scaffold.dart';
import '../../../../core/theme/app_blur.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_lottie_background.dart';
import 'free_control_controller.dart';
import 'widgets/free_control_layout_builder.dart';
import 'widgets/free_control_title.dart';

/// 自由控制主页面
///
/// 具备类似 Android CoordinatorLayout 的可折叠悬浮头部：
/// - 头部悬浮在页面顶端，随列表滑动动态折叠与展开
/// - 列表向上滑动时，大标题平滑横向居中收敛至顶栏，副标题渐隐
/// - 折叠过程中背景逐渐应用高斯模糊磨砂效果，列表内容平滑穿过其下方
/// - 此页面不显示全局设备状态浮窗（policy: hidden）
final class FreeControlPage extends StatefulWidget {
  /// 创建自由控制主页面实例
  const FreeControlPage({super.key});

  @override
  State<FreeControlPage> createState() => _FreeControlPageState();
}

final class _FreeControlPageState extends State<FreeControlPage> {
  final FreeControlController controller = Get.find<FreeControlController>();
  late final ScrollController _scrollController;
  final ValueNotifier<double> _scrollOffset = ValueNotifier<double>(0.0);

  // 顶栏高度与返回按钮尺寸常量
  static const double _toolbarHeight = 56.0;
  static const double _backButtonSize = 36.0;

  // 顶栏高斯模糊与背景遮罩调节参数（直接在此处调节效果）
  /// 完全折叠时的最大高斯模糊强度（sigma，推荐 15.0 ~ 35.0）
  static const double maxBlurSigma = 24.0;

  /// 完全折叠时背景遮罩的最大不透明度（推荐 0.15 ~ 0.30 保持通透毛玻璃质感，数值过高会导致背景黢黑掩盖模糊）
  static const double maxBackgroundAlpha = 0.20;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    _scrollOffset.value = offset;
  }

  @override
  Widget build(BuildContext context) {
    // 自由控制页面不预留全局浮窗边距（通过 AppRoutes 配置为 hidden）
    final bottomInset = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: false,
      reserveFloatingControl: false,
    );
    final topPadding = MediaQuery.paddingOf(context).top;

    // 展开与折叠的关键高度计算
    final minHeaderHeight = topPadding + _toolbarHeight;
    final backButtonTop = topPadding + (_toolbarHeight - _backButtonSize) / 2;
    final expandedTitleTop = backButtonTop + _backButtonSize + 14.0;
    final expandedSubtitleTop = expandedTitleTop + 32.0 + 4.0;
    final maxHeaderHeight = expandedSubtitleTop + 16.0 + 16.0;
    final collapseRange = maxHeaderHeight - minHeaderHeight;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Stack(
        children: [
          // 背景
          const AppLottieBackground(),

          // 主滚动内容列表（穿过悬浮 Header 底部）
          ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              maxHeaderHeight + 8,
              16,
              bottomInset,
            ),
            children: [
              // 核心：完全通过后端下发的布局数据 (modules: row, col, variant) 动态排列组件
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                }

                final currentLayout = controller.layout.value;
                if (currentLayout == null || currentLayout.components.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Text(
                        'No layout components configured',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  );
                }

                return FreeControlLayoutBuilder(layout: currentLayout);
              }),
            ],
          ),

          // 悬浮 Header（类似 CoordinatorLayout 折叠与高斯模糊）
          ValueListenableBuilder<double>(
            valueListenable: _scrollOffset,
            builder: (context, offset, _) {
              final t = (offset / collapseRange).clamp(0.0, 1.0);
              return _buildFloatingHeader(
                context: context,
                progress: t,
                topPadding: topPadding,
                minHeight: minHeaderHeight,
                maxHeight: maxHeaderHeight,
                expandedTitleTop: expandedTitleTop,
                expandedSubtitleTop: expandedSubtitleTop,
                backButtonTop: backButtonTop,
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建类似 CoordinatorLayout 的可折叠悬浮头部
  Widget _buildFloatingHeader({
    required BuildContext context,
    required double progress,
    required double topPadding,
    required double minHeight,
    required double maxHeight,
    required double expandedTitleTop,
    required double expandedSubtitleTop,
    required double backButtonTop,
  }) {
    final currentHeaderHeight = lerpDouble(maxHeight, minHeight, progress)!;
    final collapsedTitleTop = topPadding + (_toolbarHeight - 24.0) / 2;
    final currentTitleTop = lerpDouble(
      expandedTitleTop,
      collapsedTitleTop,
      progress,
    )!;

    // 大标题横向对齐：展开时靠左 (-1.0)，折叠时在顶栏水平居中 (0.0)
    final titleAlignmentX = lerpDouble(-1.0, 0.0, progress)!;
    final titleHorizontalPadding = lerpDouble(16.0, 56.0, progress)!;
    final titleFontSize = lerpDouble(26.0, 18.0, progress)!;
    final titleLetterSpacing = lerpDouble(-0.5, -0.2, progress)!;

    // 副标题渐隐：滑动至约 45% 时完全淡出
    final subtitleOpacity = (1.0 - progress * 2.2).clamp(0.0, 1.0);
    final subtitleTop = expandedSubtitleTop - 8.0 * progress;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: currentHeaderHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // 1. 高斯模糊磨砂背景层（随滑动进度逐渐显现，手势穿透）
          if (progress > 0.0)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: AppBlur.backgroundFilter(progress * maxBlurSigma),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(
                          alpha: maxBackgroundAlpha * progress,
                        ),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(
                              alpha: 0.08 * progress,
                            ),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),

          // 2. 副标题（随着滑动向上淡出渐隐，手势穿透）
          if (subtitleOpacity > 0.0)
            Positioned(
              top: subtitleTop,
              left: 16.0,
              right: 16.0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: subtitleOpacity,
                  child: Obx(() {
                    return Text(
                      '${controller.deviceName} · ${controller.connectionStatusText}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppTypography.size12,
                        color: AppColors.textHint,
                      ),
                    );
                  }),
                ),
              ),
            ),

          // 3. 大标题（随滑动逐渐横向居中收缩至顶栏，手势穿透）
          Positioned(
            top: currentTitleTop,
            left: 0,
            right: 0,
            height: 32.0,
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: titleHorizontalPadding,
                ),
                child: Align(
                  alignment: Alignment(titleAlignmentX, 0.0),
                  child: FreeControlTitle(
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: AppFontWeights.demibold,
                      color: Colors.white,
                      letterSpacing: titleLetterSpacing,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 4. 返回按钮（固定在左上角安全区，始终响应用户点击）
          Positioned(
            top: backButtonTop,
            left: 16.0,
            width: _backButtonSize,
            height: _backButtonSize,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Get.back<void>(),
              child: Container(
                width: _backButtonSize,
                height: _backButtonSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
