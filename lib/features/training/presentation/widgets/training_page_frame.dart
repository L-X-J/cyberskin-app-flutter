// 训练页面背景、安全区、最大内容宽度及固定操作区域。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/floating_control_controller.dart';
import '../../../../core/theme/app_rhythm_style.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';
import '../../../../core/widgets/app_lottie_background.dart';

/// 训练页面的背景、返回按钮和安全区容器。
final class TrainingPageFrame extends StatefulWidget {
  /// 创建训练页面的背景、返回按钮和安全区容器。
  const TrainingPageFrame({super.key, required this.body, this.footer});

  /// 正常滚动的页面主体。
  final Widget body;

  /// 固定于安全区内的操作区域。
  final Widget? footer;
  @override
  State<TrainingPageFrame> createState() => _TrainingPageFrameState();
}

final class _TrainingPageFrameState extends State<TrainingPageFrame> {
  final _bounds = GlobalKey();
  Route<dynamic>? _route;
  void _report() {
    if (!mounted || !Get.isRegistered<FloatingControlController>()) return;
    final route = ModalRoute.of(context);
    final box = _bounds.currentContext?.findRenderObject();
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _report());
    return Scaffold(
      backgroundColor: AppRhythmStyle.background,
      body: Stack(
        children: [
          const AppLottieBackground(),
          SafeArea(
            child: Center(
              key: _bounds,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppRhythmStyle.maxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: AppLiquidGlassButton(
                          label: 'Back',
                          icon: Icons.chevron_left,
                          width: 44,
                          height: 44,
                          contentPadding: EdgeInsets.zero,
                          variant: AppLiquidGlassButtonVariant.translucent,
                          onPressed: () => Get.back<void>(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(child: widget.body),
                      if (widget.footer != null)
                        Padding(
                          padding: EdgeInsets.only(
                            top: 12,
                            bottom: MediaQuery.sizeOf(context).height >= 800
                                ? 60
                                : 0,
                          ),
                          child: widget.footer,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
