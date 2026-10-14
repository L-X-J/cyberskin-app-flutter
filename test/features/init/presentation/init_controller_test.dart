import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/core/storage/session_credential_store.dart';
import 'package:cyberskin_app/features/content/domain/entities/app_content.dart';
import 'package:cyberskin_app/features/content/domain/repositories/content_repository.dart';
import 'package:cyberskin_app/features/init/presentation/init_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// 可编程的内容 Repository，用于验证初始化决策而不访问网络。
final class _FakeContentRepository implements ContentRepository {
  _FakeContentRepository({
    this.cached,
    this.lastRefreshAt,
    this.lastLaunchAt,
    this.refreshResult,
  });

  AppConfiguration? cached;
  DateTime? lastRefreshAt;
  DateTime? lastLaunchAt;
  Result<AppConfiguration>? refreshResult;
  int refreshCount = 0;

  @override
  Future<AppConfiguration?> readCachedConfiguration() async => cached;

  @override
  Future<DateTime?> readLastRefreshAt() async => lastRefreshAt;

  @override
  Future<DateTime?> readLastLaunchAt() async => lastLaunchAt;

  @override
  Future<void> writeLastLaunchAt(DateTime value) async => lastLaunchAt = value;

  @override
  Future<Result<AppConfiguration>> refreshConfiguration() async {
    refreshCount++;
    return refreshResult!;
  }

  @override
  Future<Result<CmsPage>> getCmsPage(String code) => throw UnimplementedError();

  @override
  Future<Result<List<AppAdvertisement>>> listAdvertisements() =>
      throw UnimplementedError();
}

/// 可观测的内存会话存储，用于验证启动缓存不会误清除已恢复凭证。
final class _FakeSessionCredentialStore implements SessionCredentialStore {
  _FakeSessionCredentialStore(this.value);

  SessionCredentials? value;
  int clearCount = 0;

  @override
  Stream<void> get invalidated => const Stream<void>.empty();

  @override
  Future<SessionCredentials?> read() async => value;

  @override
  Future<void> save(SessionCredentials credentials) async =>
      value = credentials;

  @override
  Future<void> clear() async {
    clearCount++;
    value = null;
  }
}

AppConfiguration _configuration(String version) => AppConfiguration(
  version: version,
  features: const AppFeatureFlags(emailLoginEnabled: true),
);

void main() {
  tearDown(Get.reset);

  test('waits for the first refresh when no cache exists', () async {
    final repository = _FakeContentRepository(
      refreshResult: Result.ok(_configuration('first')),
    );
    var navigationCount = 0;
    final controller = InitController(
      repository,
      navigateToNextPage: () async => navigationCount++,
    );

    await controller.start();

    expect(repository.refreshCount, 1);
    expect(controller.configuration.value?.version, 'first');
    expect(controller.status.value, InitStatus.ready);
    expect(navigationCount, 1);
  });

  test('uses cached data and refreshes in the background', () async {
    final repository = _FakeContentRepository(
      cached: _configuration('cached'),
      lastRefreshAt: DateTime.now(),
      lastLaunchAt: DateTime.now(),
      refreshResult: Result.ok(_configuration('new')),
    );
    var navigationCount = 0;
    final controller = InitController(
      repository,
      navigateToNextPage: () async => navigationCount++,
    );

    await controller.start();
    await Future<void>.delayed(Duration.zero);

    expect(repository.refreshCount, 1);
    expect(controller.configuration.value?.version, 'new');
    expect(controller.status.value, InitStatus.ready);
    expect(navigationCount, 1);
  });

  test('keeps cached data usable when background refresh fails', () async {
    final repository = _FakeContentRepository(
      cached: _configuration('cached'),
      lastRefreshAt: DateTime.now().subtract(const Duration(days: 1)),
      lastLaunchAt: DateTime.now(),
      refreshResult: const Result.failure(
        AppFailure(code: FailureCode.network, message: 'offline'),
      ),
    );
    var navigationCount = 0;
    final controller = InitController(
      repository,
      navigateToNextPage: () async => navigationCount++,
    );

    await controller.start();
    await Future<void>.delayed(Duration.zero);

    expect(repository.refreshCount, 1);
    expect(controller.configuration.value?.version, 'cached');
    expect(controller.status.value, InitStatus.ready);
    expect(controller.failure.value?.message, 'offline');
    expect(navigationCount, 1);
  });

  test('blocks navigation when first refresh fails without cache', () async {
    const failure = AppFailure(
      code: FailureCode.network,
      message: 'cannot load config',
    );
    final repository = _FakeContentRepository(
      refreshResult: const Result.failure(failure),
    );
    var navigationCount = 0;
    final controller = InitController(
      repository,
      navigateToNextPage: () async => navigationCount++,
    );

    await controller.start();

    expect(controller.status.value, InitStatus.failed);
    expect(controller.failure.value, failure);
    expect(navigationCount, 0);
  });

  test('first launch today waits for refresh even when cache exists', () async {
    final repository = _FakeContentRepository(
      cached: _configuration('cached'),
      lastLaunchAt: DateTime.now().subtract(const Duration(days: 1)),
      refreshResult: Result.ok(_configuration('fresh')),
    );
    var navigationCount = 0;
    final controller = InitController(
      repository,
      navigateToNextPage: () async => navigationCount++,
    );

    await controller.start();

    expect(repository.refreshCount, 1);
    expect(controller.configuration.value?.version, 'fresh');
    expect(navigationCount, 1);
  });

  test(
    'does not clear restored credentials from stale anonymous cache',
    () async {
      final store = _FakeSessionCredentialStore(
        const SessionCredentials(accessToken: 'token', clientId: 'client'),
      );
      final session = SessionController(sessionStore: store);
      final repository = _FakeContentRepository(
        // 这是用户登录前匿名状态产生的常见旧缓存。
        cached: _configuration('anonymous-cache'),
        lastLaunchAt: DateTime.now(),
        refreshResult: Result.ok(
          AppConfiguration(version: 'fresh', loggedIn: true),
        ),
      );
      final controller = InitController(
        repository,
        sessionController: session,
        navigateToNextPage: () async {},
      );

      await controller.start();

      expect(session.state.value, SessionState.authenticated);
      expect(store.value?.accessToken, 'token');
      expect(store.clearCount, 0);
    },
  );
}
