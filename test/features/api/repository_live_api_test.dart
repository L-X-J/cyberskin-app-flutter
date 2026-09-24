// 显式启用时对本地 App API 执行全 Repository 真实链路验证。
import 'dart:io';

import 'package:cyberskin_app/core/logging/app_log.dart';
import 'package:cyberskin_app/core/network/api_transport.dart';
import 'package:cyberskin_app/core/network/app_api_client.dart';
import 'package:cyberskin_app/core/network/network_request_monitor.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/core/storage/session_credential_store.dart';
import 'package:cyberskin_app/features/auth/data/auth_remote_repository.dart';
import 'package:cyberskin_app/features/auth/domain/auth_repository.dart';
import 'package:cyberskin_app/features/content/data/content_configuration_cache.dart';
import 'package:cyberskin_app/features/content/data/content_remote_repository.dart';
import 'package:cyberskin_app/features/content/domain/entities/app_content.dart';
import 'package:cyberskin_app/features/device/data/device_api_repositories.dart';
import 'package:cyberskin_app/features/device/domain/repositories/user_device_repository.dart';
import 'package:cyberskin_app/features/feedback/data/feedback_remote_repository.dart';
import 'package:cyberskin_app/features/feedback/domain/entities/feedback.dart';
import 'package:cyberskin_app/features/profile/data/profile_remote_repository.dart';
import 'package:cyberskin_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:cyberskin_app/features/rhythm/data/rhythm_remote_repository.dart';
import 'package:cyberskin_app/features/rhythm/domain/entities/rhythm.dart';
import 'package:cyberskin_app/features/rhythm/domain/repositories/rhythm_repository.dart';
import 'package:cyberskin_app/features/training/data/training_remote_repository.dart';
import 'package:cyberskin_app/features/version/data/version_remote_repository.dart';
import 'package:cyberskin_app/features/video/data/video_remote_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// 测试进程内保存登录会话，避免 live test 触碰系统 Keychain。
final class _LiveSessionStore implements SessionCredentialStore {
  SessionCredentials? credentials;

  @override
  Future<void> clear() async => credentials = null;

  @override
  Future<SessionCredentials?> read() async => credentials;

  @override
  Future<void> save(SessionCredentials value) async => credentials = value;
}

/// 真实联调使用内存配置缓存，避免污染本机持久配置。
final class _LiveContentCache implements ContentConfigurationCache {
  AppConfiguration? configuration;
  DateTime? lastRefreshAt;
  DateTime? lastLaunchAt;

  @override
  Future<AppConfiguration?> read() async => configuration;

  @override
  Future<DateTime?> readLastRefreshAt() async => lastRefreshAt;

  @override
  Future<DateTime?> readLastLaunchAt() async => lastLaunchAt;

  @override
  Future<void> write(AppConfiguration value) async => configuration = value;

  @override
  Future<void> writeLastRefreshAt(DateTime value) async =>
      lastRefreshAt = value;

  @override
  Future<void> writeLastLaunchAt(DateTime value) async => lastLaunchAt = value;
}

/// 要求每次调用成功，并在失败时保留 Repository 的业务错误上下文。
T _requireSuccess<T>(Result<T> result) {
  if (result case Success<T>(:final value)) {
    return value;
  }
  fail(result.failureOrNull.toString());
}

void main() {
  final baseUrl = Platform.environment['CYBERSKIN_LIVE_API_BASE_URL'];
  final enabled = baseUrl != null && baseUrl.isNotEmpty;

  test('all remote repositories work against the live App API', () async {
    final sessionStore = _LiveSessionStore();
    final monitor = NetworkRequestMonitor(historyLimit: 100);
    final client = AppApiClient(baseUrl: baseUrl)..onStart();
    final transport = GetConnectApiTransport(
      client: client,
      credentials: sessionStore,
      monitor: monitor,
      log: const NoopAppLog(),
    );
    final auth = AuthRemoteRepository(
      transport: transport,
      sessionStore: sessionStore,
    );
    final profile = ProfileRemoteRepository(
      transport: transport,
      sessionStore: sessionStore,
    );
    final catalog = DeviceCatalogRemoteRepository(
      transport: transport,
      sessionStore: sessionStore,
    );
    final devices = UserDeviceRemoteRepository(
      transport: transport,
      sessionStore: sessionStore,
    );
    final rhythms = RhythmRemoteRepository(
      transport: transport,
      sessionStore: sessionStore,
    );
    final training = TrainingRemoteRepository(
      transport: transport,
      sessionStore: sessionStore,
    );
    final video = VideoRemoteRepository(
      transport: transport,
      sessionStore: sessionStore,
    );
    final content = ContentRemoteRepository(
      transport: transport,
      sessionStore: sessionStore,
      configurationCache: _LiveContentCache(),
    );
    final feedback = FeedbackRemoteRepository(
      transport: transport,
      sessionStore: sessionStore,
      byteUploader: (url, bytes, contentType) =>
          transport.putBytes(url, bytes, contentType: contentType),
      monitor: monitor,
      log: const NoopAppLog(),
    );
    final version = VersionRemoteRepository(
      transport: transport,
      sessionStore: sessionStore,
    );

    int? rhythmId;
    int? bindingId;
    try {
      final email =
          'flutter.live.${DateTime.now().microsecondsSinceEpoch}@example.com';
      _requireSuccess(await auth.loginWithGoogle('mock-google-ok'));
      _requireSuccess(
        await auth.loginWithApple(
          const AppleLoginRequest(identityToken: 'mock-apple-ok'),
        ),
      );
      _requireSuccess(await auth.sendEmailCode(email));
      _requireSuccess(
        await auth.loginWithEmail(
          EmailLoginRequest(email: email, code: '123456'),
        ),
      );
      expect(sessionStore.credentials, isNotNull);
      final user = _requireSuccess(await auth.currentUser());
      expect(user.id, isNotNull);
      _requireSuccess(
        await profile.updateProfile(
          const ProfileUpdateRequest(
            nickname: 'Flutter live test',
            avatarUrl: 'https://example.com/flutter-live.png',
          ),
        ),
      );
      final updatedUser = _requireSuccess(await auth.currentUser());
      expect(updatedUser.nickname, 'Flutter live test');

      final models = _requireSuccess(await catalog.listDeviceModels());
      expect(models, isNotEmpty);
      final modelId = models.first.id!;
      final detail = _requireSuccess(
        await catalog.getDeviceModelDetail(modelId),
      );
      expect(detail.summary.id, modelId);
      expect(detail.ble, isNotNull);
      final manual = _requireSuccess(await catalog.getManual(modelId));
      expect(manual.deviceModelId, modelId);

      _requireSuccess(await devices.listUserDevices());
      final binding = _requireSuccess(
        await devices.bind(UserDeviceBindRequest(deviceModelId: modelId)),
      );
      bindingId = binding.id;
      expect(bindingId, isNotNull);
      _requireSuccess(await devices.rename(bindingId!, 'Flutter live device'));
      final bindings = _requireSuccess(await devices.listUserDevices());
      expect(
        bindings.any(
          (item) =>
              item.id == bindingId && item.customName == 'Flutter live device',
        ),
        isTrue,
      );

      _requireSuccess(await rhythms.list(deviceModelId: modelId));
      final createdRhythm = _requireSuccess(
        await rhythms.create(
          RhythmCreateRequest(
            deviceModelId: modelId,
            name: 'Flutter live rhythm',
            segments: <RhythmSegment>[
              RhythmSegment(<String, dynamic>{
                'durationSec': 1,
                'channels': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'channel': 'thrust',
                    'on': true,
                    'value': 1,
                  },
                ],
              }),
            ],
          ),
        ),
      );
      rhythmId = createdRhythm.id;
      expect(rhythmId, isNotNull);
      expect(
        _requireSuccess(await rhythms.getById(rhythmId!)).name,
        'Flutter live rhythm',
      );
      expect(
        _requireSuccess(
          await rhythms.update(
            rhythmId,
            RhythmUpdateRequest(name: 'Flutter live rhythm updated'),
          ),
        ).name,
        'Flutter live rhythm updated',
      );

      final configuration = _requireSuccess(
        await content.refreshConfiguration(),
      );
      expect(configuration.features.emailLoginEnabled, isTrue);
      expect(_requireSuccess(await content.getCmsPage('tos')).code, 'tos');
      _requireSuccess(await content.listAdvertisements());
      _requireSuccess(await video.listOfficialVideos());

      final trainings = _requireSuccess(await training.listTrainings());
      expect(trainings, isNotEmpty);
      final trainingDetail = _requireSuccess(
        await training.getTraining(trainings.first.id!),
      );
      expect(trainingDetail.summary.id, trainings.first.id);
      _requireSuccess(await version.check(platform: 'android', versionCode: 1));

      final ticket = _requireSuccess(
        await feedback.presign(
          const FeedbackAttachmentRequest(
            filename: 'flutter-live.png',
            contentType: 'image/png',
            size: 68,
          ),
        ),
      );
      final pngBytes = <int>[
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        0x00,
        0x00,
        0x00,
        0x0d,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1f,
        0x15,
        0xc4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0d,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9c,
        0x63,
        0x60,
        0x00,
        0x00,
        0x00,
        0x02,
        0x00,
        0x01,
        0xe2,
        0x21,
        0xbc,
        0x33,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4e,
        0x44,
        0xae,
        0x42,
        0x60,
        0x82,
      ];
      _requireSuccess(
        await feedback.uploadBytes(ticket, pngBytes, contentType: 'image/png'),
      );
      final attachment = _requireSuccess(
        await feedback.completeUpload(
          ticket.objectKey!,
          contentType: 'image/png',
          size: pngBytes.length,
        ),
      );
      expect(attachment.accessUrl, isNotEmpty);
      expect(
        _requireSuccess(
          await feedback.createFeedback(
            FeedbackCreateRequest(
              content: 'Flutter live API verification',
              imageUrls: <String>[attachment.accessUrl!],
            ),
          ),
        ),
        greaterThan(0),
      );

      _requireSuccess(await rhythms.delete(rhythmId));
      rhythmId = null;
      _requireSuccess(await devices.unbind(bindingId));
      bindingId = null;
    } finally {
      if (rhythmId != null) {
        await rhythms.delete(rhythmId);
      }
      if (bindingId != null) {
        await devices.unbind(bindingId);
      }
      await auth.logout();
    }

    expect(sessionStore.credentials, isNull);
    expect(monitor.activeRequestCount.value, 0);
    expect(monitor.history, isNotEmpty);
  }, skip: enabled ? false : 'CYBERSKIN_LIVE_API_BASE_URL 未配置。');
}
