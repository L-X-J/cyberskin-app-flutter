// 运行页总剩余时间圆盘；计时数据完全由会话提供。
import 'package:cyberskin_app/core/theme/app_rhythm_style.dart';
import 'package:flutter/material.dart';

import '../../../widgets/rhythm_surface.dart';

/// 根据会话总剩余秒数展示计时圆盘。
final class RhythmTimer extends StatelessWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmTimer({super.key, required this.seconds});

  /// 会话传入的总剩余秒数。
  final int seconds;
  @override
  Widget build(BuildContext context) => Container(
    width: MediaQuery.textScalerOf(context).scale(24) * 3.4 + 38,
    constraints: BoxConstraints(
      minHeight: MediaQuery.textScalerOf(context).scale(24) * 3.4 + 38,
    ),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: AppRhythmStyle.pink.withValues(alpha: .7),
        width: 4,
      ),
      gradient: const RadialGradient(
        center: Alignment(0, -.4),
        colors: [AppRhythmStyle.pinkBright, Color(0xFFE3B7E0)],
      ),
      boxShadow: const [
        BoxShadow(color: Color(0x44FFFFFF), blurRadius: 4, spreadRadius: 1),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Time', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          rhythmTime(seconds),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
