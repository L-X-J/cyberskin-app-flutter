// 应用初始化页的状态与启动配置刷新编排。
import 'dart:async';

import 'package:get/get.dart';

import '../../../app/app_routes.dart';
import '../../../app/session_controller.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/result/result.dart';
import '../../../features/content/domain/entities/app_content.dart';
import '../../../features/content/domain/repositories/content_repository.dart';
import '../../../features/device/domain/device.dart';

/// 初始化阶段展示状态。
enum InitStatus {
  /// 正在读取缓存或等待当天首次配置请求。
  loading,

  /// 已完成前置条件，可以进入主应用。
  ready,

  /// 没有可用缓存且首次请求失败，当前无法安全进入主应用。
  failed,
}

/// 负责启动配置缓存、每日刷新策略和首屏跳转的 GetX 控制器。
final class InitController extends GetxController {
  /// 创建初始化控制器。
  InitController(
    this._contentRepository, {
    this.navigateToNextPage,
    SessionController? sessionController,
  }) : _sessionController = sessionController;

  final ContentRepository _contentRepository;

  final SessionController? _sessionController;

  /// 可替换的进入下一页回调；生产环境为空时使用 GetX 注册路由。
  final Future<void> Function()? navigateToNextPage;

  /// 当前初始化阶段状态。
  final Rx<InitStatus> status = InitStatus.loading.obs;

  /// 当前启动配置；有缓存时可在后台刷新期间立即提供给后续页面。
  final Rxn<AppConfiguration> configuration = Rxn<AppConfiguration>();

  /// 阻塞首次启动失败时的可展示错误。
  final Rxn<AppFailure> failure = Rxn<AppFailure>();

  bool _started = false;

  /// 页面挂载完成后自动启动初始化流程。
  ///
  /// 使用 `unawaited` 是为了让页面先完成首帧渲染，再由响应式状态展示加载或失败，
  /// 避免在 `build` 阶段同步执行 IO。
  @override
  void onReady() {
    super.onReady();
    unawaited(start());
  }

  /// 执行初始化策略；重复调用只会启动一次。
  ///
  /// 当天首次打开时前台等待远端成功；同一天非首次打开时先让后续页面可用，再在后台
  /// 刷新。任何失败都不会销毁已有缓存。
  Future<void> start() async {
    // 重复挂载或用户快速重试时只允许一个初始化流程在运行。
    if (_started) {
      return;
    }
    _started = true;
    await _loadAndRefresh();
  }

  /// 在失败页面重试一次完整初始化流程。
  Future<void> retry() async {
    // 只有阻塞失败状态允许重试，防止用户重复点击产生并发请求。
    if (status.value != InitStatus.failed) {
      return;
    }
    _started = false;
    await start();
  }

  /// 读取本地状态、执行首次/非首次刷新策略，并决定是否允许进入下一页。
  ///
  /// 该方法是启动语义的核心：必须在写入本次启动日期后立即发出请求，确保
  /// 无论前台等待还是后台刷新，成功响应最终都会经过 Repository 写入磁盘缓存。
  Future<void> _loadAndRefresh() async {
    // 每次重新进入流程都先恢复加载态并清掉上一轮的可展示错误。
    status.value = InitStatus.loading;
    failure.value = null;

    // 先读取磁盘缓存，使已有配置在后台刷新期间仍可立即被后续页面使用。
    final cached = await _contentRepository.readCachedConfiguration();
    configuration.value = cached;
    _syncSession(cached);
    final now = DateTime.now();
    // 启动日期必须先于请求持久化，避免系统杀进程后把同一天再次误判为首次启动。
    final lastLaunchAt = await _contentRepository.readLastLaunchAt();
    final firstLaunchToday = !_isSameLocalDay(lastLaunchAt, now);
    await _contentRepository.writeLastLaunchAt(now);

    // 请求一经发出，Repository 在成功时会负责覆盖配置缓存和刷新时间。
    final refreshFuture = _contentRepository.refreshConfiguration();
    // 非首次启动且已有缓存时立即放行页面，请求结果只更新状态，不阻塞用户。
    if (!firstLaunchToday && cached != null) {
      await _openNextPage();
      unawaited(_applyRefreshResult(refreshFuture));
      return;
    }

    // 当天首次启动或无缓存时必须等待远端结果，确保下一页拿到可用配置。
    final result = await refreshFuture;
    if (result case Success<AppConfiguration>(:final value)) {
      configuration.value = value;
      _syncSession(value);
      await _openNextPage();
      return;
    }
    // 首次请求失败且无缓存时留在初始化页，由用户主动重试。
    failure.value = result.failureOrNull;
    status.value = InitStatus.failed;
  }

  /// 应用后台刷新结果；失败只记录状态，不撤销已经可用的缓存。
  Future<void> _applyRefreshResult(
    Future<Result<AppConfiguration>> refreshFuture,
  ) async {
    // 在等待响应前捕获会话状态：后台刷新发起时若用户尚未登录，
    // 则响应返回 loggedIn=false 属于正常的匿名状态，不应触发跳转。
    // 只有刷新发起时已经登录、且响应表明服务端已失效，才需要踢回登录页。
    final wasAuthenticatedWhenStarted =
        _session?.state.value == SessionState.authenticated;
    final result = await refreshFuture;
    if (result case Success<AppConfiguration>(:final value)) {
      configuration.value = value;
      _syncSession(value);
      if (wasAuthenticatedWhenStarted && value.loggedIn == false) {
        await Get.offAllNamed<void>(AppRoutes.login);
      }
      return;
    }
    failure.value = result.failureOrNull;
  }

  /// 将初始化状态切换为完成，并跳转到主应用首页。
  ///
  /// 自定义回调用于隔离单元测试；生产环境通过 GetX 的命名路由替换整个初始化栈。
  Future<void> _openNextPage() async {
    status.value = InitStatus.ready;
    final navigate = navigateToNextPage;
    if (navigate != null) {
      await navigate();
      return;
    }
    final session = _session?.state.value ?? SessionState.starting;
    final route = switch (session) {
      SessionState.authenticated => AppRoutes.home,
      SessionState.anonymous =>
        _deviceStatus == DeviceConnectionStatus.connected
            ? AppRoutes.login
            : AppRoutes.home,
      SessionState.starting => AppRoutes.home,
    };
    await Get.offAllNamed<void>(route);
  }

  SessionController? get _session =>
      _sessionController ??
      (Get.isRegistered<SessionController>()
          ? Get.find<SessionController>()
          : null);

  DeviceConnectionStatus get _deviceStatus =>
      _session?.deviceStatus.value ?? DeviceConnectionStatus.disconnected;

  void _syncSession(AppConfiguration? value) {
    if (value != null) {
      _session?.setConfiguration(value);
    }
  }

  bool _isSameLocalDay(DateTime? value, DateTime now) {
    // 缓存中的时间统一按 UTC 保存，比较前必须转成本地时区，否则跨时区会误判首次启动。
    if (value == null) {
      return false;
    }
    final local = value.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }
}
