// 主页共享背景层与头部标题组件。
import 'package:flutter/material.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';

import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/theme/app_blur.dart';
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

/// 首页标题区和头像入口；支持根据列表滑动进度动态渲染高斯模糊与暗色遮罩背景。
final class HomeHeader extends StatelessWidget {
  /// 创建主页头部组件。
  const HomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onProfile,
    this.topInset = 0,
    this.scrollProgress = 0,
    this.padding,
  });

  /// 主标题。
  final String title;

  /// 副标题。
  final String subtitle;

  /// 点击个人中心头像回调。
  final VoidCallback? onProfile;

  /// 状态栏顶部安全区内边距。
  final double topInset;

  /// 列表滑动驱动的高斯模糊与遮罩进度（0.0 表示无模糊，1.0 表示全模糊）。
  final double scrollProgress;

  /// 头部内边距；为空时默认为 `EdgeInsets.fromLTRB(24, topInset, 24, 10)`。
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        padding ?? EdgeInsets.fromLTRB(24, topInset, 24, 10);
    final progress = scrollProgress.clamp(0.0, 1.0);

    final content = Padding(
      padding: effectivePadding,
      child: Row(
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
      ),
    );

    if (progress <= 0) {
      return content;
    }

    return ClipRect(
      child: BackdropFilter(
        filter: AppBlur.backgroundFilter(progress * AppBlur.glassStrong),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.70 * progress),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08 * progress),
                width: 0.5,
              ),
            ),
          ),
          child: content,
        ),
      ),
    );
  }
}
