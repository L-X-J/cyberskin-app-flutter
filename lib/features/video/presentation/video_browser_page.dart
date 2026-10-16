// 独立 App 内网页容器：保留网站自身播放器，不提取视频链接或暴露 App 会话。
import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import '../../../app/floating_control_controller.dart';

/// 仅接受经过入口验证的 HTTP(S) Uri 的内置网页页。
final class VideoBrowserPage extends StatefulWidget {
  /// 创建网页路由，参数由命名路由传入。
  const VideoBrowserPage({super.key});

  /// 创建短生命周期 WebView 宿主。
  @override
  State<VideoBrowserPage> createState() => _VideoBrowserPageState();
}

final class _VideoBrowserPageState extends State<VideoBrowserPage>
    with WidgetsBindingObserver {
  InAppWebViewController? _web;
  Uri? _initialUrl;
  String _host = '';
  bool _fullscreen = false;
  bool _failed = false;
  bool _foreground = true;
  int _progress = 0;
  int _lifecycleRevision = 0;
  bool _leaving = false;

  /// 二次校验路由参数，避免其他页面通过任意 scheme 打开本容器。
  @override
  void initState() {
    super.initState();
    final argument = Get.arguments;
    if (argument is Uri && _allowed(argument)) {
      _initialUrl = argument;
      _host = argument.host;
    }
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }

  /// 容器只导航普通网页，拒绝文件、intent 和自定义 App scheme。
  bool _allowed(Uri uri) =>
      ['http', 'https'].contains(uri.scheme) &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;

  /// 独立应用媒体许可，回到前台不调用网页 play，保留用户手势语义。
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    unawaited(_syncMedia());
  }

  /// 使用平台暂停覆盖跨域媒体，脚本补齐普通页面上的显式 pause。
  Future<void> _syncMedia() async {
    final web = _web;
    if (web == null) return;
    final revision = ++_lifecycleRevision;
    try {
      if (Platform.isIOS) {
        await web.setAllMediaPlaybackSuspended(
          suspended: !_foreground || _leaving,
        );
      } else if (Platform.isAndroid) {
        if (_foreground && !_leaving) {
          await web.resume();
        } else {
          await web.pause();
        }
      }
      if (revision != _lifecycleRevision) return;
      if (!_foreground || _leaving) {
        await web.evaluateJavascript(
          source: "document.querySelectorAll('video,audio').forEach(function(m){m.pause();});",
        );
      }
    } catch (_) {
      // 不把含网址的插件错误显示或写入业务日志；关闭时仍会销毁原生 WebView。
    }
  }

  /// 全屏仅改变容器栏位与全局设备浮层，不强制横屏。
  void _setFullscreen(bool value) {
    if (!mounted) return;
    setState(() => _fullscreen = value);
    if (Get.isRegistered<FloatingControlController>()) {
      Get.find<FloatingControlController>().mediaFullscreen.value = value;
    }
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        value ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      ),
    );
  }

  /// 返回优先退出视频全屏，再处理网页历史，最后才离开 App 内容器。
  Future<void> _back() async {
    final web = _web;
    if (_fullscreen && web != null) {
      try {
        if (Platform.isIOS) await web.closeAllMediaPresentations();
        await web.evaluateJavascript(
          source: "if(document.fullscreenElement){document.exitFullscreen();}document.querySelectorAll('video').forEach(function(v){if(v.webkitExitFullscreen){v.webkitExitFullscreen();}});",
        );
      } catch (_) {}
      if (mounted) _setFullscreen(false);
      return;
    }
    if (web != null && await web.canGoBack()) {
      await web.goBack();
      return;
    }
    await _close();
  }

  /// 关闭前停播并卸载网页，防止路由退场动画期间声音残留。
  Future<void> _close() async {
    if (_leaving) return;
    _leaving = true;
    await _syncMedia();
    try {
      await _web?.stopLoading();
    } catch (_) {}
    if (mounted) Get.back<void>();
  }

  /// 主页面加载失败时保留原网址供重试；子资源失败不覆盖整个网页。
  void _fail() {
    if (mounted) setState(() => _failed = true);
  }

  /// 销毁容器不保存历史、网址或账号信息。
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleRevision++;
    _web = null;
    if (_fullscreen && Get.isRegistered<FloatingControlController>()) {
      Get.find<FloatingControlController>().mediaFullscreen.value = false;
    }
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    super.dispose();
  }

  /// 原生 WebView 承载网页媒体；不向页面注册可访问业务的 JavaScript handler。
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_back());
    },
    child: Scaffold(
      backgroundColor: Colors.black,
      appBar: _fullscreen
          ? null
          : AppBar(
              leading: IconButton(
                tooltip: 'Back',
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text(_host, maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  tooltip: 'Reload',
                  onPressed: () => _web?.reload(),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Close browser',
                  onPressed: _close,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
      body: SafeArea(
        top: !_fullscreen,
        bottom: !_fullscreen,
        child: Stack(
          children: [
            if (_initialUrl != null)
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri.uri(_initialUrl!)),
                initialSettings: InAppWebViewSettings(
                  incognito: true,
                  cacheEnabled: false,
                  javaScriptEnabled: true,
                  allowsInlineMediaPlayback: true,
                  allowsPictureInPictureMediaPlayback: false,
                  mediaPlaybackRequiresUserGesture: true,
                  useShouldOverrideUrlLoading: true,
                  isInspectable: false,
                  javaScriptCanOpenWindowsAutomatically: false,
                ),
                initialUserScripts: UnmodifiableListView([
                  UserScript(
                    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
                    forMainFrameOnly: false,
                    source: "document.addEventListener('visibilitychange',function(){if(document.hidden){document.querySelectorAll('video,audio').forEach(function(m){m.pause();});}});",
                  ),
                ]),
                onWebViewCreated: (controller) {
                  _web = controller;
                  unawaited(_syncMedia());
                },
                shouldOverrideUrlLoading: (controller, action) async {
                  final url = action.request.url;
                  return url != null && _allowed(url.uriValue)
                      ? NavigationActionPolicy.ALLOW
                      : NavigationActionPolicy.CANCEL;
                },
                onLoadStart: (_, url) {
                  if (mounted) {
                    setState(() {
                      _failed = false;
                      _host = url?.host ?? _host;
                    });
                  }
                },
                onLoadStop: (_, _) => _syncMedia(),
                onProgressChanged: (_, progress) {
                  if (mounted) setState(() => _progress = progress);
                },
                onReceivedError: (_, request, _) {
                  if (request.isForMainFrame == true) _fail();
                },
                onReceivedHttpError: (_, request, response) {
                  if (request.isForMainFrame == true &&
                      (response.statusCode ?? 0) >= 400) {
                    _fail();
                  }
                },
                onPermissionRequest: (_, _) async =>
                    PermissionResponse(action: PermissionResponseAction.DENY),
                onEnterFullscreen: (_) => _setFullscreen(true),
                onExitFullscreen: (_) => _setFullscreen(false),
              ),
            if (_progress < 100 && !_failed)
              LinearProgressIndicator(value: _progress / 100),
            if (_failed || _initialUrl == null)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to load this website.'),
                        IconButton(
                          tooltip: 'Retry website',
                          icon: const Icon(Icons.refresh),
                          onPressed: _initialUrl == null
                              ? null
                              : () => _web?.reload(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
