// 主页已连接状态及设备、训练和广告展示组件。
part of 'home_page.dart';

/// 设备已连接状态；内容由 Repository 快照驱动。
final class _ConnectedHome extends StatelessWidget {
  const _ConnectedHome({
    required this.dashboard,
    required this.isLoading,
    required this.failureMessage,
    required this.onDeviceDetails,
    required this.onDeviceManual,
    required this.onProfile,
    required this.onReload,
  });

  final HomeDashboard dashboard;
  final bool isLoading;
  final String? failureMessage;
  final VoidCallback onDeviceDetails;
  final VoidCallback onDeviceManual;
  final VoidCallback onProfile;
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
    return _HomeBackground(
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, 28, 24, bottomInset),
        children: [
          const _HomeHeader(
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

/// 主页背景层；装饰可裁切，内容仍由正常滚动布局负责。
final class _HomeBackground extends StatelessWidget {
  const _HomeBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      fake: true,
      useBackdropGroup: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          gradient: RadialGradient(
            center: Alignment(0.9, 0.25),
            radius: 1.1,
            colors: [Color(0xFF25163B), Color(0xFF101030), Color(0xFF020202)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// 首页标题区和头像入口。
final class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.title,
    required this.subtitle,
    this.onProfile,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 28, height: 1.2)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),

        AppLiquidGlassButton(
          label: 'Profile',
          variant: AppLiquidGlassButtonVariant.translucent,
          width: 50,
          height: 50,
          borderRadius: 25,
          onPressed: onProfile ?? () {},
          child: AppImage.load(
            'home/go_user_profile'.assetsPng,
            width: 50,
            height: 50,
          ),
        ),
      ],
    );
  }
}

/// 未连接扫描卡。
final class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.isLoading, required this.onStop});

  final bool isLoading;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassLayer(
      useBackdropGroup: true,
      fake: true,
      child: AppLayeredGradientCard.scan(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 22, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Searching for nearby devices ..',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 6),
              const Text(
                '"No devices found. Device connection methods\ncan be viewed below."',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  AppLiquidGlassButton(
                    label: 'Bluetooth scan',
                    icon: Icons.bluetooth,
                    onPressed: onStop,
                    variant: AppLiquidGlassButtonVariant.translucent,
                    width: 40,
                    height: 40,
                    iconSize: 16,
                    borderRadius: 12,
                  ),

                  const SizedBox(width: 8),
                  AppTextButtonSurface(
                    label: 'Stop',
                    onPressed: onStop,
                    width: 104,
                    height: 40,
                  ),
                  const Spacer(),
                  SizedBox.square(
                    dimension: 54,
                    child: isLoading
                        ? const Center(
                            child: AppFlowerLoadingIndicator(size: 42),
                          )
                        : const Icon(
                            Icons.bluetooth_disabled,
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
}

/// 未连接型号入口网格。
final class _DeviceModelGrid extends StatelessWidget {
  const _DeviceModelGrid({required this.models, required this.onTap});

  final List<DeviceModelSummary> models;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entries = models.isEmpty
        ? const <_ModelPreview>[
            _ModelPreview(
              title: 'Cyberskin Air',
              image: 'assets/images/home/device_air.png',
              surfaceColor: AppLayeredGradientStyle.baseColor,
            ),
            _ModelPreview(
              title: 'Cyberskin Pro',
              image: 'assets/images/home/device_pro.png',
              surfaceColor: Color(0xFF8AD36B),
            ),
          ]
        : models.take(2).map(_ModelPreview.fromModel).toList(growable: false);
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _ModelCard(preview: entries[i], onTap: onTap),
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
  const _ModelPreview({
    required this.title,
    required this.image,
    required this.surfaceColor,
    this.tags = const [],
  });

  factory _ModelPreview.fromModel(DeviceModelSummary model) => _ModelPreview(
    title: model.name ?? 'Cyberskin device',
    image: model.iconUrl,
    surfaceColor:
        _hexToColor(model.cardColor) ?? AppLayeredGradientStyle.baseColor,
    tags: List.unmodifiable(
      (model.tags ?? '')
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty),
    ),
  );
  final String title;
  final String? image;
  final Color surfaceColor;
  final List<String> tags;
}

final class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.preview, required this.onTap});

  final _ModelPreview preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppLayeredGradientCard(
      baseColor: preview.surfaceColor,
      height: 170,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: LiquidGlassLayer(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                child: Text(
                  preview.title,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              if (preview.tags.isNotEmpty)
                Positioned(
                  right: 16,
                  bottom: 45,
                  child: Text(
                    preview.tags.join('\n'),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: Colors.white.withValues(alpha: 0.25),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (preview.image != null)
                Positioned(
                  left: 0,
                  bottom: 0,
                  width: 108,
                  height: 120,
                  child: AppImage.load(preview.image, fit: BoxFit.contain),
                ),

              Positioned(
                right: 20,
                top: 20,
                child: AppLiquidGlassButton(
                  label: 'Open model',
                  icon: Icons.chevron_right,
                  onPressed: onTap,
                  variant: AppLiquidGlassButtonVariant.translucent,
                  iconSize: 16,
                  height: 20,
                  width: 20,
                  borderRadius: 10,
                ),
              ),
            ],
          ),
        ),
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
                  Row(
                    children: [
                      AppTextButtonSurface(
                        label: '◴ ${battery ?? 67}%',
                        onPressed: onOpen,
                      ),
                      const SizedBox(width: 8),
                      AppIconButtonSurface(
                        icon: Icons.power_settings_new,
                        onPressed: onOpen,
                        label: 'Power',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppTextButtonSurface(
                    label: '▣  Product manual',
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
                  AppTextButtonSurface(label: '▦ More', onPressed: onTap),
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
