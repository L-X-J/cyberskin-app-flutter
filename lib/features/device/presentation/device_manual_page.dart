// 设备说明书统一页面的滚动 UI。
import 'package:cyberskin_app/core/extensions/ui_ext.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../../core/widgets/app_lottie_background.dart';
import 'device_manual/device_manual_advertisement.dart';
import 'device_manual/device_manual_header.dart';
import 'device_manual/device_manual_product_hero.dart';
import 'device_manual/device_manual_product_picker.dart';
import 'device_manual/device_manual_sections.dart';
import 'device_manual/device_manual_status_overlay.dart';
import 'device_manual_controller.dart';
import 'device_manual_route_arguments.dart';

/// 设备说明书页面。
final class DeviceManualPage extends GetView<DeviceManualController> {
  /// 创建设备说明书页面。
  const DeviceManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments;
    final routeArgs = arguments is DeviceManualRouteArguments
        ? arguments
        : null;
    return AppScaffold(
      currentTab: AppTab.home,
      showBottomNavigation: false,
      appBar: const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      ),
      body: _DetailContent(
        controller: controller,
        routeArgs: routeArgs,
        onBack: () => Get.back<void>(),
      ),
    );
  }
}

final class _DetailContent extends StatefulWidget {
  const _DetailContent({
    required this.controller,
    required this.routeArgs,
    required this.onBack,
  });

  final DeviceManualController controller;
  final DeviceManualRouteArguments? routeArgs;
  final VoidCallback onBack;

  @override
  State<_DetailContent> createState() => _DetailContentState();
}

final class _DetailContentState extends State<_DetailContent> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: false,
      reserveFloatingControl: false,
    );
    // AppScaffold 内部的 Scaffold 即使 appBar 高度为零，也会把 body 的
    // MediaQuery.padding.top 清零，导致 SliverAppBar(primary: true) 读到 0
    // 而不加任何偏移。改用 viewPaddingOf，它不受 Scaffold 修改。
    final topPad = 0.statusBarHeight;
    return Stack(
      children: [
        const AppLottieBackground(playbackSpeed: 1.5),
        CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              // primary: false — status bar 偏移由我们手动注入，避免 Scaffold
              // 已经清零 padding.top 后再读到 0 无法正确偏移的问题。
              primary: false,
              automaticallyImplyLeading: false,
              expandedHeight: 174 + topPad,
              toolbarHeight: 64 + topPad,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              leadingWidth: 64,
              // 保留 leading 的 64px 占位，实际按钮由顶层 toolbar overlay
              // 绘制到磨玻璃背景之上，避免被 BackdropFilter 模糊。
              leading: const SizedBox.shrink(),
              clipBehavior: Clip.hardEdge,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                collapseMode: CollapseMode.pin,
                background: DeviceManualExpandedHeader(
                  controller: widget.controller,
                ),
                titlePadding: const EdgeInsetsDirectional.only(
                  start: 12,
                  end: 24,
                  bottom: 16,
                ),
                // 折叠标题和磨玻璃背景由外层 overlay 绘制，保证标题始终在
                // BackdropFilter 之上且不会被 FlexibleSpaceBar 的 clip 截断。
              ),
            ),
            SliverToBoxAdapter(
              child: DeviceManualReactiveProductHero(
                controller: widget.controller,
                routeArgs: widget.routeArgs,
              ),
            ),
            SliverToBoxAdapter(
              child: DeviceManualReactiveProductPicker(
                controller: widget.controller,
              ),
            ),
            SliverToBoxAdapter(
              child: DeviceManualReactiveSections(
                controller: widget.controller,
              ),
            ),
            SliverToBoxAdapter(
              child: DeviceManualReactiveAdvertisement(
                controller: widget.controller,
                bottomPadding: bottom,
              ),
            ),
          ],
        ),
        DeviceManualCollapsedAppBar(
          controller: widget.controller,
          onBack: widget.onBack,
          scrollController: _scrollController,
          toolbarHeight: 64 + topPad,
          topPadding: topPad,
          collapseRange: 220,
        ),
        DeviceManualStatusOverlay(controller: widget.controller),
      ],
    );
  }
}
