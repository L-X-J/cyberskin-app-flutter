// 主页已连接状态展示组件；组装已连接设备主卡、功能网格、训练卡与广告卡。
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/widgets/app_glass_surfaces.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../device/domain/connected_device_state.dart';
import '../../../device/domain/device.dart';
import '../../../device/presentation/device_home_controller.dart';
import '../home_controller.dart';
import '../widgets/home_shared_widgets.dart';
import 'connected_device_hero_card.dart';
import 'home_advertisement_card.dart';
import 'home_device_states.dart';
import 'home_feature_cards.dart';
import 'home_training_card.dart';

/// 设备已连接状态页面；集中展示已连接设备卡片、模式入口行、训练与运营位。
final class HomeConnectedView extends StatefulWidget {
  /// 创建已连接状态页面组件。
  const HomeConnectedView({
    super.key,
    required this.device,
    this.connectedState,
    this.isLoading = false,
    this.failureMessage,
    required this.topPadding,
    required this.bottomInset,
    this.onPowerOff,
    this.onReload,
    this.onDeviceManual,
    this.onFreeControl,
    this.onCustomRhythm,
    this.onTrainingMore,
    this.scrollController,
    this.homeController,
    this.contentActive = true,
  });

  /// 外部传入的滚动控制器，用于联动主页 Header 高斯模糊等动态效果。
  final ScrollController? scrollController;

  /// 首页真实内容控制器。
  final HomeController? homeController;

  /// 当前首页标签是否可见，用于轮播生命周期。
  final bool contentActive;

  /// 当前已连接的设备实体模型。
  final Device device;

  /// 连接设备的实时运行时视图；为 null 时优先从运行时协调器中读取。
  final ConnectedDeviceState? connectedState;

  /// 是否正在后台刷新或加载数据。
  final bool isLoading;

  /// 数据加载或刷新异常时的提示文案。
  final String? failureMessage;

  /// 页面顶部内边距；由调用方结合共享 Header 或安全区高度传入。
  final double topPadding;

  /// 页面底部预留高度，确保内容不被底部导航或悬浮条遮挡。
  final double bottomInset;

  /// 请求关闭设备并解除绑定的回调。
  final VoidCallback? onPowerOff;

  /// 失败重试或重新拉取设备状态的回调。
  final VoidCallback? onReload;

  /// 打开设备说明书回调；为空时采用默认路由导航。
  final VoidCallback? onDeviceManual;

  /// 打开自由控制模式回调；为空时采用默认路由导航。
  final VoidCallback? onFreeControl;

  /// 打开自定义节奏模式回调。
  final VoidCallback? onCustomRhythm;

  /// 查看更多训练模式回调。
  final VoidCallback? onTrainingMore;

  @override
  State<HomeConnectedView> createState() => _HomeConnectedViewState();
}

final class _HomeConnectedViewState extends State<HomeConnectedView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  // 顶部设备卡：淡入 + 绕 X 轴翻转落入（模拟 3D 深度感）。
  late final Animation<double> _heroFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
  );

  // 绕 X 轴翻转：从 -0.35π 翻转至 0 度正面。
  late final Animation<double> _heroFlip =
      Tween<double>(begin: -0.35 * math.pi, end: 0.0).animate(
        CurvedAnimation(
          parent: _entrance,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
        ),
      );

  // 功能入口行、训练卡、广告卡依次错帧淡入。
  late final Animation<double> _cardsFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
  );
  late final Animation<double> _trainingFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
  );
  late final Animation<double> _adFade = CurvedAnimation(
    parent: _entrance,
    curve: const Interval(0.45, 0.9, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HomeBackground(
      child: ListView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          24,
          widget.topPadding,
          24,
          widget.bottomInset,
        ),
        children: [
          ConnectedDeviceHeroCard(
            device: widget.device,
            connectedState: widget.connectedState,
            flipAnimation: _heroFlip,
            fadeAnimation: _heroFade,
            onPowerOff: widget.onPowerOff,
            onManual: widget.onDeviceManual,
          ),
          const SizedBox(height: 16),
          HomeFeatureGrid(
            fadeAnimation: _cardsFade,
            onFreeControl: widget.onFreeControl,
            onCustomRhythm: widget.onCustomRhythm,
          ),
          const SizedBox(height: 16),
          if (widget.homeController case final home?)
            Obx(() {
              final courses = home.dashboard.value.trainings;
              return HomeTrainingCard(
                fadeAnimation: _trainingFade,
                training: courses.firstOrNull,
                onMore: home.openTrainingList,
                onTraining: courses.isEmpty
                    ? null
                    : () => home.openTraining(courses.first),
              );
            })
          else
            HomeTrainingCard(
              fadeAnimation: _trainingFade,
              onMore: widget.onTrainingMore,
            ),
          const SizedBox(height: 16),
          if (widget.homeController case final home?)
            Obx(
              () => HomeAdvertisementCard(
                fadeAnimation: _adFade,
                advertisements: home.dashboard.value.advertisements,
                active: widget.contentActive,
                onAdvertisement: (ad) => unawaited(home.openAdvertisement(ad)),
              ),
            ),
          if (widget.homeController case final home?)
            Obx(
              () => Column(
                children: [
                  if (home.contentLoading.value)
                    const LinearProgressIndicator(minHeight: 2),
                  if (home.contentFailure.value case final failure?)
                    AppInlineHint(
                      icon: Icons.sync_problem_outlined,
                      text: failure.message,
                      onTap: () => unawaited(home.refreshContent(force: true)),
                    ),
                ],
              ),
            ),
          if (widget.failureMessage != null) ...[
            const SizedBox(height: 12),
            _buildFailureBanner(),
          ],
          if (widget.isLoading) ...[
            const SizedBox(height: 14),
            _buildLoadingIndicator(),
          ],
        ],
      ),
    );
  }

  /// 构建加载失败提示横幅。
  Widget _buildFailureBanner() {
    return AppInlineHint(
      icon: Icons.sync_problem_outlined,
      text: widget.failureMessage!,
      onTap: widget.onReload,
    );
  }

  /// 构建加载指示器。
  Widget _buildLoadingIndicator() {
    return const LinearProgressIndicator(minHeight: 2);
  }
}

/// 首页设备标签页的内容体。
///
/// 订阅设备控制器状态，在已连接、加载中、异常与空设备状态间分发。
final class DeviceBodyContent extends StatelessWidget {
  /// 创建设备内容体。
  const DeviceBodyContent({
    super.key,
    this.controller,
    required this.topPadding,
    required this.bottomInset,
    this.onPowerOff,
    this.scrollController,
    this.homeController,
    this.contentActive = true,
  });

  /// 设备主页控制器，持有设备列表和 BLE 发现状态；为空时从 Get 容器自动解析。
  final DeviceHomeController? controller;

  /// 首页共享标题区下方的顶部留白。
  final double topPadding;

  /// 页面底部预留高度。
  final double bottomInset;

  /// 请求关闭设备并解除绑定。
  final VoidCallback? onPowerOff;

  /// 外部传入的滚动控制器，用于联动主页 Header 高斯模糊等动态效果。
  final ScrollController? scrollController;

  /// 首页真实内容控制器。
  final HomeController? homeController;

  /// 当前首页标签是否可见，用于轮播生命周期。
  final bool contentActive;

  @override
  Widget build(BuildContext context) {
    final activeController =
        controller ??
        (Get.isRegistered<DeviceHomeController>()
            ? Get.find<DeviceHomeController>()
            : null);
    if (activeController == null) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final devices = activeController.devices.toList(growable: false);
      final failure = activeController.failure.value;
      final isLoading = activeController.isLoading.value;
      final pending = activeController.pendingDiscovery?.value;

      if (isLoading && devices.isEmpty) {
        return const HomeDeviceLoadingState();
      }
      if (failure != null && devices.isEmpty) {
        return HomeDeviceErrorState(
          message: failure.message,
          onRetry: () => unawaited(activeController.reload()),
        );
      }
      if (devices.isEmpty) {
        return HomeEmptyDeviceState(
          pending: pending,
          onConfirm: () => unawaited(activeController.confirmDiscovery()),
          onDismiss: () => unawaited(activeController.dismissDiscovery()),
          onAdd: () => unawaited(activeController.startDiscovery()),
        );
      }

      return RefreshIndicator(
        color: AppColors.secondary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await activeController.reload();
          await homeController?.reload();
        },
        child: HomeConnectedView(
          device: devices.first,
          isLoading: isLoading,
          failureMessage: failure?.message,
          topPadding: topPadding,
          bottomInset: bottomInset,
          onPowerOff: onPowerOff,
          onReload: () => unawaited(activeController.reload()),
          scrollController: scrollController,
          homeController: homeController,
          contentActive: contentActive,
        ),
      );
    });
  }
}
