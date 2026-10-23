// 首页真实广告轮播；用户拖动、后台、路由覆盖及减少动态效果时暂停自动切换。
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_route_visibility.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../content/domain/entities/app_content.dart';
import '../widgets/home_advertisement_helper.dart';

/// 首页广告横滑分页与五秒自动轮播，生命周期由当前页面约束。
final class HomeAdvertisementCard extends StatefulWidget {
  /// 创建当前组件的实例。
  const HomeAdvertisementCard({
    super.key,
    this.fadeAnimation = const AlwaysStoppedAnimation<double>(1.0),
    this.advertisements = const [],
    this.active = true,
    this.onAdvertisement,
  });

  /// 父级首次入场淡入进度。
  final Animation<double> fadeAnimation;

  /// 当前有效的广告摘要，顺序由服务端确定。
  final List<AppAdvertisement> advertisements;

  /// 首页内容标签当前是否可见。
  final bool active;

  /// 由控制器执行广告约定跳转。
  final ValueChanged<AppAdvertisement>? onAdvertisement;

  @override
  State<HomeAdvertisementCard> createState() => _HomeAdvertisementCardState();
}

final class _HomeAdvertisementCardState extends State<HomeAdvertisementCard>
    with WidgetsBindingObserver, RouteAware {
  final _pages = PageController();
  Timer? _timer;
  StreamSubscription<List<AppAdvertisement>>? _cacheSubscription;
  List<AppAdvertisement> _displayAdvertisements = const [];
  int _index = 0;
  bool _visible = true, _dragging = false, _resumed = true, _reduced = false;
  PageRoute<dynamic>? _route;
  RouteObserver<PageRoute<dynamic>>? _observer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _resumed =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _syncAdvertisements();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final observer = AppRouteVisibility.of(context);
    if (route is PageRoute<dynamic> &&
        (route != _route || observer != _observer)) {
      _observer?.unsubscribe(this);
      _route = route;
      _observer = observer;
      _observer?.subscribe(this, route);
      _visible = route.isCurrent;
    }
    _reduced = MediaQuery.disableAnimationsOf(context);
    _schedule();
  }

  @override
  void didUpdateWidget(HomeAdvertisementCard old) {
    super.didUpdateWidget(old);
    if (widget.advertisements != old.advertisements) {
      _syncAdvertisements();
    } else {
      _schedule();
    }
  }

  void _syncAdvertisements() {
    _cacheSubscription?.cancel();
    _cacheSubscription =
        AppAdvertisementHelper.syncCachedAdvertisements(widget.advertisements)
            .listen((cachedList) {
              if (!mounted) return;
              setState(() {
                _displayAdvertisements = cachedList;
                if (_index >= _displayAdvertisements.length) {
                  _index = 0;
                  if (_pages.hasClients) {
                    _pages.jumpToPage(0);
                  }
                }
              });
              _schedule();
            });
  }

  @override
  void didPush() {
    _visible = true;
    _schedule();
  }

  @override
  void didPopNext() {
    _visible = true;
    _schedule();
  }

  @override
  void didPushNext() {
    _visible = false;
    _schedule();
  }

  @override
  void didPop() {
    _visible = false;
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!mounted ||
        !_visible ||
        !_resumed ||
        _dragging ||
        _reduced ||
        !widget.active ||
        _displayAdvertisements.length < 2) {
      return;
    }
    _timer = Timer(const Duration(seconds: 5), () async {
      if (!mounted || !_pages.hasClients) return;
      await _pages.animateToPage(
        (_index + 1) % _displayAdvertisements.length,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
      );
      if (mounted) _schedule();
    });
  }

  @override
  void dispose() {
    _cacheSubscription?.cancel();
    _timer?.cancel();
    _observer?.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayAdvertisements.isEmpty) return const SizedBox.shrink();
    return FadeTransition(
      opacity: widget.fadeAnimation,
      child: Column(
        children: [
          SizedBox(
            height: 124,
            child: NotificationListener<ScrollNotification>(
              onNotification: (event) {
                if (event is ScrollStartNotification &&
                    event.dragDetails != null) {
                  _dragging = true;
                  _schedule();
                }
                if (event is ScrollEndNotification) {
                  _dragging = false;
                  _schedule();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pages,
                itemCount: _displayAdvertisements.length,
                onPageChanged: (page) {
                  setState(() => _index = page);
                },
                itemBuilder: (context, index) {
                  final ad = _displayAdvertisements[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Material(
                        color: const Color(0xFF292535),
                        child: InkWell(
                          onTap: () => widget.onAdvertisement?.call(ad),
                          child: AppImage.load(
                            ad.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorWidget: const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_displayAdvertisements.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _displayAdvertisements.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Container(
                        width: i == _index ? 14 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: i == _index ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
