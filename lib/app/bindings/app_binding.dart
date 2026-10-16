// 应用级依赖装配：注册全局 Repository、API 客户端和跨页面控制器。
import 'package:get/get.dart';

import '../../core/logging/app_log.dart';
import '../../core/network/api_transport.dart';
import '../../core/network/app_api_client.dart';
import '../../core/network/network_request_monitor.dart';
import '../../core/storage/session_credential_store.dart';
import '../../features/auth/data/auth_remote_repository.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/content/data/content_configuration_cache.dart';
import '../../features/content/data/content_remote_repository.dart';
import '../../features/content/domain/repositories/content_repository.dart';
import '../../features/control/presentation/control_session_controller.dart';
import '../../features/control/data/ble_device_command_repository.dart';
import '../../features/control/domain/device_command_repository.dart';
import '../../features/device/data/cached_user_device_repository.dart';
import '../../features/device/data/device_api_repositories.dart';
import '../../features/device/data/cyberskin_ble_runtime_coordinator.dart';
import '../../features/device/data/connected_device_repository.dart';
import '../../features/device/data/user_device_cache.dart';
import '../../features/device/domain/device_repository.dart';
import '../../features/device/domain/repositories/device_catalog_repository.dart';
import '../../features/device/domain/repositories/user_device_repository.dart';
import '../../features/feedback/data/feedback_remote_repository.dart';
import '../../features/feedback/domain/repositories/feedback_repository.dart';
import '../../features/profile/data/profile_remote_repository.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/rhythm/data/rhythm_remote_repository.dart';
import '../../features/rhythm/domain/repositories/rhythm_repository.dart';
import '../../features/training/data/training_remote_repository.dart';
import '../../features/training/domain/repositories/training_repository.dart';
import '../../features/version/data/version_remote_repository.dart';
import '../../features/version/domain/repositories/version_repository.dart';
import '../../features/video/data/video_remote_repository.dart';
import '../../features/video/domain/repositories/video_repository.dart';
import '../../features/video/domain/repositories/local_video_repository.dart';
import '../../features/video/data/local_video_repository_impl.dart';
import '../floating_control_controller.dart';
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
    Get.put<RhythmRepository>(
      RhythmRemoteRepository(transport: transport, sessionStore: sessionStore),
      permanent: true,
    );
    Get.put<TrainingRepository>(
      TrainingRemoteRepository(
        transport: transport,
        sessionStore: sessionStore,
      ),
      permanent: true,
    );
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
      BleDeviceCommandRepository(Get.find<CyberskinBleRuntimeCoordinator>()),
      permanent: true,
    );
    Get.put<ControlSessionController>(
      ControlSessionController(),
      permanent: true,
    );
    Get.put<SessionController>(
      SessionController(sessionStore: sessionStore),
      permanent: true,
    );
    Get.put<FloatingControlController>(
      FloatingControlController(),
      permanent: true,
    );
  }
}
