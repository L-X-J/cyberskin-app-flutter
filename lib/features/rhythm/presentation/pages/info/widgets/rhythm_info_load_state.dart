// 详情页完整程序加载状态与重试入口，不在 Widget 内执行下载或缓存 IO。
import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_rhythm_style.dart';

/// 下载 JSON、解析与读取能力期间提供即时反馈，失败时允许显式重试。
final class RhythmInfoLoadState extends StatelessWidget {
  /// 创建详情加载提示。
  const RhythmInfoLoadState({
    super.key,
    required this.loading,
    required this.onRetry,
  });

  /// 完整程序及型号能力是否仍在准备。
  final bool loading;

  /// 当前选择的重试动作，由 Controller 编排。
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
    child: Center(
      child: loading
          ? const Column(
              key: ValueKey('rhythm-info-loading'),
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(semanticsLabel: 'Loading rhythm'),
                SizedBox(height: 16),
                Text(
                  'Loading rhythm…',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppRhythmStyle.secondary),
                ),
              ],
            )
          : TextButton(onPressed: onRetry, child: const Text('Retry')),
    ),
  );
}
