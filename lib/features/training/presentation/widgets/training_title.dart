// 课程标题的入口专属 Hero；异步详情更新保持同一个 tag。
import 'package:flutter/material.dart';

/// 共享元素转场的训练标题；入口和课程共同定义 tag。
final class TrainingTitle extends StatelessWidget {
  /// 创建共享元素转场的训练标题；入口和课程共同定义 tag。
  const TrainingTitle({
    super.key,
    required this.title,
    required this.tag,
    this.fontSize = 18,
  });

  /// 来自课程摘要或页面约定的标题文案。
  final String title;

  /// 包含入口及课程身份的 Hero 标签。
  final String tag;

  /// 该标题在当前页面的逻辑字号。
  final double fontSize;
  @override
  Widget build(BuildContext context) => Hero(
    tag: tag,
    child: Material(
      color: Colors.transparent,
      child: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    ),
  );
}
