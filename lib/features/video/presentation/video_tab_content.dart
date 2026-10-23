// 液态玻璃来源导航与横向 PageView，组合官方信息流、网页入口和本地播放三个常驻子页。
import 'dart:async';

import 'package:cyberskin_app/core/extensions/ui_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:get/get.dart';

import '../../../app/floating_control_controller.dart';
import '../../../app/widgets/app_scaffold.dart';
import '../../../core/theme/app_video_style.dart';
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

final class _VideoTabContentState extends State<VideoTabContent> {
  late final PageController _pages;
  bool _switching = false;

  /// PageView 使用来源状态的初始索引，标签直接消费同一个状态。
  @override
  void initState() {
    super.initState();
    final initial = widget.controller.selectedTab.value.index;
    _pages = PageController(initialPage: initial);
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
    _pages.dispose();
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
                top: 0.statusBarHeight,
                left: 0,
                right: 0,
                child: _VideoSourceTabBar(
                  selectedIndex: selected.index,
                  onSelected: _select,
                ),
              ),
          ],
        ),
      );
    });
  }
}

/// 顶部导航使用完整窗口的安全区；玻璃背景实际采样其后的页面内容。
final class _VideoSourceTabBar extends StatelessWidget {
  const _VideoSourceTabBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final textStyle = AppVideoStyle.tabLabel.copyWith(
      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
    );
    final height = AppVideoStyle.tabBarHeightFor(
      MediaQuery.textScalerOf(context),
    );
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        // 壳层会清除局部顶部 inset；外层已通过全局 statusBarHeight 避让。
        // 此处仅处理左右安全区，避免再次叠加顶部距离。
        padding: AppVideoStyle.tabBarMargin,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppVideoStyle.tabBarMaxWidth,
            ),
            child: LGContainer(
              useOwnLayer: true,
              settings: AppVideoStyle.tabBarGlass,
              shape: const LiquidRoundedRectangle(
                borderRadius: AppVideoStyle.tabBarRadius,
              ),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppVideoStyle.tabBarBackground,
                  borderRadius: BorderRadius.all(
                    Radius.circular(AppVideoStyle.tabBarRadius),
                  ),
                ),
                child: SizedBox(
                  key: const ValueKey('video-source-tab-bar'),
                  height: height,
                  child: Padding(
                    padding: AppVideoStyle.tabIndicatorPadding,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width =
                            (constraints.maxWidth - AppVideoStyle.tabGap * 2) /
                            VideoTab.values.length;
                        const labels = ['Official', 'Browser', 'Local'];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            IgnorePointer(
                              child: AnimatedAlign(
                                alignment: Alignment(-1.0 + selectedIndex, 0),
                                duration:
                                    MediaQuery.disableAnimationsOf(context)
                                    ? Duration.zero
                                    : const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                child: SizedBox(
                                  key: const ValueKey('video-source-indicator'),
                                  width: width,
                                  height: constraints.maxHeight,
                                  child: _VideoSourceIndicator(
                                    height: constraints.maxHeight,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                for (
                                  var index = 0;
                                  index < labels.length;
                                  index++
                                ) ...[
                                  if (index > 0)
                                    const SizedBox(width: AppVideoStyle.tabGap),
                                  Expanded(
                                    child: _VideoSourceButton(
                                      label: labels[index],
                                      selected: selectedIndex == index,
                                      textStyle: textStyle,
                                      height: constraints.maxHeight,
                                      onSelected: () => onSelected(index),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// SVG 填充与玻璃轮廓分层绘制；不把颜色交给玻璃 tint 的乘色混合。
final class _VideoSourceIndicator extends StatelessWidget {
  const _VideoSourceIndicator({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => LGContainer(
    useOwnLayer: true,
    quality: LGQuality.premium,
    settings: AppVideoStyle.tabIndicatorGlass,
    shape: LiquidRoundedRectangle(borderRadius: height / 2),
    child: const CustomPaint(
      painter: _VideoSourceCapsulePainter(),
      child: SizedBox.expand(),
    ),
  );
}

/// 光学轮廓限制在内缘，既保留 SVG 渐变，也避免粗描边遮住背景。
final class _VideoSourceCapsulePainter extends CustomPainter {
  const _VideoSourceCapsulePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      bounds,
      Radius.circular(size.height / 2),
    );
    canvas.drawRRect(
      shape,
      Paint()..shader = AppVideoStyle.tabIndicatorGradient.createShader(bounds),
    );
    canvas.drawDRRect(
      shape,
      shape.deflate(AppVideoStyle.tabIndicatorRimWidth),
      Paint()..shader = AppVideoStyle.tabIndicatorRim.createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(covariant _VideoSourceCapsulePainter oldDelegate) => false;
}

/// 固定按钮区负责点击、键盘与语义；装饰胶囊独立移动，不改变命中位置。
final class _VideoSourceButton extends StatelessWidget {
  const _VideoSourceButton({
    required this.label,
    required this.selected,
    required this.textStyle,
    required this.height,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final TextStyle textStyle;
  final double height;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    },
    actions: {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (_) {
          onSelected();
          return null;
        },
      ),
    },
    child: Semantics(
      selected: selected,
      child: LGButton.custom(
        label: label,
        width: double.infinity,
        height: height,
        onTap: onSelected,
        style: LGButtonStyle.transparent,
        interactionScale: 1,
        stretch: 0,
        child: ExcludeSemantics(
          child: Padding(
            padding: AppVideoStyle.tabLabelPadding,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textStyle.copyWith(
                color: selected
                    ? textStyle.color
                    : AppVideoStyle.tabUnselectedLabelColor,
              ),
            ),
          ),
        ),
      ),
    ),
  );
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
            top:
                0.statusBarHeight +
                AppVideoStyle.tabBarMargin.top +
                AppVideoStyle.tabBarHeightFor(
                  MediaQuery.textScalerOf(context),
                ) +
                12,
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
