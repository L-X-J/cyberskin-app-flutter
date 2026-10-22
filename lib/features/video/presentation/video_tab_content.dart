// 共享 TabBar 与横向 PageView，组合官方信息流、网页入口和本地播放三个常驻子页。
import 'dart:async';

import 'package:cyberskin_app/core/extensions/ui_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../app/floating_control_controller.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../core/widgets/app_image.dart';
import 'video_controller.dart';
import 'video_player_surface.dart';
import 'video_source_entries.dart';

/// 可内嵌于首页的视频体验，外层明确提供一级导航可见性。
final class VideoTabContent extends StatefulWidget {
  /// 创建共享内容；独立视频路由默认可见。
  const VideoTabContent({
    super.key,
    required this.controller,
    this.active = true,
  });

  /// 来源与数据状态。
  final VideoController controller;

  /// 一级 Device / Video 内容切换时的显式播放许可。
  final bool active;

  /// 创建标签页状态。
  @override
  State<VideoTabContent> createState() => _VideoTabContentState();
}

final class _VideoTabContentState extends State<VideoTabContent>
    with SingleTickerProviderStateMixin {
  late final PageController _pages;
  late final TabController _tabs;
  late final Worker _tabWorker;
  bool _switching = false;

  /// 两个导航控件共享初始索引，避免标签高亮与实际页不同步。
  @override
  void initState() {
    super.initState();
    final initial = widget.controller.selectedTab.value.index;
    _pages = PageController(initialPage: initial);
    _tabs = TabController(length: 3, vsync: this, initialIndex: initial);
    _tabWorker = ever(widget.controller.selectedTab, (tab) {
      if (_tabs.index != tab.index) _tabs.animateTo(tab.index);
    });
  }

  /// 隐藏一级视频页时退出全屏；不能把全屏状态带到设备页面。
  @override
  void didUpdateWidget(VideoTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.active &&
        oldWidget.active &&
        widget.controller.isFullscreen.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _setFullscreen(false);
      });
    }
  }

  /// 同步浮层与系统栏；播放实例仍留在原来的子树。
  void _setFullscreen(bool fullscreen) {
    widget.controller.isFullscreen.value = fullscreen;
    if (Get.isRegistered<FloatingControlController>()) {
      Get.find<FloatingControlController>().mediaFullscreen.value = fullscreen;
    }
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      ),
    );
  }

  /// 点击标签后驱动 PageView，切换过程暂停所有来源。
  void _select(int index) {
    if (!_pages.hasClients) return;
    widget.controller.selectTab(VideoTab.values[index]);
    unawaited(
      _pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  /// 仅消费外层横向滚动通知，官方流的纵向滑动不影响来源许可。
  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.horizontal) {
      return false;
    }
    if (notification is ScrollStartNotification && !_switching) {
      setState(() => _switching = true);
    } else if (notification is ScrollEndNotification && _switching) {
      setState(() => _switching = false);
    }
    return false;
  }

  /// 退出清理局部导航资源，不持久化本地视频或网址。
  @override
  void dispose() {
    _tabWorker.dispose();
    _pages.dispose();
    _tabs.dispose();
    if (widget.controller.isFullscreen.value) {
      if (Get.isRegistered<FloatingControlController>()) {
        Get.find<FloatingControlController>().mediaFullscreen.value = false;
      }
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    super.dispose();
  }

  /// 共享导航只订阅标签和全屏；各来源内部独立订阅自己的请求状态。
  @override
  Widget build(BuildContext context) {
    final routeVisible = ModalRoute.of(context)?.isCurrent ?? true;
    return Obx(() {
      final selected = widget.controller.selectedTab.value;
      final fullscreen = widget.controller.isFullscreen.value;
      final active = widget.active && routeVisible && !_switching;
      if (active && selected == VideoTab.official) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(widget.controller.ensureOfficialLoaded());
        });
      }
      final bottom = fullscreen
          ? 0.0
          : AppScaffold.contentBottomPaddingOf(
              context,
              showBottomNavigation: true,
            );
      return PopScope(
        canPop: !fullscreen,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && fullscreen) _setFullscreen(false);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: PageView(
                controller: _pages,
                physics: fullscreen
                    ? const NeverScrollableScrollPhysics()
                    : null,
                onPageChanged: (index) =>
                    widget.controller.selectTab(VideoTab.values[index]),
                children: [
                  _KeepAlivePage(
                    child: _OfficialVideos(
                      controller: widget.controller,
                      active: active && selected == VideoTab.official,
                      fullscreen: fullscreen,
                      bottomPadding: bottom,
                      onFullscreen: () => _setFullscreen(!fullscreen),
                    ),
                  ),
                  _KeepAlivePage(
                    child: BrowserVideoEntry(
                      controller: widget.controller,
                      bottomPadding: bottom,
                    ),
                  ),
                  _KeepAlivePage(
                    child: LocalVideoView(
                      controller: widget.controller,
                      active: active && selected == VideoTab.local,
                      fullscreen: fullscreen,
                      bottomPadding: bottom,
                      onFullscreen: () => _setFullscreen(!fullscreen),
                    ),
                  ),
                ],
              ),
            ),
            if (!fullscreen)
              Positioned(
                top: 1.statusBarHeight,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: .45),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: TabBar(
                      controller: _tabs,
                      onTap: _select,
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary
                            .withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [
                        Tab(text: 'Official'),
                        Tab(text: 'Browser'),
                        Tab(text: 'Local'),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

/// 常驻子树只保留页面与播放位置，不赋予隐藏页面播放许可。
final class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});
  final Widget child;

  /// 创建 PageView 保活边界。
  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

final class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  /// 来源切换保留输入和播放器控制器。
  @override
  bool get wantKeepAlive => true;

  /// 保活不改变父级的可见性约束。
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// 官方列表和播放共用当前分页快照。
final class _OfficialVideos extends StatefulWidget {
  const _OfficialVideos({
    required this.controller,
    required this.active,
    required this.fullscreen,
    required this.bottomPadding,
    required this.onFullscreen,
  });
  final VideoController controller;
  final bool active;
  final bool fullscreen;
  final double bottomPadding;
  final VoidCallback onFullscreen;

  /// 创建选片列表与播放器的局部绑定。
  @override
  State<_OfficialVideos> createState() => _OfficialVideosState();
}

final class _OfficialVideosState extends State<_OfficialVideos> {
  var _player = GlobalKey<VideoPlayerSurfaceState>();
  int _revision = -1;

  /// 选片使用已有结果，接近列表末尾时仍由同一个分页接口追加。
  Future<void> _showList() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Obx(
            () => ListView.builder(
              itemCount: widget.controller.officialVideos.length + 1,
              itemBuilder: (context, index) {
                final videos = widget.controller.officialVideos;
                if (index == videos.length) {
                  return Center(
                    child: TextButton(
                      onPressed:
                          widget.controller.hasMore &&
                              !widget.controller.isLoadingMore.value
                          ? widget.controller.loadMore
                          : null,
                      child: Text(
                        widget.controller.isLoadingMore.value
                            ? 'Loading...'
                            : widget.controller.hasMore
                            ? 'Load more'
                            : 'End of videos',
                      ),
                    ),
                  );
                }
                final video = videos[index];
                return ListTile(
                  leading: SizedBox(
                    width: 64,
                    height: 48,
                    child: AppImage.load(
                      video.coverUrl ?? '',
                      fit: BoxFit.contain,
                    ),
                  ),
                  title: Text(
                    video.titleEn ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${video.durationSeconds ?? 0}s'),
                  onTap: () => Navigator.pop(context, index),
                );
              },
            ),
          ),
        ),
      ),
    );
    if (selected != null && mounted) {
      await _player.currentState?.jumpToIndex(selected);
    }
  }

  /// 首屏与分页错误分开呈现，不能因后续请求失败移除正在播放的视频。
  @override
  Widget build(BuildContext context) => Obx(() {
    final videos = widget.controller.officialVideos.toList(growable: false);
    final loading = widget.controller.isLoading.value;
    final failure = widget.controller.failure.value;
    final revision = widget.controller.feedRevision.value;
    if (_revision != revision) {
      _revision = revision;
      _player = GlobalKey<VideoPlayerSurfaceState>();
    }
    if (videos.isEmpty) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      failure == null
                          ? 'No official videos yet'
                          : 'Unable to load videos.',
                      textAlign: TextAlign.center,
                    ),
                    IconButton(
                      tooltip: 'Refresh videos',
                      onPressed: widget.controller.loadOfficialVideos,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        KeyedSubtree(
          key: ValueKey(revision),
          child: VideoPlayerSurface(
            key: _player,
            items: videos.map((video) => video.media).toList(growable: false),
            feedId: 'cyberskin-official-$revision',
            active: widget.active,
            fullscreen: widget.fullscreen,
            bottomPadding: widget.bottomPadding,
            onFullscreen: widget.onFullscreen,
            onShowList: _showList,
            onIndexChanged: (index) {
              if (index >= videos.length - 3 &&
                  widget.controller.loadMoreFailure.value == null) {
                unawaited(widget.controller.loadMore());
              }
            },
          ),
        ),
        if (!widget.fullscreen)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 72,
            right: 16,
            child: Obx(
              () => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.controller.isLoadingMore.value || loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (widget.controller.loadMoreFailure.value != null)
                    IconButton(
                      tooltip: 'Retry loading more videos',
                      onPressed: widget.controller.loadMore,
                      icon: const Icon(Icons.cloud_off_outlined),
                    ),
                  IconButton(
                    tooltip: 'Refresh videos',
                    onPressed: loading
                        ? null
                        : widget.controller.loadOfficialVideos,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  });
}
