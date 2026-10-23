// 训练计时圆盘与指标卡；只消费引擎总剩余秒数，没有独立 UI 定时器。
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_rhythm_style.dart';

/// 使用总剩余秒数格式化 MM:SS，不启动独立计时器。
String trainingTime(int seconds) =>
    '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

/// 随文字和宽度约束调整的总剩余时间圆盘。
final class TrainingTimer extends StatelessWidget {
  /// 创建随文字和宽度约束调整的总剩余时间圆盘。
  const TrainingTimer({
    super.key,
    required this.remaining,
    required this.total,
  });

  /// 课程真实总秒数，用于计算统一进度。
  final int remaining, total;
  @override
  Widget build(BuildContext context) {
    final size = math.max(
      202.0,
      MediaQuery.textScalerOf(context).scale(44) * 4.6,
    );
    return LayoutBuilder(
      builder: (context, constraints) => Semantics(
        label: 'Time remaining ${trainingTime(remaining)}',
        child: SizedBox.square(
          dimension: math.min(size, constraints.maxWidth),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFBD96DB), width: 4),
                  gradient: const RadialGradient(
                    colors: [
                      AppRhythmStyle.pinkBright,
                      AppRhythmStyle.pinkBright,
                      Color(0xFFE2A5CF),
                    ],
                    stops: [0, .55, 1],
                  ),
                ),
              ),
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: total <= 0
                      ? 0
                      : ((total - remaining) / total).clamp(0, 1),
                  strokeWidth: 4,
                  color: Colors.white54,
                  backgroundColor: Colors.transparent,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Time',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trainingTime(remaining),
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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

/// 按内容自然增高的训练统计卡片。
final class TrainingMetric extends StatelessWidget {
  /// 创建按内容自然增高的训练统计卡片。
  const TrainingMetric({super.key, required this.label, required this.value});

  /// 从同一课程或引擎快照导出的展示值。
  final String label, value;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0x990D0B27),
      borderRadius: BorderRadius.circular(32),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF34204C), Color(0xFF795AA7)],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Color(0xFFC7C3D5)),
          ),
        ],
      ),
    ),
  );
}
