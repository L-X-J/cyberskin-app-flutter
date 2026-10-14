// 主页未连接状态及扫描、型号入口的展示组件。
import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:get/get.dart';

import '../../../../app/widgets/app_flower_loading_indicator.dart';
import '../../../../app/widgets/app_glass_surfaces.dart';
import '../../../../app/widgets/app_scaffold.dart';
import '../../../../core/theme/app_layered_gradient_style.dart';
import '../../../../core/widgets/app_layered_gradient_card.dart';
import '../../../device/domain/repositories/device_catalog_repository.dart';
import '../../../device/presentation/device_model_card.dart';
import '../home_controller.dart';
import '../home_dashboard.dart';
import '../states/home_ble_card_state.dart';
import '../widgets/home_shared_widgets.dart';

/// 设备未连接状态页面；底部一级导航按产品规则隐藏，集中展现设备搜索、配对与设备型号入口。
final class HomeDisconnectedView extends StatelessWidget {
  /// 创建未连接状态页面组件。
  const HomeDisconnectedView({
    super.key,
    required this.dashboard,
    required this.isLoading,
    this.failureMessage,
    this.bindFailureMessage,
    required this.isAuthenticated,
    required this.bleCardState,
    required this.onPrimaryAction,
    required this.onStopDiscovery,
    required this.pendingDiscovery,
    required this.onConfirmDiscovery,
    required this.onDismissDiscovery,
    required this.isScanning,
    required this.onDeviceModelDetails,
    this.onDeviceManual,
    required this.onLogin,
    required this.onProfile,
    this.onReload,
    this.topHeaderPadding,
  });

  /// 主页冻结可渲染数据（含设备型号列表与推荐内容）。
  final HomeDashboard dashboard;

  /// 是否正在加载或刷新数据。
  final bool isLoading;

  /// 加载数据时的异常提示文案。
  final String? failureMessage;

  /// 用户是否已完成登录认证。
  final bool isAuthenticated;

  /// 扫描卡片展示状态与 phase。
  final HomeBleCardState bleCardState;

  /// 绑定失败时的服务端错误消息；非空时在扫描卡下方展示持久横幅。
  final String? bindFailureMessage;

  /// 点击扫描卡主要动作按钮回调（根据阶段处理蓝牙开/权限/扫描/登录）。
  final VoidCallback onPrimaryAction;

  /// 停止蓝牙扫描回调。
  final VoidCallback onStopDiscovery;

  /// 发现中的待确认设备。
  final BleDiscoveredDevice? pendingDiscovery;

  /// 确认连接发现的设备回调。
  final VoidCallback onConfirmDiscovery;

  /// 忽略/暂不连接发现的设备回调。
  final VoidCallback onDismissDiscovery;

  /// 是否处于蓝牙扫描过程中。
  final bool isScanning;

  /// 点击设备型号卡片回调。
  final ValueChanged<DeviceModelSummary> onDeviceModelDetails;

  /// 打开设备使用说明书回调。
  final VoidCallback? onDeviceManual;

  /// 登录入口回调。
  final VoidCallback onLogin;

  /// 个人中心入口回调。
  final VoidCallback onProfile;

  /// 错误重试或重新加载数据回调。
  final VoidCallback? onReload;

  /// 首页 Shell 共享 HomeHeader 所占高度；传入后 ListView 顶部跳过该区域，
  /// 自身不再渲染 HomeHeader。为 null 时作为独立视图渲染自有标题区。
  final double? topHeaderPadding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: false,
    );
    final topPadding = topHeaderPadding ?? Get.mediaQuery.viewPadding.top + 28;
    return HomeBackground(
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, topPadding, 24, bottomInset),
        children: [
          _ScanCard(
            state: bleCardState,
            pending: pendingDiscovery,
            onPrimaryAction: onPrimaryAction,
            onStop: onStopDiscovery,
            onConfirm: onConfirmDiscovery,
            onDismiss: onDismissDiscovery,
            onLogin: onLogin,
          ),
          if (bindFailureMessage != null) ...[
            const SizedBox(height: 10),
            AppInlineHint(icon: Icons.link_off, text: bindFailureMessage!),
          ],
          const SizedBox(height: 16),
          _DeviceModelGrid(
            models: dashboard.deviceModels,
            onTap: onDeviceModelDetails,
          ),
          if (dashboard.deviceModels.isEmpty) ...[
            const SizedBox(height: 10),
            _buildEmptyModelHint(),
          ],
          if (failureMessage != null) ...[
            const SizedBox(height: 12),
            _buildFailureBanner(),
          ],
          if (isLoading) ...[
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
      text: failureMessage!,
      onTap: onReload,
    );
  }

  /// 构建加载指示器。
  Widget _buildLoadingIndicator() {
    return const LinearProgressIndicator(minHeight: 2);
  }

  /// 构建无型号数据时的空状态提示。
  Widget _buildEmptyModelHint() {
    return AppInlineHint(
      icon: Icons.bluetooth_disabled_outlined,
      text: 'Turn on Bluetooth and keep the device nearby.',
      onTap: onReload,
    );
  }
}

/// 未连接扫描卡；包含状态文案、动画指示、匹配提示及动作按钮。
final class _ScanCard extends StatelessWidget {
  /// 创建蓝牙扫描卡片组件。
  const _ScanCard({
    required this.state,
    required this.pending,
    required this.onPrimaryAction,
    required this.onStop,
    required this.onConfirm,
    required this.onDismiss,
    required this.onLogin,
  });

  /// 卡片当前的文案、图标与可操作状态。
  final HomeBleCardState state;

  /// 扫描到的待确认目标设备。
  final BleDiscoveredDevice? pending;

  /// 点击主要动作按钮回调（根据阶段触发打开蓝牙/请求权限/开始扫描）。
  final VoidCallback onPrimaryAction;

  /// 点击停止扫描按钮回调。
  final VoidCallback onStop;

  /// 点击确认配对设备按钮回调。
  final VoidCallback onConfirm;

  /// 点击忽略/取消设备配对回调。
  final VoidCallback onDismiss;

  /// 未登录状态下点击登录动作回调。
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final showPending = pending != null;
    final hideCompactAction =
        state.phase == HomeBleCardPhase.loginRequired ||
        state.phase == HomeBleCardPhase.unavailable;
    final showLoginOnly = state.phase == HomeBleCardPhase.loginRequired;

    return LiquidGlassLayer(
      useBackdropGroup: true,
      fake: true,
      child: AppLayeredGradientCard.scan(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 22, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(state.title, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 6),
              Text(
                state.description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.2,
                ),
              ),
              if (showPending) ...[
                const SizedBox(height: 10),
                Text(
                  'Found: ${pending!.name.isEmpty ? pending!.remoteId : pending!.name} '
                  '(${pending!.rssi} dBm)',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: AppTextButtonSurface(
                        label: 'Connect',
                        onPressed: onConfirm,
                        height: 36,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppTextButtonSurface(
                        label: 'Dismiss',
                        onPressed: onDismiss,
                        height: 36,
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: state.showSpinner ? 8 : 12),
              Row(
                children: [
                  if (state.showStop)
                    AppTextButtonSurface(
                      label: state.actionLabel,
                      leadingIcon: Icons.stop_circle_outlined,
                      onPressed: onStop,
                      height: 40,
                    )
                  else
                    AppTextButtonSurface(
                      label: state.actionLabel,
                      leadingIcon: hideCompactAction ? null : state.actionIcon,
                      onPressed: state.actionEnabled
                          ? (showLoginOnly ? onLogin : onPrimaryAction)
                          : null,
                      height: 40,
                    ),
                  const Spacer(),
                  if (!showLoginOnly)
                    SizedBox.square(
                      dimension: 64,
                      child: state.showSpinner
                          ? const Center(
                              child: AppFlowerLoadingIndicator(size: 64),
                            )
                          : Icon(
                              _statusIcon(state.phase),
                              color: Colors.white70,
                            ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据 phase 返回右侧状态图标。
  IconData _statusIcon(HomeBleCardPhase phase) => switch (phase) {
    HomeBleCardPhase.bluetoothOff => Icons.bluetooth_disabled,
    HomeBleCardPhase.permissionRequired => Icons.security,
    HomeBleCardPhase.unavailable => Icons.bluetooth_disabled,
    HomeBleCardPhase.loginRequired => Icons.login,
    HomeBleCardPhase.ready => Icons.bluetooth,
    HomeBleCardPhase.scanning => Icons.bluetooth_searching,
    HomeBleCardPhase.deviceFound => Icons.bluetooth_connected,
    HomeBleCardPhase.noDevice => Icons.bluetooth_searching,
    HomeBleCardPhase.connecting => Icons.bluetooth_connected,
    HomeBleCardPhase.connectionFailed => Icons.sync_problem_outlined,
    HomeBleCardPhase.bindFailed => Icons.link_off,
    HomeBleCardPhase.checking => Icons.bluetooth_searching,
  };
}

/// 未连接型号入口网格；平铺展示支持的设备型号入口。
final class _DeviceModelGrid extends StatelessWidget {
  /// 创建设备型号网格组件。
  const _DeviceModelGrid({required this.models, required this.onTap});

  /// 允许展示的设备型号列表。
  final List<DeviceModelSummary> models;

  /// 点击特定型号卡片的回调。
  final ValueChanged<DeviceModelSummary> onTap;

  @override
  Widget build(BuildContext context) {
    final entries = models.isEmpty
        ? const <_ModelPreview>[
            _ModelPreview(
              title: 'Cyberskin Air',
              image: 'assets/images/home/device_air.png',
              surfaceColor: AppLayeredGradientStyle.baseColor,
              model: DeviceModelSummary(name: 'Cyberskin Air'),
            ),
            _ModelPreview(
              title: 'Cyberskin Pro',
              image: 'assets/images/home/device_pro.png',
              surfaceColor: Color(0xFF8AD36B),
              model: DeviceModelSummary(name: 'Cyberskin Pro'),
            ),
          ]
        : models.take(2).map(_ModelPreview.fromModel).toList(growable: false);
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _ModelCard(
              preview: entries[i],
              onTap: () => onTap(entries[i].model),
            ),
          ),
        ],
      ],
    );
  }
}

/// 后台卡片色支持 RGB / ARGB；非法值由展示模型回退到设计默认值。
Color? _hexToColor(String? hex) {
  final clean = hex?.trim().replaceFirst(RegExp(r'^#'), '');
  if (clean == null ||
      !RegExp(r'^(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$').hasMatch(clean)) {
    return null;
  }
  final value = int.tryParse(clean.length == 6 ? 'FF$clean' : clean, radix: 16);
  return value == null ? null : Color(value);
}

/// 型号入口的不可变展示数据；后台字段在此转换为卡片内容。
final class _ModelPreview {
  /// 创建型号卡片预览展示数据。
  const _ModelPreview({
    required this.title,
    required this.image,
    required this.surfaceColor,
    required this.model,
    this.tags = const [],
  });

  /// 从后台 [DeviceModelSummary] 模型构建展示预览数据。
  factory _ModelPreview.fromModel(DeviceModelSummary model) => _ModelPreview(
    title: model.name ?? 'Cyberskin device',
    image: model.iconUrl,
    surfaceColor:
        _hexToColor(model.cardColor) ?? AppLayeredGradientStyle.baseColor,
    model: model,
    tags: List.unmodifiable(
      (model.tags ?? '')
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty),
    ),
  );

  /// 展示标题。
  final String title;

  /// 展示图片 URL 或本地资源路径。
  final String? image;

  /// 基础渐变卡片背景色。
  final Color surfaceColor;

  /// 对应的后端设备型号模型。
  final DeviceModelSummary model;

  /// 特性标签列表。
  final List<String> tags;
}

/// 型号入口展示卡片。
final class _ModelCard extends StatelessWidget {
  /// 创建型号入口卡片组件。
  const _ModelCard({required this.preview, required this.onTap});

  /// 卡片渲染用的预览模型数据。
  final _ModelPreview preview;

  /// 点击卡片时的回调。
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DeviceModelCard(
    title: preview.title,
    image: preview.image,
    baseColor: preview.surfaceColor,
    tags: preview.tags,
    heroTag: 'device-model-${preview.model.id ?? preview.title}',
    onTap: onTap,
    variant: DeviceModelCardVariant.home,
  );
}
