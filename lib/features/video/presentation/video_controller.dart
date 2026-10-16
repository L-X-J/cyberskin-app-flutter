// 视频页来源、分页和本地选择编排；不持有原生播放器或文件句柄。
import 'package:get/get.dart';

import '../../../core/error/app_failure.dart';
import '../domain/entities/official_video.dart';
import '../domain/entities/video_media.dart';
import '../domain/repositories/local_video_repository.dart';
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
  VideoController(this._repository, {LocalVideoRepository? localRepository})
    : _localRepository = localRepository;

  final VideoRepository? _repository;
  final LocalVideoRepository? _localRepository;
  static const int _pageSize = 20;
  int _generation = 0;
  int _nextPage = 1;
  int _total = 0;
  bool _loaded = false;

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

  /// 加载后续分页状态。
  final isLoadingMore = false.obs;

  /// 分页请求失败；不覆盖已有列表。
  final loadMoreFailure = Rxn<AppFailure>();

  /// 本地选择结果，仅保留在当前会话。
  final localVideo = Rxn<VideoMedia>();

  /// 系统选择器忙状态。
  final isChoosing = false.obs;

  /// 本地选择失败；取消不构成失败。
  final localFailure = Rxn<AppFailure>();

  /// 全屏只是布局状态，不替换播放器实例。
  final isFullscreen = false.obs;

  /// 刷新后递增，通知播放器回到新的首条内容。
  final feedRevision = 0.obs;

  /// 是否还有服务端未加载的数据。
  bool get hasMore => officialVideos.length < _total;

  /// 只有来源实际可见时才请求官方首屏，避免隐藏首页提前加载视频。
  Future<void> ensureOfficialLoaded() async {
    if (!_loaded &&
        !isLoading.value &&
        failure.value == null &&
        const String.fromEnvironment('CYBERSKIN_API_BASE_URL').isNotEmpty) {
      await loadOfficialVideos();
    }
  }

  /// 切换来源标签。
  void selectTab(VideoTab tab) => selectedTab.value = tab;

  /// 保存网址输入，不做媒体抓取。
  void setBrowserUrl(String value) => browserUrl.value = value;

  /// 刷新开始新代次，忽略旧分页或旧刷新的迟到响应。
  Future<void> loadOfficialVideos() async {
    final repository = _repository;
    if (repository == null) return;
    final generation = ++_generation;
    isLoading.value = true;
    isLoadingMore.value = false;
    failure.value = null;
    loadMoreFailure.value = null;
    final result = await repository.listOfficialVideos(pageSize: _pageSize);
    if (isClosed || generation != _generation) return;
    final page = result.valueOrNull;
    if (page != null) {
      officialVideos.assignAll(page.rows);
      _total = page.total ?? page.rows.length;
      _nextPage = 2;
      _loaded = true;
      feedRevision.value++;
    } else {
      failure.value = result.failureOrNull;
    }
    isLoading.value = false;
  }

  /// 接近末尾后按需追加；失败不推进页码，重试仍请求同一页。
  Future<void> loadMore() async {
    final repository = _repository;
    if (repository == null ||
        isLoading.value ||
        isLoadingMore.value ||
        !hasMore) {
      return;
    }
    final generation = _generation;
    isLoadingMore.value = true;
    loadMoreFailure.value = null;
    final result = await repository.listOfficialVideos(
      pageNumber: _nextPage,
      pageSize: _pageSize,
    );
    if (isClosed || generation != _generation) return;
    final page = result.valueOrNull;
    if (page != null) {
      final ids = officialVideos.map((video) => video.id).toSet();
      officialVideos.addAll(page.rows.where((video) => ids.add(video.id)));
      _total = page.rows.isEmpty
          ? officialVideos.length
          : page.total ?? officialVideos.length;
      _nextPage++;
    } else {
      loadMoreFailure.value = result.failureOrNull;
    }
    isLoadingMore.value = false;
  }

  /// 调起系统选择器；取消保留原视频，完成后才替换媒体快照。
  Future<void> chooseLocalVideo(LocalVideoSource source) async {
    if (isChoosing.value || _localRepository == null) return;
    isChoosing.value = true;
    localFailure.value = null;
    final result = await _localRepository.choose(source);
    if (isClosed) return;
    if (result.valueOrNull case final VideoMedia media) {
      localVideo.value = media;
    }
    localFailure.value = result.failureOrNull;
    isChoosing.value = false;
  }

  /// 退出时废弃未完成请求，不再更新已销毁的页面状态。
  @override
  void onClose() {
    _generation++;
    super.onClose();
  }
}
