// 通用 HTML 内容加载与渲染组件。
//
// 从远端 URL 拉取 HTML 字符串，借助磁盘缓存避免重复网络请求，
// 并使用 flutter_widget_from_html 将内容渲染为 Flutter 原生 Widget 树。
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// 从 [url] 加载并渲染 HTML 内容的通用组件。
///
/// 内部通过 [DefaultCacheManager] 管理磁盘缓存，自动尊重服务端 HTTP
/// 缓存头（Cache-Control / ETag / Last-Modified），同一 URL 在缓存有效
/// 期内不会重复发起网络请求。URL 发生变化时组件会自动重新拉取。
///
/// 加载过程显示骨架占位动画；拉取失败或内容为空时显示友好提示文字。
final class AppHtmlContent extends StatefulWidget {
  /// 创建 HTML 内容组件。
  ///
  /// [url] 必须是合法的 HTTP/HTTPS 地址。
  /// [textStyle] 为可选的正文字体覆盖；为空时使用 [AppTypography.bodyMedium]。
  const AppHtmlContent({
    super.key,
    required this.url,
    this.textStyle,
  });

  /// HTML 内容的远端地址。
  final String url;

  /// 覆盖默认正文字体样式。
  final TextStyle? textStyle;

  @override
  State<AppHtmlContent> createState() => _AppHtmlContentState();
}

final class _AppHtmlContentState extends State<AppHtmlContent> {
  // 已加载的 HTML 字符串；null 表示尚未完成加载。
  String? _html;
  // 是否正在拉取中。
  bool _loading = true;
  // 是否发生了拉取错误。
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(AppHtmlContent old) {
    super.didUpdateWidget(old);
    // URL 变更时重置状态并重新拉取，避免展示上一个 URL 的缓存内容。
    if (old.url != widget.url) {
      setState(() {
        _html = null;
        _loading = true;
        _error = false;
      });
      _fetch();
    }
  }

  /// 通过磁盘缓存管理器拉取 HTML 内容。
  ///
  /// 网络请求失败或文件读取异常时静默降级，不向上抛出；
  /// 单个内容分段失败不应影响整页其他内容的展示。
  Future<void> _fetch() async {
    try {
      final file = await DefaultCacheManager().getSingleFile(widget.url);
      if (!mounted) return;
      final html = await file.readAsString();
      if (!mounted) return;
      setState(() {
        _html = html;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppHtmlSkeleton();
    }
    if (_error || _html == null || _html!.trim().isEmpty) {
      return Text(
        '暂无内容',
        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      );
    }
    return HtmlWidget(
      _html!,
      textStyle: widget.textStyle ??
          AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
    );
  }
}

/// 加载中的骨架占位动画。
///
/// 用若干宽度不一的圆角条模拟段落文字形态，配合透明度脉冲动画，
/// 比旋转指示器更贴近最终内容的视觉结构。可在 [AppHtmlContent]
/// 之外独立使用，例如在父级已知数据加载中时提前占位。
final class AppHtmlSkeleton extends StatefulWidget {
  /// 创建骨架占位组件。
  const AppHtmlSkeleton({super.key});

  @override
  State<AppHtmlSkeleton> createState() => _AppHtmlSkeletonState();
}

final class _AppHtmlSkeletonState extends State<AppHtmlSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _opacity,
    builder: (_, child) => Opacity(
      opacity: _opacity.value,
      child: const _SkeletonLines(),
    ),
  );
}

/// 骨架占位的具体线条布局。
final class _SkeletonLines extends StatelessWidget {
  const _SkeletonLines();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // 模拟标题行
      _bar(width: 0.55),
      const SizedBox(height: 18),
      // 第一段落
      _bar(width: 1.0),
      const SizedBox(height: 8),
      _bar(width: 0.95),
      const SizedBox(height: 8),
      _bar(width: 0.88),
      const SizedBox(height: 8),
      _bar(width: 0.70),
      const SizedBox(height: 24),
      // 第二段落
      _bar(width: 1.0),
      const SizedBox(height: 8),
      _bar(width: 0.92),
      const SizedBox(height: 8),
      _bar(width: 0.50),
    ],
  );

  Widget _bar({required double width}) => FractionallySizedBox(
    widthFactor: width,
    child: Container(
      height: 13,
      decoration: BoxDecoration(
        color: AppColors.white20,
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}
