// 设备型号卡片的共享视觉组件，供首页型号入口和详情页型号选择器复用。
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import '../../../core/extensions/string_extensions.dart';
import '../../../core/theme/app_layered_gradient_style.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_img_group_80_card.dart';
import '../../../core/widgets/app_liquid_glass_button.dart';

/// 设备型号卡片的尺寸和内容变体。
enum DeviceModelCardVariant {
  /// 首页未连接设备入口。
  home,

  /// 详情页横向型号选择器。
  picker,
}

/// 统一绘制设备型号的彩色玻璃背景、设备图和 Hero 动画。
final class DeviceModelCard extends StatelessWidget {
  /// 创建型号卡片。
  const DeviceModelCard({
    required this.title,
    required this.image,
    required this.onTap,
    this.baseColor,
    this.tags = const <String>[],
    this.heroTag,
    this.variant = DeviceModelCardVariant.home,
    this.selected = false,
    super.key,
  });

  /// 型号名称。
  final String title;

  /// 型号产品图。
  final String? image;

  /// 卡片点击行为。
  final VoidCallback onTap;

  /// 后台配置的卡片底色。
  final Color? baseColor;

  /// 首页卡片右下角的设备标签。
  final List<String> tags;

  /// 产品图的共享 Hero 标识。
  final String? heroTag;

  /// 卡片展示变体。
  final DeviceModelCardVariant variant;

  /// 当前型号是否为选择器中的主型号。
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final compact = variant == DeviceModelCardVariant.picker;
    final surfaceColor = baseColor ?? AppLayeredGradientStyle.baseColor;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: compact && !selected ? 0.82 : 1,
        child: AppImgGroup80Card(
          backgroundColor: surfaceColor,
          height: compact ? 114 : 170,
          borderRadius: compact ? BorderRadius.circular(30) : AppRadius.card,
          child: InkWell(
            onTap: onTap,
            borderRadius: compact ? BorderRadius.circular(30) : AppRadius.card,
            child: LiquidGlassLayer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 10, 10),
                      child: Text(title, style: const TextStyle(fontSize: 16)),
                    ),
                  if (!compact && tags.isNotEmpty)
                    Positioned(
                      right: 16,
                      bottom: 45,
                      child: Text(
                        tags.join('\n'),
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.25,
                          color: Colors.white.withValues(alpha: 0.25),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (!compact)
                    Positioned(
                      left: 5,
                      right: 20,
                      bottom: 40,
                      child: AppImage.load(
                        'home/icons_lius'.assetsSvg,
                        width: 50,
                      ),
                    ),
                  if (image != null)
                    Positioned(
                      left: compact ? 14 : 0,
                      bottom: compact ? 8 : 0,
                      width: compact ? 84 : 108,
                      height: compact ? 96 : 120,
                      child: _HeroImage(tag: heroTag, image: image!),
                    ),
                  if (!compact)
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
        ),
      ),
    );
  }
}

final class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.tag, required this.image});

  final String? tag;
  final String image;

  @override
  Widget build(BuildContext context) {
    final child = AppImage.load(image, fit: BoxFit.contain);
    return tag == null ? child : Hero(tag: tag!, child: child);
  }
}
