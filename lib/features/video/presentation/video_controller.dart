// 视频页标签、官方内容和浏览器输入状态编排。
import 'dart:async';

import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../domain/entities/official_video.dart';
import '../domain/repositories/video_repository.dart';

/// 视频页的三个内容标签。
enum VideoTab {
  /// 后台官方视频。
  official,

  /// 外部浏览器/播放器链接。
  browser,

  /// 本地视频选择。
  local,
}

/// 视频页状态控制器；不持有播放器实例或平台文件句柄。
final class VideoController extends GetxController {
  /// 创建视频控制器。
  VideoController(this._repository);

  final VideoRepository? _repository;

  /// 当前选中的视频来源标签。
  final Rx<VideoTab> selectedTab = VideoTab.official.obs;

  /// 官方视频结果；播放器接入后仍由页面消费该领域模型。
  final RxList<OfficialVideo> officialVideos = <OfficialVideo>[].obs;

  /// 官方视频加载状态。
  final RxBool isLoading = false.obs;

  /// 官方视频加载失败。
  final Rxn<AppFailure> failure = Rxn<AppFailure>();

  /// Browser 输入框当前值。
  final RxString browserUrl = ''.obs;

  @override
  void onReady() {
    super.onReady();
    // 没有构建地址时保留设计兜底背景，避免测试和离线壳层等待网络超时。
    if (const String.fromEnvironment('CYBERSKIN_API_BASE_URL').isNotEmpty) {
      unawaited(loadOfficialVideos());
    }
  }

  /// 切换来源标签。
  void selectTab(VideoTab tab) => selectedTab.value = tab;

  /// 保存 Browser 输入值；实际播放器由后续平台能力接入。
  void setBrowserUrl(String value) => browserUrl.value = value;

  /// 读取官方视频列表。
  Future<void> loadOfficialVideos() async {
    if (_repository == null || isLoading.value) return;
    isLoading.value = true;
    failure.value = null;
    final result = await _repository.listOfficialVideos();
    final page = result.valueOrNull;
    if (page != null) {
      officialVideos.assignAll(page.rows);
    } else {
      failure.value = result.failureOrNull;
    }
    isLoading.value = false;
  }
}
