// 应用级依赖装配：注册全局 Repository、API 客户端和跨页面控制器。
import 'package:get/get.dart';

import '../../core/logging/app_log.dart';
import '../../core/network/api_transport.dart';
import '../../core/network/app_api_client.dart';
import '../../core/network/network_request_monitor.dart';
import '../../core/storage/seen_ad_store.dart';
import '../../core/storage/session_credential_store.dart';
import '../../features/ad/data/ad_remote_repository.dart';
import '../../features/ad/domain/repositories/ad_repository.dart';
import '../../features/auth/data/auth_remote_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/content/data/content_configuration_cache.dart';
import '../../features/content/data/content_remote_repository.dart';
import '../../features/content/domain/repositories/content_repository.dart';
import '../../features/control/data/ble_device_command_repository.dart';
import '../../features/control/data/ble_device_playback_port.dart';
import '../../features/control/data/common_program_file_cache.dart';
import '../../features/control/domain/device_command_repository.dart';
import '../../features/control/domain/services/device_program_playback.dart';
import '../../features/control/presentation/control_session_controller.dart';
import '../../features/device/data/cached_user_device_repository.dart';
import '../../features/device/data/connected_device_repository.dart';
import '../../features/device/data/cyberskin_ble_runtime_coordinator.dart';
import '../../features/device/data/device_api_repositories.dart';
import '../../features/device/data/user_device_cache.dart';
import '../../features/device/domain/device_repository.dart';
import '../../features/device/domain/repositories/device_catalog_repository.dart';
import '../../features/device/domain/repositories/user_device_repository.dart';
import '../../features/feedback/data/feedback_remote_repository.dart';
import '../../features/feedback/domain/repositories/feedback_repository.dart';
import '../../features/home/data/home_remote_repository.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/profile/data/profile_remote_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/rhythm/data/cached_rhythm_repository.dart';
import '../../features/rhythm/data/rhythm_catalog_repository.dart';
import '../../features/rhythm/data/rhythm_local_store.dart';
import '../../features/rhythm/data/rhythm_remote_repository.dart';
import '../../features/rhythm/domain/repositories/rhythm_catalog.dart';
import '../../features/rhythm/domain/repositories/rhythm_repository.dart';
import '../../features/rhythm/domain/services/rhythm_playback.dart';
import '../../features/rhythm/presentation/rhythm_session_controller.dart';
import '../../features/training/data/training_remote_repository.dart';
import '../../features/training/domain/repositories/training_repository.dart';
import '../../features/training/presentation/training_session_controller.dart';
import '../../features/version/data/version_remote_repository.dart';
import '../../features/version/domain/repositories/version_repository.dart';
import '../../features/video/data/local_video_repository_impl.dart';
import '../../features/video/data/video_remote_repository.dart';
import '../../features/video/domain/repositories/local_video_repository.dart';
import '../../features/video/domain/repositories/video_repository.dart';
import '../floating_control_controller.dart';
import '../playback_session_notifier.dart';
import '../session_controller.dart';

/// 注册应用生命周期内共享的 Repository、API 客户端和控制器。
final class AppBinding extends Bindings {
  /// 使用应用入口选择的设备 Repository 创建绑定。
  AppBinding({
    required this.deviceRepository,
    required this.contentConfigurationCache,
    required this.log,
  });

  /// 当前运行环境使用的设备 Repository 具体实现。
  final DeviceRepository? deviceRepository;

  /// 当前运行环境使用的启动配置缓存实现。
  final ContentConfigurationCache contentConfigurationCache;

  /// 应用生命周期内共享的统一日志接口。
  final AppLog log;

  @override
  void dependencies() {
    final client = AppApiClient();
    final sessionStore = SecureSessionCredentialStore();
    final monitor = NetworkRequestMonitor();
    final transport = GetConnectApiTransport(
      client: client,
      credentials: sessionStore,
      monitor: monitor,
      log: log,
    );
    Get.put<AppApiClient>(client, permanent: true);
    Get.put<SessionCredentialStore>(sessionStore, permanent: true);
    Get.put<NetworkRequestMonitor>(monitor, permanent: true);
    Get.put<AppLog>(log, permanent: true);
    Get.put<ApiTransport>(transport, permanent: true);
    Get.put<AuthRepository>(
      AuthRemoteRepository(transport: transport, sessionStore: sessionStore),
      permanent: true,
    );
    Get.put<ProfileRepository>(
      ProfileRemoteRepository(transport: transport, sessionStore: sessionStore),
      permanent: true,
    );
    Get.put<DeviceCatalogRepository>(
      DeviceCatalogRemoteRepository(
        transport: transport,
        sessionStore: sessionStore,
      ),
      permanent: true,
    );
    Get.put<UserDeviceRepository>(
      CachedUserDeviceRepository(
        remote: UserDeviceRemoteRepository(
          transport: transport,
          sessionStore: sessionStore,
        ),
        cache: SharedPreferencesUserDeviceCache(),
      ),
      permanent: true,
    );
    Get.put<CyberskinBleRuntimeCoordinator>(
      CyberskinBleRuntimeCoordinator(
        catalogRepository: Get.find<DeviceCatalogRepository>(),
        userDeviceRepository: Get.find<UserDeviceRepository>(),
      ),
      permanent: true,
    );
    Get.put<DeviceRepository>(
      deviceRepository ??
          ConnectedDeviceRepository(
            userDeviceRepository: Get.find<UserDeviceRepository>(),
            catalogRepository: Get.find<DeviceCatalogRepository>(),
            bleCoordinator: Get.find<CyberskinBleRuntimeCoordinator>(),
          ),
      permanent: true,
    );
    final rhythmStore = RhythmLocalStore(sessionStore);
    final programFiles = Get.put(CommonProgramFileCache(), permanent: true);
    Get.put<RhythmRepository>(
      CachedRhythmRepository(
        RhythmRemoteRepository(
          transport: transport,
          sessionStore: sessionStore,
        ),
        rhythmStore,
        programFiles: programFiles,
      ),
      permanent: true,
    );
    Get.put<RhythmCatalog>(
      RhythmCatalogRepository(
        UserDeviceRemoteRepository(
          transport: transport,
          sessionStore: sessionStore,
        ),
        Get.find<DeviceCatalogRepository>(),
        rhythmStore,
      ),
      permanent: true,
    );
    final playbackPort = BleDevicePlaybackPort(
      Get.find<CyberskinBleRuntimeCoordinator>(),
      BleDeviceCommandRepository(Get.find<CyberskinBleRuntimeCoordinator>()),
      sessionStore,
    );
    final devicePlayback = Get.put(
      DeviceProgramPlayback(playbackPort),
      permanent: true,
    );
    final playback = Get.put(
      RhythmPlayback.fromEngine(devicePlayback),
      permanent: true,
    );
    Get.put(
      RhythmSessionController(
        playback,
        Get.find<RhythmCatalog>(),
        repository: Get.find<RhythmRepository>(),
      ),
      permanent: true,
    );
    Get.put<TrainingRepository>(
      TrainingRemoteRepository(
        transport: transport,
        sessionStore: sessionStore,
        programFiles: programFiles,
      ),
      permanent: true,
    );
    Get.put<TrainingSessionController>(
      TrainingSessionController(
        Get.find<TrainingRepository>(),
        Get.find<DeviceCatalogRepository>(),
        devicePlayback,
      ),
      permanent: true,
    );
    Get.put<HomeRepository>(
      HomeRemoteRepository(transport: transport, sessionStore: sessionStore),
      permanent: true,
    );
    Get.put<AdRepository>(
      AdRemoteRepository(transport: transport, sessionStore: sessionStore),
      permanent: true,
    );
    Get.put<SeenAdStore>(SeenAdStore(), permanent: true);
    Get.put<LocalVideoRepository>(LocalVideoRepositoryImpl(), permanent: true);
    Get.put<VideoRepository>(
      VideoRemoteRepository(transport: transport, sessionStore: sessionStore),
      permanent: true,
    );
    Get.put<ContentRepository>(
      ContentRemoteRepository(
        transport: transport,
        sessionStore: sessionStore,
        configurationCache: contentConfigurationCache,
      ),
      permanent: true,
    );
    Get.put<FeedbackRepository>(
      FeedbackRemoteRepository(
        transport: transport,
        sessionStore: sessionStore,
        byteUploader: (url, bytes, contentType) =>
            transport.putBytes(url, bytes, contentType: contentType),
        monitor: monitor,
        log: log,
      ),
      permanent: true,
    );
    Get.put<VersionRepository>(
      VersionRemoteRepository(transport: transport, sessionStore: sessionStore),
      permanent: true,
    );
    Get.put<DeviceCommandRepository>(
      BleDeviceCommandRepository(
        Get.find<CyberskinBleRuntimeCoordinator>(),
        runWithControl: devicePlayback.runManualCommand,
      ),
      permanent: true,
    );
    Get.put<SessionController>(
      SessionController(sessionStore: sessionStore),
      permanent: true,
    );
    Get.put<ControlSessionController>(
      ControlSessionController(
        programPlayback: devicePlayback,
        bleCoordinator: Get.find<CyberskinBleRuntimeCoordinator>(),
        commandRepository: Get.find<DeviceCommandRepository>(),
        sessionController: Get.find<SessionController>(),
        log: log,
      ),
      permanent: true,
    );
    Get.put<FloatingControlController>(
      FloatingControlController(),
      permanent: true,
    );
    // 订阅公共播放引擎快照，驱动 iOS Live Activity 和 Android MediaStyle 通知。
    Get.put(PlaybackSessionNotifier(devicePlayback)..start(), permanent: true);
  }
}
