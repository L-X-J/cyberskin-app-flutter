// 共享播放器的 Flutter 适配宿主；封装插件资源、生命周期和只影响播放区域的进度状态。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_video_feed_list/flutter_video_feed_list.dart';

import '../../../core/theme/app_video_style.dart';
import '../domain/entities/video_media.dart';

/// 官方信息流和本地视频共用的播放区域，不处理文件选择、HTTP 或设备指令。
final class VideoPlayerSurface extends StatefulWidget {
  /// 创建播放器宿主；active 必须由导航、标签与路由共同决定。
  const VideoPlayerSurface({
    super.key,
    required this.items,
    required this.feedId,
    required this.active,
    required this.fullscreen,
    required this.onFullscreen,
    this.bottomPadding = 0,
    this.onIndexChanged,
    this.onChoose,
    this.scrollable = true,
  });

  /// 不可变媒体列表。
  final List<VideoMedia> items;

  /// 不同来源的独立播放会话名。
  final String feedId;

  /// 宿主是否允许播放。
  final bool active;

  /// 是否占用完整视口。
  final bool fullscreen;

  /// 请求改变全屏布局，不重建播放器。
  final VoidCallback onFullscreen;

  /// 主导航与设备浮层占用的底部余量。
  final double bottomPadding;

  /// 当前官方视频改变后触发分页预取。
  final ValueChanged<int>? onIndexChanged;

  /// 重新选择本地视频。
  final VoidCallback? onChoose;

  /// 本地单视频关闭纵向滑动。
  final bool scrollable;

  /// 创建独立平台资源宿主。
  @override
  State<VideoPlayerSurface> createState() => VideoPlayerSurfaceState();
}

/// 提供不泄露插件类型的选片跳转入口。
final class VideoPlayerSurfaceState extends State<VideoPlayerSurface>
    with WidgetsBindingObserver {
  final _feed = VideoFeedViewController();
  final _progress = ValueNotifier<_PlaybackSnapshot>(const _PlaybackSnapshot());
  final _failedIds = <String>{};
  bool _foreground = true;
  int _index = 0;
  late List<IVideoItem> _items;

  /// 初始化插件数据并监听系统生命周期。
  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _updateItems();
    WidgetsBinding.instance.addObserver(this);
  }

  /// 媒体对象变化才重新映射，进度更新不触发整个信息流重建。
  @override
  void didUpdateWidget(VideoPlayerSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) _updateItems();
  }

  /// 将领域快照转换为优化插件的数据契约，缓存身份包含资源地址。
  void _updateItems() {
    _items = widget.items
        .map(
          (media) => DefaultVideoItem(
            id: '${media.id}:${media.videoUrl}',
            videoUrl: media.videoUrl,
            coverUrl: media.coverUrl,
            videoWidth: media.width,
            videoHeight: media.height,
            videoCoverWidth: media.coverWidth,
            videoCoverHeight: media.coverHeight,
          ),
        )
        .toList(growable: false);
    if (_index >= _items.length) _index = 0;
  }

  /// 选片只跳转现有流，不销毁当前视图或重复请求详情。
  Future<void> jumpToIndex(int index) => _feed.jumpToIndex(index);

  /// 前后台许可同步到插件，防止初始化完成或缓冲结束后在后台播放。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    setState(() => _foreground = state == AppLifecycleState.resumed);
  }

  /// 插件组件负责销毁控制器；宿主只释放自己的订阅和进度状态。
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progress.dispose();
    super.dispose();
  }

  /// 更新独立进度快照，不重建 PageView 和视频纹理。
  void _onProgress(VideoPlaybackProgressEvent event) {
    if (!mounted) return;
    _progress.value = _PlaybackSnapshot(
      position: event.position,
      duration: event.duration,
    );
  }

  /// 当前索引更新后清除上一条的进度；重复稳态通知不会清空当前进度。
  void _onIndex(int index) {
    if (!mounted) return;
    if (_index != index) {
      setState(() => _index = index);
      _progress.value = const _PlaybackSnapshot();
    }
    widget.onIndexChanged?.call(index);
  }

  /// 错误只保留媒体身份，界面不显示可能包含签名或本地路径的底层错误。
  void _onError(IVideoItem item) {
    if (mounted) setState(() => _failedIds.add(item.key));
  }

  /// 重新初始化当前媒体，不影响列表和其他来源的进度。
  Future<void> _retry() async {
    if (_items.isEmpty) return;
    setState(() => _failedIds.remove(_items[_index].key));
    await _feed.retryCurrent();
  }

  /// 渲染视频与控制条；跨来源媒体互斥由显式 active 许可保证。
  @override
  Widget build(BuildContext context) {
    final failed = _items.isNotEmpty && _failedIds.contains(_items[_index].key);
    final media = widget.items.isEmpty ? null : widget.items[_index];
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoFeedView(
            feedId: widget.feedId,
            controller: _feed,
            items: _items,
            playbackAllowed: widget.active && _foreground,
            preserveManualPause: true,
            reportPausedProgress: true,
            infiniteScroll: false,
            loop: widget.scrollable,
            allowUserScroll: widget.scrollable && !widget.fullscreen,
            preloadAround: widget.scrollable ? 1 : 0,
            maxCacheControllers: 2,
            preloadCoverAround: widget.scrollable ? 2 : 0,
            settleDelayMs: 10,
            videoDisplayMode: widget.fullscreen
                ? VideoDisplayMode.contain
                : VideoDisplayMode.adaptive,
            onIndexChanged: _onIndex,
            onPlaybackProgress: _onProgress,
            onPlaybackError: _onError,
            mediaOverlayBuilder: (context, item, index, mediaBounds) {
              if (index != _index) return null;
              return Positioned(
                left: mediaBounds.left,
                top: mediaBounds.bottom - AppVideoStyle.playbackTouchHeight,
                width: mediaBounds.width,
                height: AppVideoStyle.playbackTouchHeight,
                child: ValueListenableBuilder<_PlaybackSnapshot>(
                  valueListenable: _progress,
                  builder: (context, progress, _) => _PlaybackProgress(
                    progress: progress,
                    onSeek: _feed.seekTo,
                  ),
                ),
              );
            },
            logF: (_) {},
          ),
          if (failed)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Unable to play this video.',
                    textAlign: TextAlign.center,
                  ),
                  IconButton(
                    tooltip: 'Retry video',
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.fullscreen
                ? AppVideoStyle.playbackTouchHeight
                : widget.bottomPadding,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: SafeArea(
                top: false,
                bottom: widget.fullscreen,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          media?.title ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (widget.onChoose != null && !widget.fullscreen)
                        IconButton(
                          tooltip: 'Choose video',
                          onPressed: widget.onChoose,
                          color: Colors.white,
                          icon: const Icon(Icons.video_file_outlined),
                        ),
                      IconButton(
                        tooltip: widget.fullscreen
                            ? 'Exit full screen'
                            : 'Full screen',
                        onPressed: widget.onFullscreen,
                        color: Colors.white,
                        icon: Icon(
                          widget.fullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 控制条使用的只读局部快照，避免上升成全局共享状态。
final class _PlaybackSnapshot {
  const _PlaybackSnapshot({
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });
  final Duration position;
  final Duration duration;
}

/// 拖动时保留手指位置，松手才向原生播放器发送一次 seek。
final class _PlaybackProgress extends StatefulWidget {
  const _PlaybackProgress({required this.progress, required this.onSeek});
  final _PlaybackSnapshot progress;
  final Future<void> Function(Duration) onSeek;

  /// 创建进度拖动的局部状态。
  @override
  State<_PlaybackProgress> createState() => _PlaybackProgressState();
}

final class _PlaybackProgressState extends State<_PlaybackProgress> {
  double? _dragPosition;

  /// 将进度格式化为播放器的分秒或时分秒显示。
  String _time(Duration value) {
    final seconds = value.inSeconds;
    final minutes = (seconds ~/ 60 % 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 3600
        ? '${seconds ~/ 3600}:$minutes:$rest'
        : '$minutes:$rest';
  }

  /// 以固定高度渲染控制条，不让播放进度推动视频布局。
  @override
  Widget build(BuildContext context) {
    final total = widget.progress.duration.inMilliseconds.toDouble();
    final value =
        (_dragPosition ?? widget.progress.position.inMilliseconds.toDouble())
            .clamp(0.0, total > 0 ? total : 1.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: AppVideoStyle.playbackTouchHeight,
          child: SliderTheme(
            data: AppVideoStyle.playbackSliderTheme,
            child: Slider(
              value: value,
              max: total > 0 ? total : 1,
              semanticFormatterCallback: (value) =>
                  _time(Duration(milliseconds: value.round())),
              onChangeStart: total > 0
                  ? (value) => setState(() => _dragPosition = value)
                  : null,
              onChanged: total > 0
                  ? (value) => setState(() => _dragPosition = value)
                  : null,
              onChangeEnd: (value) {
                // 松手即隐藏提示；seek 的异步耗时不延长数值的展示时间。
                setState(() => _dragPosition = null);
                unawaited(widget.onSeek(Duration(milliseconds: value.round())));
              },
            ),
          ),
        ),
        if (_dragPosition != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: AppVideoStyle.playbackPreviewBottomGap,
            child: IgnorePointer(
              child: Text(
                '${_time(Duration(milliseconds: value.round()))} / ${_time(widget.progress.duration)}',
                key: const ValueKey('video-seek-time'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
