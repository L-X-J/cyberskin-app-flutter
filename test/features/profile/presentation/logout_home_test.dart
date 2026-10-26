// 退出账号回到已有未连接首页，验证路由生命周期和远端退出的凭证读取顺序。
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/app/app_routes.dart';
import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/app/widgets/app_scaffold.dart';
import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/core/storage/session_credential_store.dart';
import 'package:cyberskin_app/features/auth/domain/app_user.dart';
import 'package:cyberskin_app/features/auth/domain/auth_repository.dart';
import 'package:cyberskin_app/features/auth/presentation/login_controller.dart';
import 'package:cyberskin_app/features/content/domain/entities/app_content.dart';
import 'package:cyberskin_app/features/content/domain/repositories/content_repository.dart';
import 'package:cyberskin_app/features/device/data/cyberskin_ble_runtime_coordinator.dart';
import 'package:cyberskin_app/features/device/domain/connected_device_state.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/device/domain/device_repository.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_home_controller.dart';
import 'package:cyberskin_app/features/home/presentation/home_connected/home_connected_view.dart';
import 'package:cyberskin_app/features/home/presentation/home_controller.dart';
import 'package:cyberskin_app/features/home/presentation/home_disconnected/home_disconnected_view.dart';
import 'package:cyberskin_app/features/home/presentation/home_page.dart';
import 'package:cyberskin_app/features/profile/presentation/profile_controller.dart';
import 'package:cyberskin_app/features/profile/presentation/profile_page.dart';
import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => Get.reset());

  test('credential invalidation ends a session without a home route', () async {
    final store = _Credentials();
    var cleanupCalls = 0;
    final session = SessionController(
      sessionStore: store,
      onSessionEnded: () async {
        cleanupCalls++;
      },
    );
    session.onInit();
    session.markAuthenticated();
    session.deviceStatus.value = DeviceConnectionStatus.connected;
    await store.clear();
    await Future<void>.delayed(Duration.zero);
    expect(session.state.value, SessionState.anonymous);
    expect(session.deviceStatus.value, DeviceConnectionStatus.disconnected);
    expect(cleanupCalls, 1);
    session.onClose();
    await store.events.close();
  });

  for (final remoteFails in [false, true]) {
    testWidgets('logout returns to living home when remoteFails=$remoteFails', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        for (final font in [
          ('LogoutPreview', 'Roboto-Regular.ttf'),
          ('MaterialIcons', 'MaterialIcons-Regular.otf'),
        ]) {
          final bytes = File(
            '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/${font.$2}',
          ).readAsBytesSync();
          await (FontLoader(
            font.$1,
          )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
        }
      });
      final store = _Credentials();
      addTearDown(store.events.close);
      late final CyberskinBleRuntimeCoordinator coordinator;
      final session = Get.put(
        SessionController(
          sessionStore: store,
          onSessionEnded: () => coordinator.clearUserSession(),
        ),
        permanent: true,
      )..markAuthenticated();
      coordinator = CyberskinBleRuntimeCoordinator(
        catalogRepository: _Catalog(),
        isAuthenticated: () =>
            session.state.value == SessionState.authenticated,
      );
      // 使用已初始化的离线适配器，所有平台 BLE 操作都不会触发。
      coordinator.isInitialized.value = true;
      coordinator.adapterState.value = 'on';
      coordinator.connectionStates['device'] = BleConnectionState.connected;
      coordinator.setConnectedDevice(
        ConnectedDeviceState(device: _liveDevice(), remoteId: 'device'),
      );
      addTearDown(coordinator.onClose);
      final auth = _Auth(store, remoteFails);
      var homeCreations = 0;
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'LogoutPreview',
          ),
          initialRoute: AppRoutes.home,
          getPages: [
            GetPage<void>(
              name: AppRoutes.home,
              page: () => const RepaintBoundary(
                key: ValueKey('logout-home'),
                child: HomePage(),
              ),
              binding: BindingsBuilder<void>(() {
                homeCreations++;
                Get.put(DeviceHomeController(_Devices(), coordinator));
                Get.put(HomeController(session, bleCoordinator: coordinator));
              }),
            ),
            GetPage<void>(
              name: AppRoutes.login,
              page: () => const Scaffold(body: Text('Login')),
              binding: BindingsBuilder<void>(() {
                Get.put(LoginController(auth, _Content(), session));
              }),
            ),
            GetPage<void>(
              name: AppRoutes.profile,
              page: () => const ProfilePage(),
              binding: BindingsBuilder<void>(() {
                Get.put(ProfileController(auth, session));
              }),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      final home = Get.find<HomeController>();
      final device = Get.find<DeviceHomeController>();
      final homeState = tester.state(find.byType(HomePage));
      expect(session.deviceStatus.value, DeviceConnectionStatus.connected);
      home.selectTab(AppTab.video);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      unawaited(Get.toNamed<void>(AppRoutes.profile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign out'));
      await tester.pump();
      expect(session.state.value, SessionState.anonymous);
      expect(session.deviceStatus.value, DeviceConnectionStatus.disconnected);
      expect(
        store.value,
        isNotNull,
        reason: 'Remote logout must still read credentials',
      );
      expect(coordinator.connectionStates, isEmpty);
      auth.remoteGate.complete();
      await tester.pumpAndSettle();

      expect(auth.receivedToken, 'test-token');
      expect(store.value, isNull);
      expect(Get.currentRoute, AppRoutes.home);
      expect(homeCreations, 1);
      expect(Get.find<HomeController>(), same(home));
      expect(Get.find<DeviceHomeController>(), same(device));
      expect(home.isClosed, isFalse);
      expect(device.devices, isEmpty);
      expect(tester.state(find.byType(HomePage)), same(homeState));
      expect(home.selectedTab.value, AppTab.home);
      expect(find.byType(HomeDisconnectedView), findsOneWidget);
      expect(find.text('Add Device'), findsOneWidget);
      // 即使旧派生状态仍为扫描中，匿名视图也必须显示登录入口。
      home.bleCardState.value = HomeBleCardState.fromPhase(
        HomeBleCardPhase.scanning,
        adapterOn: true,
      );
      await tester.pump();
      expect(find.text('Log in now'), findsOneWidget);
      expect(find.text('Stop'), findsNothing);
      expect(coordinator.isScanning.value, isFalse);
      expect(tester.takeException(), isNull);
      Future<void> capture(String state) async {
        if (remoteFails) return;
        await tester.runAsync(() async {
          final context = tester.element(find.byType(HomePage));
          await Future.wait([
            for (final asset in [
              'device_air.png',
              'device_pro.png',
              'go_user_profile.png',
              'device_air_connected.png',
            ])
              precacheImage(AssetImage('assets/images/home/$asset'), context),
          ]);
        });
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('logout-home')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            Directory('build/ui').createSync(recursive: true);
            File('build/ui/home_${state}_402x874_text1.0.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }

      await capture('logout_disconnected');
      // 通过真实登录 Controller 返回已有首页，再投影设备连接，覆盖第二次入场。
      await tester.tap(find.text('Log in now'));
      await tester.pumpAndSettle();
      final login = Get.find<LoginController>();
      login.verificationEmail.value = 'test@example.com';
      login.code.value = '123456';
      final loggingIn = login.signInWithEmail();
      await tester.pumpAndSettle();
      await loggingIn;
      expect(Get.currentRoute, AppRoutes.home);
      expect(homeCreations, 1);
      expect(Get.find<HomeController>(), same(home));
      expect(home.isClosed, isFalse);
      coordinator.isScanning.value = true;
      await tester.pump();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(coordinator.isScanning.value, isFalse);
      expect(find.text('Stop'), findsNothing);
      coordinator.permissionGranted.value = true;
      await tester.pumpAndSettle();
      expect(coordinator.isDiscoveryPaused, isTrue);
      await home.startDiscovery();
      coordinator.connectionStates['device'] = BleConnectionState.connecting;
      coordinator.connectionStates['device'] = BleConnectionState.connected;
      coordinator.setConnectedDevice(
        ConnectedDeviceState(device: _liveDevice(), remoteId: 'device'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HomeDisconnectedView), findsNothing);
      expect(find.byType(HomeConnectedView), findsOneWidget);
      expect(find.text('My device'), findsOneWidget);
      final connectedFades = tester.widgetList<FadeTransition>(
        find.descendant(
          of: find.byType(HomeConnectedView),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(connectedFades, isNotEmpty);
      expect(connectedFades.every((fade) => fade.opacity.value == 1), isTrue);
      expect(Get.find<DeviceHomeController>(), same(device));
      expect(tester.takeException(), isNull);
      await capture('relogin_connected');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

class _Credentials implements SessionCredentialStore {
  SessionCredentials? value = const SessionCredentials(
    accessToken: 'test-token',
    clientId: 'test',
  );
  final events = StreamController<void>.broadcast();
  @override
  Stream<void> get invalidated => events.stream;
  @override
  Future<SessionCredentials?> read() async => value;
  @override
  Future<void> save(SessionCredentials credentials) async {
    value = credentials;
  }

  @override
  Future<void> clear() async {
    value = null;
    events.add(null);
  }
}

class _Auth implements AuthRepository {
  _Auth(this.store, this.remoteFails);
  final _Credentials store;
  final bool remoteFails;
  final remoteGate = Completer<void>();
  String? receivedToken;
  @override
  Future<Result<void>> logout() async {
    await remoteGate.future;
    receivedToken = (await store.read())?.accessToken;
    await store.clear();
    return remoteFails
        ? const Result.failure(
            AppFailure(code: FailureCode.unauthorized, message: 'Expired'),
          )
        : const Result.ok(null);
  }

  @override
  Future<Result<AppUser>> currentUser() async =>
      const Result.ok(AppUser(nickname: 'Test user'));
  @override
  Future<Result<void>> sendEmailCode(String email) =>
      throw UnimplementedError();
  @override
  Future<Result<AppUser>> loginWithEmail(EmailLoginRequest request) async {
    await store.save(
      const SessionCredentials(accessToken: 'next-token', clientId: 'test'),
    );
    return const Result.ok(AppUser(nickname: 'Test user'));
  }

  @override
  Future<Result<AppUser>> loginWithGoogle(String token) =>
      throw UnimplementedError();
  @override
  Future<Result<AppUser>> loginWithApple(AppleLoginRequest request) =>
      throw UnimplementedError();
}

class _Catalog implements DeviceCatalogRepository {
  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() async =>
      const Result.failure(
        AppFailure(code: FailureCode.network, message: 'offline'),
      );
  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) =>
      throw UnimplementedError();
  @override
  Future<Result<DeviceManual>> getManual(int id) => throw UnimplementedError();
}

Device _liveDevice() => Device(
  id: 'device',
  model: '1',
  name: 'Test device',
  status: DeviceConnectionStatus.connected,
  capabilities: DeviceCapabilities(channels: const []),
);

// 与日志一致：已连接但设备列表为空，页面必须使用实时快照。
class _Devices implements DeviceRepository {
  @override
  Future<Result<List<Device>>> loadDevices() async => const Result.ok([]);
}

class _Content implements ContentRepository {
  @override
  Future<AppConfiguration?> readCachedConfiguration() async =>
      AppConfiguration();
  @override
  Future<DateTime?> readLastRefreshAt() async => null;
  @override
  Future<DateTime?> readLastLaunchAt() async => null;
  @override
  Future<void> writeLastLaunchAt(DateTime value) async {}
  @override
  Future<Result<AppConfiguration>> refreshConfiguration() async =>
      Result.ok(AppConfiguration());
  @override
  Future<Result<CmsPage>> getCmsPage(String code) => throw UnimplementedError();
  @override
  Future<Result<List<AppAdvertisement>>> listAdvertisements() async =>
      const Result.ok([]);
}
