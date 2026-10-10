// 视频标签页：提供 Official、Browser、Local 三种内容来源状态。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/app_liquid_glass_button.dart';
import '../domain/entities/official_video.dart';
import 'video_controller.dart';

/// 视频标签页入口页面。
final class VideoPage extends GetView<VideoController> {
  /// 创建视频页面。
  const VideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.video,
      appBar: const PreferredSize(
        preferredSize: Size.zero,
        child: SizedBox.shrink(),
      ),
      body: VideoTabContent(controller: controller),
    );
  }
}

/// 可嵌入一级壳层的视频内容区域；只订阅视频领域状态，不创建页面路由。
final class VideoTabContent extends StatelessWidget {
  /// 创建视频内容区域。
  const VideoTabContent({super.key, required this.controller});

  /// 当前视频展示状态。
  final VideoController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => switch (controller.selectedTab.value) {
      VideoTab.official => _OfficialVideoView(
        videos: controller.officialVideos.toList(growable: false),
        isLoading: controller.isLoading.value,
        failure: controller.failure.value,
        onRetry: controller.loadOfficialVideos,
        onSelect: controller.selectTab,
      ),
      VideoTab.browser => _BrowserVideoView(
        value: controller.browserUrl.value,
        onChanged: controller.setBrowserUrl,
        onSelect: controller.selectTab,
      ),
      VideoTab.local => _LocalVideoView(onSelect: controller.selectTab),
    },
  );
}

final class _OfficialVideoView extends StatelessWidget {
  const _OfficialVideoView({
    required this.videos,
    required this.isLoading,
    required this.failure,
    required this.onRetry,
    required this.onSelect,
  });

  final List<OfficialVideo> videos;
  final bool isLoading;
  final AppFailure? failure;
  final VoidCallback onRetry;
  final void Function(VideoTab) onSelect;

  @override
  Widget build(BuildContext context) {
    final background = videos.isNotEmpty && videos.first.coverUrl != null
        ? videos.first.coverUrl
        : 'assets/images/video/official_background.png';
    return Stack(
      fit: StackFit.expand,
      children: [
        AppImage.load(background, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.12),
                Colors.black.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              _VideoTabs(selected: VideoTab.official, onSelect: onSelect),
              const Spacer(),
              if (isLoading)
                const CircularProgressIndicator()
              else if (failure != null)
                _VideoError(message: failure!.message, onRetry: onRetry)
              else if (videos.isEmpty)
                const Text(
                  'No official videos yet',
                  style: TextStyle(fontSize: 16),
                )
              else
                const _FrequencyOverlay(),
              SizedBox(
                height: AppScaffold.contentBottomPaddingOf(
                  context,
                  showBottomNavigation: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _BrowserVideoView extends StatefulWidget {
  const _BrowserVideoView({
    required this.value,
    required this.onChanged,
    required this.onSelect,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final void Function(VideoTab) onSelect;

  @override
  State<_BrowserVideoView> createState() => _BrowserVideoViewState();
}

final class _BrowserVideoViewState extends State<_BrowserVideoView> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _BrowserVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _textController.text != widget.value) {
      _textController.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _VideoGradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _VideoTabs(selected: VideoTab.browser, onSelect: widget.onSelect),
            const Spacer(),
            const Text('Please enter the link', style: TextStyle(fontSize: 21)),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: TextField(
                onChanged: widget.onChanged,
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  suffixIcon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ),
            const Spacer(),
            const _PrivacyCard(),
            SizedBox(
              height: AppScaffold.contentBottomPaddingOf(
                context,
                showBottomNavigation: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _LocalVideoView extends StatelessWidget {
  const _LocalVideoView({required this.onSelect});
  final void Function(VideoTab) onSelect;

  @override
  Widget build(BuildContext context) {
    return _VideoGradientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _VideoTabs(selected: VideoTab.local, onSelect: onSelect),
            const Spacer(),
            const Icon(
              Icons.video_file_outlined,
              size: 58,
              color: Colors.white70,
            ),
            const SizedBox(height: 18),
            const Text('Select local video', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            AppLiquidGlassButton(
              variant: AppLiquidGlassButtonVariant.translucent,
              onPressed: () {},
              leadingIcon: Icons.upload_file,
              label: 'Choose video',
            ),
            const Spacer(),
            const _PrivacyCard(),
            SizedBox(
              height: AppScaffold.contentBottomPaddingOf(
                context,
                showBottomNavigation: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _VideoTabs extends StatelessWidget {
  const _VideoTabs({required this.selected, required this.onSelect});
  final VideoTab selected;
  final void Function(VideoTab) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: AppRadius.pill,
        color: Colors.white.withValues(alpha: 0.20),
      ),
      child: Row(
        children: [
          _tab('Official', VideoTab.official),
          _tab('Browser', VideoTab.browser),
          _tab('Local', VideoTab.local),
        ],
      ),
    );
  }

  Widget _tab(String label, VideoTab tab) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(tab),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.pill,
            color: selected == tab
                ? const Color(0xFF9D58A8)
                : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

final class _VideoGradientBackground extends StatelessWidget {
  const _VideoGradientBackground({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.8, 0.2),
          radius: 1.2,
          colors: [Color(0xFF666078), Color(0xFF292774), Color(0xFF060817)],
        ),
      ),
      child: child,
    );
  }
}

final class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy first', style: TextStyle(fontSize: 12)),
                SizedBox(height: 2),
                Text(
                  'We attach great importance to your personal privacy,\nand the content you access will not be recorded',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    height: 1.2,
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

final class _FrequencyOverlay extends StatelessWidget {
  const _FrequencyOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      height: 85,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(12),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequency',
            style: TextStyle(fontSize: 11, color: Colors.white70),
          ),
          SizedBox(height: 10),
          Icon(Icons.show_chart, color: Color(0xFFC99BC8), size: 90),
        ],
      ),
    );
  }
}

final class _VideoError extends StatelessWidget {
  const _VideoError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        AppLiquidGlassButton(
          variant: AppLiquidGlassButtonVariant.translucent,
          onPressed: onRetry,
          label: 'Try again',
        ),
      ],
    );
  }
}
