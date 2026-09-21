// 视频标签页入口占位页面。
import 'package:flutter/material.dart';

import '../../../app/widgets/app_scaffold.dart';

/// 视频标签页入口页面。
final class VideoPage extends StatelessWidget {
  /// 创建视频页面。
  const VideoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.video,
      appBar: AppBar(title: const Text('Video')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Video experiences',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                'Official, browser, and local video sources will be configured here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
