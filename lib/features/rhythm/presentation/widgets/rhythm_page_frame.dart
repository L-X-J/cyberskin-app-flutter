// 节奏页面公共背景、安全区、受控内容宽度和底部操作区。
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/floating_control_controller.dart';
import '../../../../core/theme/app_rhythm_style.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';
import '../../../../core/widgets/app_lottie_background.dart';

/// 统一节奏背景、顶栏、安全区和最大操作列宽。
final class RhythmPageFrame extends StatefulWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmPageFrame({
    super.key,
    required this.body,
    required this.onBack,
    this.trailing,
    this.footer,
    this.showToolbar = true,
    this.topOverlay,
  });

  /// 页面可滚动主体，不包含固定底栏。
  final Widget body;

  /// 返回行为由页面处理草稿或运行生命周期。
  final VoidCallback onBack;

  /// 顶栏附加操作与底部固定操作区。
  final Widget? trailing, footer;

  /// 列表使用滚动容器内的折叠顶栏，其余页面保持固定顶栏。
  final bool showToolbar;

  /// 全视口顶层，由调用方分别裁切背景并约束交互内容，不重复消费安全区。
  final Widget? topOverlay;
  @override
  State<RhythmPageFrame> createState() => _RhythmPageFrameState();
}

final class _RhythmPageFrameState extends State<RhythmPageFrame> {
  final _boundsKey = GlobalKey();
  Route<dynamic>? _route;

  void _reportBounds() {
    if (!mounted || !Get.isRegistered<FloatingControlController>()) return;
    final route = ModalRoute.of(context);
    final box = _boundsKey.currentContext?.findRenderObject();
    if (route == null || box is! RenderBox || !box.hasSize) return;
    _route = route;
    Get.find<FloatingControlController>().reportPageBounds(
      route,
      box.localToGlobal(Offset.zero) & box.size,
    );
  }

  @override
  void dispose() {
    if (_route != null && Get.isRegistered<FloatingControlController>()) {
      Get.find<FloatingControlController>().forgetPage(_route!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportBounds());
    return Scaffold(
      backgroundColor: AppRhythmStyle.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const AppLottieBackground(),
          // const Positioned.fill(
          //   child: IgnorePointer(
          //     child: CustomPaint(painter: RhythmBackgroundPainter()),
          //   ),
          // ),
          SafeArea(
            child: Center(
              key: _boundsKey,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppRhythmStyle.maxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                  child: Column(
                    children: [
                      if (widget.showToolbar) ...[
                        Row(
                          children: [
                            AppLiquidGlassButton(
                              label: 'Back',
                              icon: Icons.chevron_left,
                              width: 44,
                              height: 44,
                              iconSize: 30,
                              contentPadding: EdgeInsets.zero,
                              variant: AppLiquidGlassButtonVariant.translucent,
                              onPressed: widget.onBack,
                            ),
                            const Spacer(),
                            ?widget.trailing,
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      Expanded(child: widget.body),
                      if (widget.footer != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: widget.footer,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.topOverlay != null)
            Positioned.fill(child: widget.topOverlay!),
        ],
      ),
    );
  }
}

/// 装饰层使用画板比例裁切；交互和文字布局保持真实逻辑像素。
final class RhythmBackgroundPainter extends CustomPainter {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmBackgroundPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 402, size.height / 874);
    void glow(Rect rect, Color color, double sigma) {
      canvas.drawOval(
        rect,
        Paint()
          ..color = color
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, sigma),
      );
    }

    glow(const Rect.fromLTWH(-165, 175, 485, 525), AppRhythmStyle.blue, 70);
    glow(const Rect.fromLTWH(182, 418, 360, 383), AppRhythmStyle.purple, 80);
    glow(const Rect.fromLTWH(215, 95, 293, 291), AppRhythmStyle.haze, 58.35);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RhythmBackgroundPainter oldDelegate) => false;
}
