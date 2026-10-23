// 主页页面：按设备连接状态渲染可复用的设备、内容和广告卡片。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../device/domain/device.dart';
import '../../device/presentation/device_home_controller.dart';
import '../../video/domain/repositories/local_video_repository.dart';
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

final class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final HomeController _controller = Get.find<HomeController>();
  final GlobalKey _headerKey = GlobalKey();

  // 共享 HomeHeader 覆层测量出的高度；首帧为 0，布局完成后回填真实值。
  double _headerHeight = 0;

  // 列表滚动驱动的 Header 高斯模糊进度（0.0 ~ 1.0）。
  double _headerScrollProgress = 0.0;

  // 已连接与未连接视图各自专用的 ScrollController，互不干扰。
  late final ScrollController _connectedScrollController;
  late final ScrollController _disconnectedScrollController;

  // 顶部栏先退出，再横移内容；同一时间轴支持快速反向点击，无需排队等待。
  late final AnimationController _tabTransition = AnimationController(
    vsync: this,
    value: _controller.selectedTab.value == AppTab.video ? 1 : 0,
    duration: const Duration(milliseconds: 440),
  );
  late final Animation<double> _headerExit = _tabTransition.drive(
    CurveTween(curve: const Interval(0, 0.25, curve: Curves.easeInOutCubic)),
  );
  late final Animation<double> _bodyTransition = _tabTransition.drive(
    CurveTween(curve: const Interval(0.25, 1, curve: Curves.easeInOutCubic)),
  );

  // 连接成功时驱动 HomeDisconnectedView 退场的控制器（扫描卡淡出、型号卡飞出）。
  late final AnimationController _disconnectedExit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );

  // 监听连接状态与标签页变化的 GetX Worker，dispose 时必须取消。
  Worker? _statusWorker;
  Worker? _tabWorker;

  @override
  void initState() {
    super.initState();
    _connectedScrollController = ScrollController()..addListener(_onScroll);
    _disconnectedScrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
    WidgetsBinding.instance.addObserver(this);
    // 监听连接状态：连接成功时前进，断开时复位，使退场动画可重复播放；同时同步 Header 模糊进度。
    _statusWorker = ever(_controller.deviceStatus, (status) {
      final isConnected =
          status == DeviceConnectionStatus.connected ||
          status == DeviceConnectionStatus.lowBattery;
      if (isConnected) {
        _disconnectedExit.forward();
      } else {
        _disconnectedExit.reset();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncScrollProgress();
      });
    });
    _tabWorker = ever(_controller.selectedTab, (tab) {
      final target = tab == AppTab.video ? 1.0 : 0.0;
      if (MediaQuery.disableAnimationsOf(context)) {
        _tabTransition.value = target;
      } else {
        unawaited(_tabTransition.animateTo(target));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncScrollProgress();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _tabTransition.value = _controller.selectedTab.value == AppTab.video
          ? 1
          : 0;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  void dispose() {
    _statusWorker?.dispose();
    _tabWorker?.dispose();
    _tabTransition.dispose();
    _disconnectedExit.dispose();
    _connectedScrollController.removeListener(_onScroll);
    _connectedScrollController.dispose();
    _disconnectedScrollController.removeListener(_onScroll);
    _disconnectedScrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onScroll() {
    _syncScrollProgress();
  }

  void _syncScrollProgress() {
    final status = _controller.deviceStatus.value;
    final connected =
        status == DeviceConnectionStatus.connected ||
        status == DeviceConnectionStatus.lowBattery;
    final activeController = connected
        ? _connectedScrollController
        : _disconnectedScrollController;
    if (!activeController.hasClients) {
      if (_headerScrollProgress != 0.0) {
        setState(() => _headerScrollProgress = 0.0);
      }
      return;
    }
    final offset = activeController.offset;
    final progress = (offset / 36.0).clamp(0.0, 1.0);
    if ((progress - _headerScrollProgress).abs() > 0.01 ||
        (progress == 0.0 && _headerScrollProgress != 0.0) ||
        (progress == 1.0 && _headerScrollProgress != 1.0)) {
      setState(() => _headerScrollProgress = progress);
    }
  }

  void _measureHeader() {
    final box = _headerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final height = box.size.height;
    if (height > 0 && height != _headerHeight) {
      setState(() => _headerHeight = height + 10);
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
      // Header 仅在 Device 标签（含已连接与未连接）显示。
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
        showBottomNavigation: connected && !videoController.isFullscreen.value,
        onTabSelected: _controller.selectTab,
        appBar: const PreferredSize(
          preferredSize: Size.zero,
          child: SizedBox.shrink(),
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (_controller.selectedTab.value == AppTab.video) {
              return false;
            }
            if (notification.metrics.axis == Axis.vertical) {
              final offset = notification.metrics.pixels;
              final progress = (offset / 36.0).clamp(0.0, 1.0);
              if ((progress - _headerScrollProgress).abs() > 0.01 ||
                  (progress == 0.0 && _headerScrollProgress != 0.0) ||
                  (progress == 1.0 && _headerScrollProgress != 1.0)) {
                setState(() => _headerScrollProgress = progress);
              }
            }
            return false;
          },
          child: Stack(
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
                        homeController: _controller,
                        videoController: videoController,
                        transition: _bodyTransition,
                        headerHeight: _headerHeight,
                        scrollController: _connectedScrollController,
                      )
                    : HomeDisconnectedView(
                        key: const ValueKey('home-disconnected'),
                        dashboard: _controller.dashboard.value,
                        isLoading: _controller.isLoading.value,
                        failureMessage: _controller.failure.value?.message,
                        bindFailureMessage:
                            _controller.bindFailureMessage.value,
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
                          _controller
                              .dashboard
                              .value
                              .boundDevice
                              ?.deviceModelId,
                        ),
                        onLogin: _controller.openLogin,
                        onProfile: _controller.openProfile,
                        onReload: _controller.reload,
                        topHeaderPadding: _headerHeight,
                        exitAnimation: _disconnectedExit,
                        scrollController: _disconnectedScrollController,
                        onAdvertisement: (ad) =>
                            unawaited(_controller.openAdvertisement(ad)),
                        contentActive: selectedTab != AppTab.video,
                      ),
              ),
              // Header 保持完整高度，从顶部整体飞出/飞入，不参与内容区尺寸变化。
              // 滚动时带有平滑高斯模糊与暗色遮罩背景，避免滑动内容与文字发生重叠。
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: ClipRect(
                  child: IgnorePointer(
                    ignoring: !showHeader,
                    child: ExcludeFocus(
                      excluding: !showHeader,
                      child: ExcludeSemantics(
                        excluding: !showHeader,
                        child: AnimatedBuilder(
                          animation: _headerExit,
                          builder: (context, child) => FractionalTranslation(
                            translation: Offset(0, -_headerExit.value),
                            child: child,
                          ),
                          child: HomeHeader(
                            key: _headerKey,
                            title: headerTitle,
                            subtitle: headerSubtitle,
                            onProfile: onHeaderProfile,
                            topInset: topInset,
                            scrollProgress: _headerScrollProgress,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    return Get.put<VideoController>(
      VideoController(
        repository,
        localRepository: Get.isRegistered<LocalVideoRepository>()
            ? Get.find<LocalVideoRepository>()
            : null,
      ),
    );
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

/// 已连接状态下的双标签体；两个子树保持常驻，仅平移可见内容。
final class _ConnectedBody extends StatelessWidget {
  const _ConnectedBody({
    super.key,
    required this.selectedTab,
    required this.homeController,
    required this.videoController,
    required this.transition,
    required this.headerHeight,
    this.scrollController,
  });

  final AppTab selectedTab;
  final VideoController videoController;
  final HomeController homeController;
  final Animation<double> transition;

  // 首页共享 HomeHeader 覆层测量高度；首帧为 0，内容会暂时上移再回填。
  final double headerHeight;

  /// 外部传入的滚动控制器，用于联动主页 Header 高斯模糊等动态效果。
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final bottomInset = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: true,
    );
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 首页已通过覆层渲染共享 HomeHeader，内容体只需在覆层下方留出对应空间。
          _slidingTab(
            tab: AppTab.home,
            child: DeviceBodyContent(
              controller: Get.isRegistered<DeviceHomeController>()
                  ? Get.find<DeviceHomeController>()
                  : null,
              bottomInset: bottomInset,
              homeController: homeController,
              contentActive: selectedTab != AppTab.video,
              topPadding: headerHeight,
              scrollController: scrollController,
              onPowerOff: () =>
                  unawaited(homeController.confirmPowerOffAndUnbind()),
            ),
          ),
          _slidingTab(
            tab: AppTab.video,
            child: VideoTabContent(
              controller: videoController,
              active: selectedTab == AppTab.video,
            ),
          ),
        ],
      ),
    );
  }

  /// 隐藏页保留滚动与播放实例，退出后停止 ticker，并移除焦点和点击入口。
  Widget _slidingTab({required AppTab tab, required Widget child}) {
    final selected = selectedTab == tab;
    return AnimatedBuilder(
      animation: transition,
      builder: (context, child) {
        final progress = transition.value;
        final offstage = tab == AppTab.home ? progress == 1 : progress == 0;
        return Offstage(
          offstage: offstage,
          child: TickerMode(
            enabled: !offstage,
            child: FractionalTranslation(
              translation: Offset(
                tab == AppTab.home ? -progress : 1 - progress,
                0,
              ),
              child: child,
            ),
          ),
        );
      },
      child: IgnorePointer(
        ignoring: !selected,
        child: ExcludeFocus(
          excluding: !selected,
          child: ExcludeSemantics(excluding: !selected, child: child),
        ),
      ),
    );
  }
}
