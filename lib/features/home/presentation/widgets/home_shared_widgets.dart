// 主页共享背景层与头部标题组件。
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';

/// 主页背景层；装饰可裁切，内容仍由正常滚动布局负责。
final class HomeBackground extends StatelessWidget {
  /// 创建主页背景组件。
  const HomeBackground({super.key, required this.child});

  /// 子组件内容。
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
final class HomeHeader extends StatelessWidget {
  /// 创建主页头部组件。
  const HomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onProfile,
  });

  /// 主标题。
  final String title;

  /// 副标题。
  final String subtitle;

  /// 点击个人中心头像回调。
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
