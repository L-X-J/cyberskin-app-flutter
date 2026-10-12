import 'dart:async';

import 'package:cyberskin_app/core/logging/app_log.dart';
import 'package:cyberskin_app/core/network/api_transport.dart';
import 'package:cyberskin_app/core/network/app_api_operation.dart';
import 'package:cyberskin_app/core/network/network_request_monitor.dart';
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
import 'package:http/http.dart' as http;

final class _MemorySessionStore implements SessionCredentialStore {
  _MemorySessionStore(this.value);

  SessionCredentials? value;
  final StreamController<void> _invalidations =
      StreamController<void>.broadcast();

  @override
  Stream<void> get invalidated => _invalidations.stream;

  @override
  Future<void> clear() async {
    value = null;
    if (!_invalidations.isClosed) {
      _invalidations.add(null);
    }
  }

  @override
  Future<SessionCredentials?> read() async => value;

  @override
  Future<void> save(SessionCredentials credentials) async =>
      value = credentials;
}

final class _RecordedRequest {
  const _RecordedRequest({
    required this.operation,
    required this.pathParameters,
    required this.queryParameters,
    required this.body,
  });

  final AppApiOperation operation;
  final Map<String, Object?> pathParameters;
  final Map<String, Object?> queryParameters;
  final Object? body;
}

final class _RecordingTransport implements ApiTransport {
  final List<_RecordedRequest> requests = <_RecordedRequest>[];
  final List<Uri> textRequests = <Uri>[];

  @override
  Future<String> fetchText(Uri uri) async {
    textRequests.add(uri);
    return '<h2 style="text-align:center">Remote manual</h2>';
  }

  @override
  Future<ApiRawResponse> send(
    AppApiOperation operation, {
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, Object?> queryParameters = const <String, Object?>{},
    Object? body,
  }) async {
    requests.add(
      _RecordedRequest(
        operation: operation,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        body: body,
      ),
    );
    return ApiRawResponse(statusCode: 200, body: _success(_dataFor(operation)));
  }
}

/// 合约测试使用的内存配置缓存，不触碰平台存储插件。
final class _MemoryContentCache implements ContentConfigurationCache {
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

SessionCredentials _session() =>
    SessionCredentials(accessToken: 'token', clientId: 'client-id');

Map<String, dynamic> _success(Object? data) => <String, dynamic>{
  'code': 200,
  'msg': '',
  'data': data,
};

Object? _dataFor(AppApiOperation operation) => switch (operation) {
  AppApiOperation.rhythmDetail ||
  AppApiOperation.updateRhythm ||
  AppApiOperation.createRhythm => <String, dynamic>{
    'id': 1,
    'deviceModelId': 2,
    'name': 'Rhythm',
    'segmentCount': 1,
    'segments': <Map<String, dynamic>>[
      <String, dynamic>{'durationSec': 5, 'v': 1},
    ],
  },
  AppApiOperation.listRhythms => <Map<String, dynamic>>[
    <String, dynamic>{'id': 1, 'segments': <Map<String, dynamic>>[]},
  ],
  AppApiOperation.listUserDevices || AppApiOperation.bindUserDevice =>
    operation == AppApiOperation.listUserDevices
        ? <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'deviceModelId': 2, 'name': 'Device'},
          ]
        : <String, dynamic>{'id': 1, 'deviceModelId': 2, 'name': 'Device'},
  AppApiOperation.listDeviceModels => <Map<String, dynamic>>[
    <String, dynamic>{'id': 2, 'name': 'Device'},
  ],
  AppApiOperation.deviceModelDetail => <String, dynamic>{
    'id': 2,
    'name': 'Device',
    'ble': <String, dynamic>{'readChar': 'ae02'},
    'supportedActions': <Map<String, dynamic>>[],
    'heatSupported': 1,
    'heatLevels': <int>[1, 2],
    'layout': <String, dynamic>{'columns': 2},
  },
  AppApiOperation.deviceManual => <String, dynamic>{
    'deviceModelId': 2,
    'items': <Map<String, dynamic>>[
      <String, dynamic>{
        'tab': 'intro',
        'contentUrl': 'https://cdn.example.test/manual/intro.html',
      },
    ],
  },
  AppApiOperation.googleLogin ||
  AppApiOperation.emailLogin ||
  AppApiOperation.appleLogin => <String, dynamic>{
    'token': 'new-token',
    'clientId': 'new-client',
    'expireIn': 3600,
    'user': <String, dynamic>{'id': 3, 'profileCompleted': 'Y'},
  },
  AppApiOperation.currentUser => <String, dynamic>{
    'id': 3,
    'profileCompleted': 1,
  },
  AppApiOperation.officialVideos => <String, dynamic>{
    'total': 1,
    'rows': <Map<String, dynamic>>[
      <String, dynamic>{'id': 1, 'durationSec': 30},
    ],
  },
  AppApiOperation.checkVersion => <String, dynamic>{'hasUpdate': 'false'},
  AppApiOperation.listTrainings => <Map<String, dynamic>>[
    <String, dynamic>{'id': 1, 'nameEn': 'Training'},
  ],
  AppApiOperation.trainingDetail => <String, dynamic>{
    'id': 1,
    'stages': <Map<String, dynamic>>[
      <String, dynamic>{'duration': 10},
    ],
    'customMode': <Map<String, dynamic>>[
      <String, dynamic>{
        'start-end': '0-10',
        'des': 'Warmup',
        'command_data': 'v:1',
      },
    ],
  },
  AppApiOperation.appConfig => <String, dynamic>{
    'features': <String, dynamic>{'feedbackEnabled': 'Y'},
  },
  AppApiOperation.cmsPage => <String, dynamic>{'id': 1, 'code': 'tos'},
  AppApiOperation.listAds => <Map<String, dynamic>>[
    <String, dynamic>{'id': 1, 'jumpType': 'url'},
  ],
  AppApiOperation.presignUpload => <String, dynamic>{
    'uploadUrl': 'https://upload.example.test/object',
    'objectKey': 'feedback/object.png',
  },
  AppApiOperation.completeUpload => <String, dynamic>{
    'objectKey': 'feedback/object.png',
  },
  AppApiOperation.createFeedback => 99,
  AppApiOperation.deleteRhythm ||
  AppApiOperation.renameUserDevice ||
  AppApiOperation.unbindUserDevice ||
  AppApiOperation.updateProfile ||
  AppApiOperation.logout ||
  AppApiOperation.sendEmailCode => null,
};

void main() {
  test(
    'repositories map every OpenAPI operation to its registered operation',
    () async {
      final store = _MemorySessionStore(_session());
      final transport = _RecordingTransport();
      final auth = AuthRemoteRepository(
        transport: transport,
        sessionStore: store,
      );
      final profile = ProfileRemoteRepository(
        transport: transport,
        sessionStore: store,
      );
      final catalog = DeviceCatalogRemoteRepository(
        transport: transport,
        sessionStore: store,
      );
      final devices = UserDeviceRemoteRepository(
        transport: transport,
        sessionStore: store,
      );
      final rhythms = RhythmRemoteRepository(
        transport: transport,
        sessionStore: store,
      );
      final training = TrainingRemoteRepository(
        transport: transport,
        sessionStore: store,
      );
      final video = VideoRemoteRepository(
        transport: transport,
        sessionStore: store,
      );
      final content = ContentRemoteRepository(
        transport: transport,
        sessionStore: store,
        configurationCache: _MemoryContentCache(),
      );
      final feedback = FeedbackRemoteRepository(
        transport: transport,
        sessionStore: store,
        byteUploader: (url, bytes, contentType) async => http.Response('', 200),
        monitor: NetworkRequestMonitor(),
        log: const NoopAppLog(),
      );
      final version = VersionRemoteRepository(
        transport: transport,
        sessionStore: store,
      );

      await rhythms.getById(1);
      await rhythms.update(1, RhythmUpdateRequest(name: 'New'));
      await rhythms.delete(1);
      await devices.rename(1, 'Desk');
      await devices.unbind(1);
      await profile.updateProfile(const ProfileUpdateRequest(nickname: 'New'));
      await rhythms.list(deviceModelId: 2);
      await rhythms.create(
        RhythmCreateRequest(
          deviceModelId: 2,
          name: 'New',
          segments: <RhythmSegment>[
            RhythmSegment(<String, dynamic>{'v': 1}),
          ],
        ),
      );
      final ticketResult = await feedback.presign(
        const FeedbackAttachmentRequest(
          filename: 'image.png',
          contentType: 'image/png',
        ),
      );
      final ticket = ticketResult.valueOrNull!;
      await feedback.uploadBytes(ticket, <int>[1], contentType: 'image/png');
      await feedback.completeUpload('feedback/object.png');
      await devices.listUserDevices();
      await devices.bind(const UserDeviceBindRequest(deviceModelId: 2));
      await feedback.createFeedback(FeedbackCreateRequest(content: 'Text'));
      await auth.logout();
      expect(store.value, isNull);
      store.value = _session();
      await auth.loginWithGoogle('google-token');
      await auth.sendEmailCode('user@example.com');
      await auth.loginWithEmail(
        const EmailLoginRequest(email: 'user@example.com', code: '123456'),
      );
      await auth.loginWithApple(
        const AppleLoginRequest(identityToken: 'apple-token'),
      );
      await video.listOfficialVideos(pageNumber: 2, pageSize: 3);
      await version.check(platform: 'ios', versionCode: 1);
      await training.listTrainings();
      await training.getTraining(1);
      await catalog.listDeviceModels();
      await catalog.getDeviceModelDetail(2);
      final manual = await catalog.getManual(2);
      expect(
        manual.valueOrNull?.items.single.contentHtml,
        contains('Remote manual'),
      );
      await content.readCachedConfiguration();
      await content.readLastRefreshAt();
      await content.refreshConfiguration();
      await content.getCmsPage('tos');
      await auth.currentUser();
      await content.listAdvertisements();

      expect(
        transport.requests.map((item) => item.operation).toSet(),
        AppApiOperation.values.toSet(),
      );
      expect(transport.requests, hasLength(29));
      expect(transport.textRequests, <Uri>[
        Uri.parse('https://cdn.example.test/manual/intro.html'),
      ]);
      final videoRequest = transport.requests.singleWhere(
        (item) => item.operation == AppApiOperation.officialVideos,
      );
      expect(videoRequest.queryParameters, <String, Object?>{
        'pageNum': 2,
        'pageSize': 3,
      });
      final rhythmRequest = transport.requests.singleWhere(
        (item) => item.operation == AppApiOperation.createRhythm,
      );
      expect(rhythmRequest.body, <String, Object?>{
        'deviceModelId': 2,
        'name': 'New',
        'segments': <Map<String, dynamic>>[
          <String, dynamic>{'v': 1},
        ],
      });
    },
  );
}
