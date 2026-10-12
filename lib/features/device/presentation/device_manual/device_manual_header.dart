import 'package:cyberskin_app/core/extensions/ui_ext.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_blur.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';
import '../device_manual_controller.dart';

/// 展开态 AppBar 背景层；承载大标题，接近折叠时淡出。
final class DeviceManualExpandedHeader extends StatelessWidget {
  /// 创建 [DeviceManualExpandedHeader]。
  const DeviceManualExpandedHeader({required this.controller, super.key});

  /// 说明书页面控制器。
  final DeviceManualController controller;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // 折叠后的实际高度是 64 + status bar，展开高度比它多 110px，
      // 所以折叠区间始终是 110，progress = 0 对应完全折叠。
      final topPad = 0.statusBarHeight;
      final collapsedHeight = 64.0 + topPad;
      final progress = ((constraints.maxHeight - collapsedHeight) / 110).clamp(
        0.0,
        1.0,
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: Opacity(
              opacity: progress,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 24,
                    left: 24,
                    right: 24,
                  ),
                  child: DeviceManualHeaderTitle(
                    controller: controller,
                    style: AppTypography.productName,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

/// 响应式标题文字；在展开态和折叠态 AppBar 中复用。
final class DeviceManualHeaderTitle extends StatelessWidget {
  /// 创建 [DeviceManualHeaderTitle]。
  const DeviceManualHeaderTitle({
    required this.controller,
    required this.style,
    super.key,
  });

  /// 说明书页面控制器。
  final DeviceManualController controller;

  /// 标题文字样式。
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Obx(() {
    final model = controller.selectedModel.value ?? controller.summary;
    return Text(
      model?.name ?? 'Cyberskin device',
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style,
    );
  });
}

/// SliverAppBar 折叠后工具栏区域的磨玻璃背景层和标题。
///
/// 该层必须位于滚动内容之上，才能在标题完全置顶后模糊其后的页面内容。
/// 标题由同一层绘制，避免标题自身被 [BackdropFilter] 模糊。
final class DeviceManualCollapsedAppBar extends StatefulWidget {
  /// 创建 [DeviceManualCollapsedAppBar]。
  const DeviceManualCollapsedAppBar({
    required this.controller,
    required this.onBack,
    required this.scrollController,
    required this.toolbarHeight,
    required this.topPadding,
    required this.collapseRange,
    super.key,
  });

  /// 说明书页面控制器。
  final DeviceManualController controller;

  /// 返回按钮回调。
  final VoidCallback onBack;

  /// 页面主滚动控制器，用于计算折叠进度。
  final ScrollController scrollController;

  /// 折叠后的工具栏高度（含 status bar）。
  final double toolbarHeight;

  /// Status bar 高度偏移。
  final double topPadding;

  /// 完全折叠所需的滚动距离。
  final double collapseRange;

  @override
  State<DeviceManualCollapsedAppBar> createState() =>
      _DeviceManualCollapsedAppBarState();
}

final class _DeviceManualCollapsedAppBarState
    extends State<DeviceManualCollapsedAppBar> {
  double _collapseT = 0;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final offset = widget.scrollController.hasClients
        ? widget.scrollController.offset + 10
        : 0.0;
    final t = (offset / widget.collapseRange).clamp(0.0, 1.0);
    if ((t - _collapseT).abs() > 0.005 && mounted) {
      setState(() => _collapseT = t);
    }
  }

  @override
  Widget build(BuildContext context) => Positioned(
    left: 0,
    right: 0,
    height: widget.toolbarHeight,
    child: Stack(
      children: [
        if (_collapseT > 0.465)
          IgnorePointer(
            child: ClipRect(
              child: BackdropFilter(
                filter: AppBlur.backgroundFilter(AppBlur.glassStrong),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.14 * _collapseT),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 10,
                        end: 24,
                        bottom: 24,
                      ),
                      child: Opacity(
                        opacity: _collapseT,
                        child: DeviceManualHeaderTitle(
                          controller: widget.controller,
                          style: AppTypography.subtitle.copyWith(fontSize: 24),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        PositionedDirectional(
          start: 0,
          top: 0,
          width: 64,
          height: widget.toolbarHeight,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: 24,
              top: widget.topPadding,
            ),
            child: UnconstrainedBox(
              alignment: AlignmentDirectional.topStart,
              child: AppLiquidGlassButton(
                label: 'Back',
                icon: Icons.arrow_back_ios_new,
                onPressed: widget.onBack,
                variant: AppLiquidGlassButtonVariant.translucent,
                width: 40,
                height: 40,
                borderRadius: 20,
                iconSize: 17,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
