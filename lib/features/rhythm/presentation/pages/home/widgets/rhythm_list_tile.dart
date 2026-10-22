// 列表日期徽标和玻璃节奏卡片。
import 'package:cyberskin_app/core/theme/app_rhythm_style.dart';
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../domain/entities/rhythm.dart';

/// 可点击运行、长按管理的节奏摘要卡片。
final class RhythmListTile extends StatelessWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmListTile({
    super.key,
    required this.rhythm,
    required this.onTap,
    required this.onLongPress,
  });

  /// 当前会话绑定的不可变节奏快照。
  final Rhythm rhythm;

  /// 运行入口及长按管理入口，由父页面编排。
  final VoidCallback onTap, onLongPress;
  @override
  Widget build(BuildContext context) {
    final date = rhythm.createTime;

    final label = date == null
        ? '—'
        : '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return Semantics(
      customSemanticsActions: {
        const CustomSemanticsAction(label: 'Edit or delete rhythm'):
            onLongPress,
      },
      child: GestureDetector(
        onLongPress: onLongPress,
        child: AppLiquidGlassButton(
          label: rhythm.name ?? 'Custom rhythm',
          height: 78 + (MediaQuery.textScalerOf(context).scale(18) - 18) * 2,
          width: double.infinity,
          borderRadius: 16,
          contentPadding: const EdgeInsets.all(12),
          variant: AppLiquidGlassButtonVariant.translucent,
          onPressed: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppRhythmStyle.pink, Color(0xFFC65DC3)],
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rhythm.name ?? 'Custom rhythm',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rhythm.deviceModelName ??
                            'Device ${rhythm.deviceModelId ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppRhythmStyle.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
