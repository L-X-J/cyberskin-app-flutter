// 主页已连接状态及设备、训练和广告展示组件。
import 'package:flutter/material.dart';

import '../../../../app/widgets/app_glass_surfaces.dart';
import '../../../../app/widgets/app_scaffold.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_layered_gradient_card.dart';
import '../../../content/domain/entities/app_content.dart';
import '../../../training/domain/entities/training.dart';
import '../home_dashboard.dart';
import '../widgets/home_shared_widgets.dart';

/// 设备已连接状态；内容由 Repository 快照驱动。
final class HomeConnectedView extends StatelessWidget {
  /// 创建已连接状态组件。
  const HomeConnectedView({
    super.key,
    required this.dashboard,
    required this.isLoading,
    required this.failureMessage,
    required this.onDeviceDetails,
    required this.onDeviceManual,
    required this.onProfile,
    required this.onReload,
  });

  /// 主页冻结可渲染数据。
  final HomeDashboard dashboard;

  /// 是否加载中。
  final bool isLoading;

  /// 失败错误信息。
  final String? failureMessage;

  /// 打开设备回调。
  final VoidCallback onDeviceDetails;

  /// 打开设备说明书回调。
  final VoidCallback onDeviceManual;

  /// 打开个人中心回调。
  final VoidCallback onProfile;

  /// 重试重新加载回调。
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final device = dashboard.currentDevice;
    final bound = dashboard.boundDevice;
    final deviceName = device?.name ?? bound?.customName ?? bound?.modelName;
    final bottomInset = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: true,
    );
    return HomeBackground(
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, 28, 24, bottomInset),
        children: [
          const HomeHeader(
            title: 'My device',
            subtitle: 'Good evening, stay relaxed',
          ),
          const SizedBox(height: 28),
          _ConnectedDeviceCard(
            name: deviceName ?? 'Cyberskin Air',
            battery: device?.batteryPercent,
            imageUrl: 'assets/images/home/device_pro_connected.png',
            onOpen: onDeviceDetails,
            onManual: onDeviceManual,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  title: 'Free control\nmode',
                  icon: Icons.tune,
                  colors: const [Color(0xFFE4472A), Color(0xFF8E171A)],
                  onTap: onDeviceDetails,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FeatureCard(
                  title: 'Customrhythm',
                  icon: Icons.show_chart,
                  colors: const [Color(0xFFBEF77A), Color(0xFF4B9C58)],
                  onTap: onDeviceDetails,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TrainingCard(
            summary: dashboard.trainings.isEmpty
                ? null
                : dashboard.trainings.first,
            onTap: onDeviceDetails,
          ),
          if (dashboard.advertisements.isNotEmpty) ...[
            const SizedBox(height: 16),
            _AdvertisementCard(advertisement: dashboard.advertisements.first),
          ],
          if (failureMessage != null) ...[
            const SizedBox(height: 12),
            AppInlineHint(
              icon: Icons.sync_problem_outlined,
              text: failureMessage!,
              onTap: onReload,
            ),
          ],
          if (isLoading) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }
}

/// 已连接设备主卡。
final class _ConnectedDeviceCard extends StatelessWidget {
  const _ConnectedDeviceCard({
    required this.name,
    required this.battery,
    required this.imageUrl,
    required this.onOpen,
    required this.onManual,
  });

  final String name;
  final int? battery;
  final String imageUrl;
  final VoidCallback onOpen;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    return AppLayeredGradientCard(
      height: 179,
      baseColor: const Color(0xFF5E185F),
      topGradientColors: const [Colors.black, Color(0xFFC95FD0)],
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadius.card,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('⌁  · Connected', style: TextStyle(fontSize: 13)),
                  const Spacer(),
                  AppTextButtonSurface(
                    label: '${battery ?? 67}%',
                    leadingIcon: Icons.power_settings_new,
                    onPressed: onOpen,
                  ),
                  const SizedBox(height: 8),
                  AppTextButtonSurface(
                    label: 'Product manual',
                    leadingIcon: Icons.description_outlined,
                    onPressed: onManual,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 16,
              top: -6,
              width: 132,
              height: 166,
              child: AppImage.load(imageUrl, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}

/// 自由控制与自定义节奏入口卡。
final class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppLayeredGradientCard(
      height: 170,
      baseColor: colors.last,
      topGradientColors: [Colors.black, colors.first],
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, height: 1.15)),
              const Spacer(),
              Icon(icon, size: 64, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

/// 训练摘要卡。
final class _TrainingCard extends StatelessWidget {
  const _TrainingCard({required this.summary, required this.onTap});

  final TrainingSummary? summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = summary?.nameEn ?? "Rhythm Adaptation · Beginner's Guide";
    final seconds = summary?.totalSeconds;
    final duration = seconds == null
        ? '12 minutes'
        : '${seconds ~/ 60} minutes';
    final stages = summary?.stageCount ?? 4;
    final intensity = summary?.intensity ?? 'Low intensity';
    return AppGlassCard(
      height: 136,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Training mode', style: TextStyle(fontSize: 17)),
                  const Spacer(),
                  AppTextButtonSurface(
                    label: 'More',
                    leadingIcon: Icons.grid_view_outlined,
                    onPressed: onTap,
                  ),
                ],
              ),
              const Spacer(),
              AppGlassCard(
                height: 62,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: AppImage.load(
                        'assets/images/home/training_thumb.png',
                        width: 44,
                        height: 44,
                        radius: 22,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$duration · $stages stages · $intensity',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 后台广告卡片；图片缺失时仍保留文本层级。
final class _AdvertisementCard extends StatelessWidget {
  const _AdvertisementCard({required this.advertisement});

  final AppAdvertisement advertisement;

  @override
  Widget build(BuildContext context) {
    return AppGlassCard(
      height: 124,
      child: Stack(
        children: [
          if (advertisement.imageUrl != null)
            Positioned.fill(
              child: AppImage.load(
                advertisement.imageUrl,
                fit: BoxFit.cover,
                radius: 32,
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.card,
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 100, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advertisement.titleEn ?? 'The GalaxyVoy1',
                  style: const TextStyle(fontSize: 17),
                ),
                const SizedBox(height: 4),
                Text(
                  advertisement.subtitleEn ?? 'New product launch',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  '12 modes of vibration heating',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
