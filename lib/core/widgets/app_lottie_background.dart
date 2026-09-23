// 跨业务 Lottie 背景组件：统一铺满、底色、播放倍速和无限循环策略。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../extensions/string_extensions.dart';
import '../theme/app_colors.dart';

/// 可跨页面复用的 Lottie 全屏背景。
///
/// 组件只负责渲染装饰背景，不承载业务状态或交互。默认使用初始化页的
/// `init_bg` 素材、App 统一底色和一倍速；[playbackSpeed] 可在运行时调整，
/// 动画会始终保持无限循环。调用方必须为组件提供有界约束，通常作为页面
/// `Stack` 的首个全屏子节点使用。
final class AppLottieBackground extends StatefulWidget {
  /// 创建 Lottie 全屏背景。
  ///
  /// [assetName] 为 `assets/lotties/` 下不含扩展名的素材名；[playbackSpeed]
  /// 必须大于零。非法速度在发布构建中回退为一倍速，避免背景阻断页面渲染。
  const AppLottieBackground({
    super.key,
    this.assetName = 'init_bg',
    this.playbackSpeed = 1,
    this.backgroundColor = AppColors.scaffold,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  }) : assert(
         playbackSpeed > 0 && playbackSpeed < double.infinity,
         'playbackSpeed must be finite and greater than zero.',
       );

  /// `assets/lotties/` 下不含扩展名的 Lottie 素材名。
  final String assetName;

  /// 动画相对原始时长的播放倍速，`1` 表示原速。
  final double playbackSpeed;

  /// 动画加载前、透明区域或加载失败时使用的背景色。
  final Color backgroundColor;

  /// 动画在可用区域内的适配方式；默认裁切铺满背景。
  final BoxFit fit;

  /// 动画在可用区域内的对齐方式。
  final AlignmentGeometry alignment;

  @override
  State<AppLottieBackground> createState() => _AppLottieBackgroundState();
}

final class _AppLottieBackgroundState extends State<AppLottieBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Duration? _compositionDuration;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didUpdateWidget(AppLottieBackground oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 素材切换时必须停止旧动画；新素材加载完成后会在 onLoaded 中重新启动。
    if (oldWidget.assetName != widget.assetName) {
      _controller.stop();
      _compositionDuration = null;
      return;
    }

    if (oldWidget.playbackSpeed != widget.playbackSpeed &&
        _compositionDuration != null) {
      _startRepeatingAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: widget.backgroundColor,
      child: SizedBox.expand(
        // 纯装饰背景不参与指针命中或无障碍语义，避免覆盖页面内容交互。
        child: ExcludeSemantics(
          child: IgnorePointer(
            child: LottieBuilder.asset(
              widget.assetName.assetsLottie,
              controller: _controller,
              onLoaded: (composition) {
                _compositionDuration = composition.duration;
                _startRepeatingAnimation();
              },
              fit: widget.fit,
              alignment: widget.alignment,
              errorBuilder: (_, _, _) => const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  /// 按当前速度重建无限循环周期。
  ///
  /// Lottie 的原始时长以微秒保存，速度变化时直接设置 `AnimationController.duration`
  /// 并从当前进度继续循环，避免页面或父布局重建导致动画跳回起点。
  void _startRepeatingAnimation() {
    final compositionDuration = _compositionDuration;
    if (compositionDuration == null ||
        compositionDuration.inMicroseconds <= 0) {
      return;
    }

    final speed = widget.playbackSpeed > 0 && widget.playbackSpeed.isFinite
        ? widget.playbackSpeed
        : 1.0;
    final cycleMicroseconds = math.max(
      1,
      (compositionDuration.inMicroseconds / speed).round(),
    );
    _controller.duration = Duration(microseconds: cycleMicroseconds);
    _controller.repeat();
  }
}
