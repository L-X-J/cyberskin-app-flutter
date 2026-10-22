// 节奏专属内发光表面、错误提示和时间格式展示。
import 'package:flutter/material.dart';

import '../../../../core/theme/app_rhythm_style.dart';
import '../../../../core/widgets/app_layered_gradient_card.dart';

/// 节奏专用内发光面板，内容尺寸由正常布局决定。
final class RhythmSurface extends StatelessWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  /// 正常流式布局内容，不包含业务控制逻辑。
  final Widget child;

  /// 表面内部留白。
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => AppLayeredGradientCard(
    baseColor: AppRhythmStyle.panel,
    topGradientColors: const [Colors.transparent, Colors.transparent],
    innerShadowColor: AppRhythmStyle.panelGlow,
    innerShadowBlur: 48,
    innerShadowSpread: 0,
    topLayerBlur: 12,
    borderRadius: AppRhythmStyle.radius,
    child: Padding(padding: padding, child: child),
  );
}

/// 可被辅助技术及时朗读的错误提示。
final class RhythmError extends StatelessWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmError(this.message, {super.key});

  /// 用户可见状态说明；为空时不展示提示。
  final String? message;
  @override
  Widget build(BuildContext context) => message == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(
              message!,
              style: const TextStyle(color: Color(0xFFFFCFDF)),
              textAlign: TextAlign.center,
            ),
          ),
        );
}

/// 把剩余秒数格式化为分钟和秒。
String rhythmTime(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
