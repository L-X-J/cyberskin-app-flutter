// 跨业务图片组件：统一资源、本地文件与网络图片的加载、占位和预览交互。
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_radius.dart';

/// 图片组件统一入口。
///
/// [url] 支持 `assets/images/` 资源、绝对本地路径、HTTP/HTTPS 地址以及 `asset:`
/// 前缀。组件本身不判断业务场景，不依赖 GetX 或 Repository；预览使用稳定的
/// `showDialog` 路由，不引入原项目的全局 Dialog 单例。
abstract final class AppImage {
  /// 创建可加载资源、本地文件或网络图片的 Widget。
  ///
  /// 默认在 URL 为空或加载失败时展示 [placeholder]；[placeholder] 为空时显示透明占位，
  /// 避免在尚未确认默认素材时引用不存在的资源路径。[borderRadius] 和 [width]/[height]
  /// 由调用方按页面布局传入，组件不内置业务尺寸。
  static Widget load(
    String? url, {
    Key? key,
    double? radius,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    ExtendedImageMode mode = ExtendedImageMode.none,
    LoadStateChanged? loadStateChanged,
    bool showPlaceholderWhileLoading = true,
    Color? color,
    Widget? placeholder,
    Widget? errorWidget,
    String? semanticLabel,
    VoidCallback? onTap,
  }) {
    final borderRadius = AppRadius.circular(radius ?? 0);
    final resolved = _resolveSource(url);
    if (resolved == null) {
      return _decorate(
        key: key,
        borderRadius: borderRadius,
        width: width,
        height: height,
        child: errorWidget ?? placeholder ?? const SizedBox.shrink(),
        onTap: onTap,
      );
    }

    if (resolved is _AssetSource && resolved.path.endsWith('.svg')) {
      return _decorate(
        key: key,
        borderRadius: borderRadius,
        width: width,
        height: height,
        onTap: onTap,
        child: SvgPicture.asset(
          resolved.path,
          width: width,
          height: height,
          fit: fit,
          colorFilter: color == null
              ? null
              : ColorFilter.mode(color, BlendMode.srcIn),
          semanticsLabel: semanticLabel,
          errorBuilder: (_, _, _) =>
              errorWidget ?? placeholder ?? const SizedBox.shrink(),
        ),
      );
    }

    final image = switch (resolved) {
      final _AssetSource source => ExtendedImage.asset(
        source.path,
        key: key,
        width: width,
        height: height,
        fit: fit,
        color: color,
        mode: mode,
        semanticLabel: semanticLabel,
        loadStateChanged: (state) =>
            loadStateChanged?.call(state) ??
            _loadStateChanged(
              state,
              width: width,
              height: height,
              fit: fit,
              placeholder: placeholder,
              errorWidget: errorWidget,
              showPlaceholderWhileLoading: showPlaceholderWhileLoading,
            ),
      ),
      final _FileSource source => ExtendedImage.file(
        File(source.path),
        key: key,
        width: width,
        height: height,
        fit: fit,
        color: color,
        mode: mode,
        semanticLabel: semanticLabel,
        loadStateChanged: (state) =>
            loadStateChanged?.call(state) ??
            _loadStateChanged(
              state,
              width: width,
              height: height,
              fit: fit,
              placeholder: placeholder,
              errorWidget: errorWidget,
              showPlaceholderWhileLoading: showPlaceholderWhileLoading,
            ),
      ),
      final _NetworkSource source => ExtendedImage.network(
        source.url,
        key: key,
        width: width,
        height: height,
        fit: fit,
        color: color,
        mode: mode,
        semanticLabel: semanticLabel,
        cache: true,
        loadStateChanged: (state) =>
            loadStateChanged?.call(state) ??
            _loadStateChanged(
              state,
              width: width,
              height: height,
              fit: fit,
              placeholder: placeholder,
              errorWidget: errorWidget,
              showPlaceholderWhileLoading: showPlaceholderWhileLoading,
            ),
      ),
    };

    return _decorate(
      key: key,
      borderRadius: borderRadius,
      width: width,
      height: height,
      onTap: onTap,
      child: image,
    );
  }

  /// 预加载网络图片。
  ///
  /// 返回预加载 Future，调用方可选择等待或忽略；失败由 Flutter 图片缓存报告，不改变
  /// 当前页面业务状态。
  static Future<void> preCache(BuildContext context, String url) {
    return precacheImage(
      ExtendedNetworkImageProvider(url, cache: true),
      context,
    );
  }

  /// 打开单张图片预览，支持手势缩放和点击背景关闭。
  static Future<void> showPreview(
    BuildContext context, {
    required String? url,
    Widget? placeholder,
    String? semanticLabel,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => _ImagePreview(
        urls: <String>[if (url != null && url.isNotEmpty) url],
        initialIndex: 0,
        placeholder: placeholder,
        semanticLabel: semanticLabel,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  /// 打开多图画廊预览，支持左右滑动、缩放和点击背景关闭。
  static Future<void> showGallery(
    BuildContext context, {
    required List<String> urls,
    int initialIndex = 0,
    Widget? placeholder,
    String? semanticLabel,
  }) {
    if (urls.isEmpty) {
      return Future<void>.value();
    }
    final safeInitialIndex = initialIndex.clamp(0, urls.length - 1);
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => _ImagePreview(
        urls: List<String>.unmodifiable(urls),
        initialIndex: safeInitialIndex,
        placeholder: placeholder,
        semanticLabel: semanticLabel,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  static Widget? _loadStateChanged(
    ExtendedImageState state, {
    required double? width,
    required double? height,
    required BoxFit fit,
    required Widget? placeholder,
    required Widget? errorWidget,
    required bool showPlaceholderWhileLoading,
  }) {
    return switch (state.extendedImageLoadState) {
      LoadState.loading =>
        showPlaceholderWhileLoading
            ? _emptyImage(
                width: width,
                height: height,
                fit: fit,
                child: placeholder,
              )
            : null,
      LoadState.completed => state.completedWidget,
      LoadState.failed => _emptyImage(
        width: width,
        height: height,
        fit: fit,
        child: errorWidget ?? placeholder,
      ),
    };
  }

  static Widget _emptyImage({
    required double? width,
    required double? height,
    required BoxFit fit,
    required Widget? child,
  }) {
    if (child == null) {
      return SizedBox(width: width, height: height);
    }
    return SizedBox(
      width: width,
      height: height,
      child: FittedBox(fit: fit, child: child),
    );
  }

  static Widget _decorate({
    required Key? key,
    required BorderRadius borderRadius,
    required double? width,
    required double? height,
    required Widget child,
    VoidCallback? onTap,
  }) {
    Widget result = ClipRRect(
      key: key,
      borderRadius: borderRadius,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(width: width, height: height, child: child),
    );
    if (onTap != null) {
      result = GestureDetector(onTap: onTap, child: result);
    }
    return result;
  }

  static _ImageSource? _resolveSource(String? url) {
    final value = url?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.startsWith('assets/') || value.startsWith('asset:')) {
      return _AssetSource(
        value.startsWith('asset:') ? value.substring(6) : value,
      );
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return _NetworkSource(value);
    }
    return _FileSource(value);
  }
}

sealed class _ImageSource {
  const _ImageSource();
}

final class _AssetSource extends _ImageSource {
  const _AssetSource(this.path);

  final String path;
}

final class _FileSource extends _ImageSource {
  const _FileSource(this.path);

  final String path;
}

final class _NetworkSource extends _ImageSource {
  const _NetworkSource(this.url);

  final String url;
}

final class _ImagePreview extends StatefulWidget {
  const _ImagePreview({
    required this.urls,
    required this.initialIndex,
    required this.onClose,
    this.placeholder,
    this.semanticLabel,
  });

  final List<String> urls;
  final int initialIndex;
  final VoidCallback onClose;
  final Widget? placeholder;
  final String? semanticLabel;

  @override
  State<_ImagePreview> createState() => _ImagePreviewState();
}

final class _ImagePreviewState extends State<_ImagePreview> {
  late int _current;
  late ExtendedPageController _controller;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = ExtendedPageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClose,
      child: SizedBox.expand(
        child: Stack(
          children: [
            ExtendedImageGesturePageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (index) => setState(() => _current = index),
              itemBuilder: (_, index) => AppImage.load(
                widget.urls[index],
                fit: BoxFit.contain,
                mode: ExtendedImageMode.gesture,
                placeholder: widget.placeholder,
                semanticLabel: widget.semanticLabel,
                loadStateChanged: (state) => state.completedWidget,
              ),
            ),
            if (widget.urls.length > 1)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_current + 1} / ${widget.urls.length}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
