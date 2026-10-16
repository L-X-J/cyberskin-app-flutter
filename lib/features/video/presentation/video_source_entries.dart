// Browser 输入和 Local 选择/播放子页；与共享标签导航解耦。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../core/widgets/app_liquid_glass_button.dart';
import '../domain/repositories/local_video_repository.dart';
import 'video_controller.dart';
import 'video_player_surface.dart';

/// Browser 是打开 App 内网页容器的入口，不推断或抓取直链视频。
final class BrowserVideoEntry extends StatefulWidget {
  /// 创建常驻的网页输入子页。
  const BrowserVideoEntry({super.key, required this.controller, required this.bottomPadding});
  /// 保存来源输入的状态所有者。
  final VideoController controller;
  /// 一级导航与设备浮层的底部占位。
  final double bottomPadding;

  /// 创建独立输入状态，避免 Rx 更新重置光标。
  @override
  State<BrowserVideoEntry> createState() => _BrowserVideoEntryState();
}

final class _BrowserVideoEntryState extends State<BrowserVideoEntry> {
  late final _text = TextEditingController(
    text: widget.controller.browserUrl.value,
  );
  String? _error;

  /// 校验导航地址并打开独立 WebView，不携带 App 会话头或媒体凭据。
  void _open() {
    var value = _text.text.trim();
    if (!value.contains('://')) value = 'https://$value';
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      setState(() => _error = 'Enter a valid website address.');
      return;
    }
    setState(() => _error = null);
    FocusScope.of(context).unfocus();
    unawaited(Get.toNamed<void>(AppRoutes.videoBrowser, arguments: uri));
  }

  /// 输入状态随视频会话释放，不写本地存储。
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// 键盘出现时内容可滚动，避免输入框与 Privacy 区域互相遮挡。
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFF121219),
    child: SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(24, 130, 24, widget.bottomPadding + 24),
        children: [
          const SizedBox(height: 32),
          const Text(
            'Please enter the link',
            style: TextStyle(fontSize: 21),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _text,
            onChanged: widget.controller.setBrowserUrl,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.go,
            onSubmitted: (_) => _open(),
            decoration: InputDecoration(
              hintText: 'https://',
              errorText: _error,
              suffixIcon: IconButton(
                tooltip: 'Open website',
                onPressed: _open,
                icon: const Icon(Icons.arrow_forward),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 64),
          const _PrivacyNotice(),
        ],
      ),
    ),
  );
}

/// Local 来源只访问系统授权文件，不上传、不构造设备联动。
final class LocalVideoView extends StatelessWidget {
  /// 创建本地选择与播放子页。
  const LocalVideoView({
    super.key,
    required this.controller,
    required this.active,
    required this.fullscreen,
    required this.bottomPadding,
    required this.onFullscreen,
  });
  /// 本地选择与错误状态。
  final VideoController controller;
  /// 来源、路由和一级导航合并后的播放许可。
  final bool active;
  /// 当前全屏布局状态。
  final bool fullscreen;
  /// 底部导航占位。
  final double bottomPadding;
  /// 请求切换全屏，不重置媒体。
  final VoidCallback onFullscreen;

  /// 通过系统入口选择相册或文件；弹层遮挡期间播放器自动停播。
  Future<void> _choose(BuildContext context) async {
    final source = await showModalBottomSheet<LocalVideoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo library'),
              onTap: () => Navigator.pop(context, LocalVideoSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Files'),
              onTap: () => Navigator.pop(context, LocalVideoSource.files),
            ),
          ],
        ),
      ),
    );
    if (source != null) await controller.chooseLocalVideo(source);
  }

  /// 选择状态不影响官方列表或 Browser 输入。
  @override
  Widget build(BuildContext context) => Obx(() {
    final media = controller.localVideo.value;
    final choosing = controller.isChoosing.value;
    final failure = controller.localFailure.value;
    if (media != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayerSurface(
            key: ValueKey(media.videoUrl),
            items: [media],
            feedId: 'cyberskin-local',
            active: active && !choosing,
            fullscreen: fullscreen,
            onFullscreen: onFullscreen,
            scrollable: false,
            bottomPadding: bottomPadding,
            onChoose: () => _choose(context),
          ),
          if (failure != null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 80,
              left: 24,
              right: 24,
              child: Text(failure.message, textAlign: TextAlign.center),
            ),
        ],
      );
    }
    return ColoredBox(
      color: const Color(0xFF121219),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(24, 160, 24, bottomPadding + 24),
          children: [
            const Icon(
              Icons.video_file_outlined,
              size: 58,
              color: Colors.white70,
            ),
            const SizedBox(height: 18),
            const Text(
              'Select local video',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Center(
              child: AppLiquidGlassButton(
                variant: AppLiquidGlassButtonVariant.translucent,
                onPressed: choosing ? null : () => _choose(context),
                leadingIcon: Icons.video_file_outlined,
                label: choosing ? 'Opening...' : 'Choose video',
              ),
            ),
            if (failure != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(failure.message, textAlign: TextAlign.center),
              ),
            const SizedBox(height: 64),
            const _PrivacyNotice(),
          ],
        ),
      ),
    );
  });
}

/// 隐私承诺只描述本地行为，不承诺第三方网站不保存访问记录。
final class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  /// 自适应行高，不以固定高度裁切大字体。
  @override
  Widget build(BuildContext context) => const Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(Icons.shield_outlined, size: 28),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy first',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'Local videos stay on your device. Browsing history is not saved by this app.',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    ],
  );
}
