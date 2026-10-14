// 主页页面：按设备连接状态渲染可复用的设备、内容和广告卡片。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../device/domain/device.dart';
import '../../device/presentation/device_home_controller.dart';
import '../../video/domain/repositories/video_repository.dart';
import '../../video/presentation/video_controller.dart';
import '../../video/presentation/video_page.dart';
import 'home_connected/home_connected_view.dart';
import 'home_controller.dart';
import 'home_disconnected/home_disconnected_view.dart';
import 'widgets/home_shared_widgets.dart';

/// 匿名可浏览的应用主页。
final class HomePage extends StatefulWidget {
  /// 创建主页。
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

final class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final HomeController _controller = Get.find<HomeController>();
  final GlobalKey _headerKey = GlobalKey();

  // 共享 HomeHeader 覆层测量出的高度；首帧为 0，布局完成后回填真实值。
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _measureHeader() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final height = box.size.height;
    if (height > 0 && height != _headerHeight) {
      setState(() => _headerHeight = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoController = _videoController();
    return Obx(() {
      final status = _controller.deviceStatus.value;
      final connected =
          status == DeviceConnectionStatus.connected ||
          status == DeviceConnectionStatus.lowBattery;
      final selectedTab = _controller.selectedTab.value;
      final pendingDiscovery = _controller.pendingDiscovery?.value;
      final isScanning = _controller.isScanning?.value ?? false;
      final bleCardState = _controller.bleCardState.value;
      // Header 仅在 Device 标签（含已连接与未连接）显示，切到 Video 时折叠隐藏。
      final showHeader = selectedTab != AppTab.video;
      final topInset = MediaQuery.viewPaddingOf(context).top;
      final animDuration = MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 760);

      final headerTitle = connected ? 'My device' : 'Add Device';
      final headerSubtitle = connected
          ? 'Good evening, stay relaxed'
          : _resolveHeaderSubtitle(
              isAuthenticated: _controller.isAuthenticated,
              bleCardState: bleCardState,
            );
      final onHeaderProfile = _controller.isAuthenticated
          ? _controller.openProfile
          : _controller.openLogin;

      return AppScaffold(
        currentTab: selectedTab,
        showBottomNavigation: connected,
        onTabSelected: _controller.selectTab,
        appBar: const PreferredSize(
          preferredSize: Size.zero,
          child: SizedBox.shrink(),
        ),
        body: Stack(
          children: [
            // 全高内容体：已连接/未连接状态用 AnimatedSwitcher 过渡。
            AnimatedSwitcher(
              duration: animDuration,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: connected
                  ? _ConnectedBody(
                      key: const ValueKey('home-connected'),
                      selectedTab: selectedTab,
                      videoController: videoController,
                      topInset: topInset,
                      headerHeight: _headerHeight,
                    )
                  : HomeDisconnectedView(
                      key: const ValueKey('home-disconnected'),
                      dashboard: _controller.dashboard.value,
                      isLoading: _controller.isLoading.value,
                      failureMessage: _controller.failure.value?.message,
                      bindFailureMessage: _controller.bindFailureMessage.value,
                      isAuthenticated: _controller.isAuthenticated,
                      bleCardState: bleCardState,
                      onPrimaryAction: () =>
                          unawaited(_controller.handleBlePrimaryAction()),
                      onStopDiscovery: () =>
                          unawaited(_controller.stopDiscovery()),
                      pendingDiscovery: pendingDiscovery,
                      onConfirmDiscovery: () =>
                          unawaited(_controller.confirmDiscovery()),
                      onDismissDiscovery: () =>
                          unawaited(_controller.dismissDiscovery()),
                      isScanning: isScanning,
                      onDeviceModelDetails: (model) => _controller
                          .openDeviceManual(model.id, summary: model),
                      onDeviceManual: () => _controller.openDeviceManual(
                        _controller.dashboard.value.boundDevice?.deviceModelId,
                      ),
                      onLogin: _controller.openLogin,
                      onProfile: _controller.openProfile,
                      onReload: _controller.reload,
                      topHeaderPadding: _headerHeight,
                    ),
            ),
            // 共享顶部 Header：切换到 Video 时从顶部折叠上滑隐藏，回到 Device 时展开下滑显示。
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ClipRect(
                child: AnimatedAlign(
                  heightFactor: showHeader ? 1.0 : 0.0,
                  alignment: Alignment.topCenter,
                  duration: animDuration,
                  curve: showHeader ? Curves.easeOutCubic : Curves.easeInCubic,
                  child: Padding(
                    key: _headerKey,
                    padding: EdgeInsets.fromLTRB(24, topInset + 28, 24, 20),
                    child: HomeHeader(
                      title: headerTitle,
                      subtitle: headerSubtitle,
                      onProfile: onHeaderProfile,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// 主页测试可只注册 HomeController；此时以无远端 Repository 的视频壳层补齐展示依赖。
  VideoController _videoController() {
    if (Get.isRegistered<VideoController>()) {
      return Get.find<VideoController>();
    }
    final repository = Get.isRegistered<VideoRepository>()
        ? Get.find<VideoRepository>()
        : null;
    return Get.put<VideoController>(VideoController(repository));
  }
}

/// 根据 BLE 阶段与认证状态解析共享 HomeHeader 的副标题文案；保持单行精简。
String _resolveHeaderSubtitle({
  required bool isAuthenticated,
  required HomeBleCardState bleCardState,
}) {
  if (!isAuthenticated) return 'Log in to pair devices';
  return switch (bleCardState.phase) {
    HomeBleCardPhase.bluetoothOff => 'Turn on Bluetooth',
    HomeBleCardPhase.permissionRequired => 'Bluetooth permission required',
    HomeBleCardPhase.unavailable => 'Bluetooth unavailable',
    HomeBleCardPhase.loginRequired => 'Log in to connect',
    HomeBleCardPhase.ready => 'Keep device nearby to scan',
    HomeBleCardPhase.scanning => 'Searching for devices...',
    HomeBleCardPhase.deviceFound => 'Device found nearby',
    HomeBleCardPhase.noDevice => 'No device found',
    HomeBleCardPhase.connecting => 'Connecting...',
    HomeBleCardPhase.connectionFailed => 'Connection failed',
    HomeBleCardPhase.checking => 'Checking Bluetooth...',
    HomeBleCardPhase.bindFailed => 'Device link failed',
  };
}

/// 已连接状态下的双标签体；IndexedStack 保持两个子树常驻，避免切换时重建。
final class _ConnectedBody extends StatelessWidget {
  const _ConnectedBody({
    super.key,
    required this.selectedTab,
    required this.videoController,
    required this.topInset,
    required this.headerHeight,
  });

  final AppTab selectedTab;
  final VideoController videoController;
  final double topInset;

  // 首页共享 HomeHeader 覆层测量高度；首帧为 0，内容会暂时上移再回填。
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    final bottomInset = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: true,
    );
    return IndexedStack(
      index: selectedTab == AppTab.video ? 1 : 0,
      children: [
        // 首页已通过覆层渲染共享 HomeHeader，内容体只需在覆层下方留出对应空间。
        DeviceBodyContent(
          controller: Get.find<DeviceHomeController>(),
          topInset: topInset,
          bottomInset: bottomInset,
          topPaddingOverride: headerHeight,
        ),
        VideoTabContent(controller: videoController),
      ],
    );
  }
}
