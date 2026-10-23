import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/app/app_routes.dart';
import 'package:cyberskin_app/app/floating_control_controller.dart';
import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/app/widgets/app_primary_tab_navigation.dart';
import 'package:cyberskin_app/app/widgets/app_scaffold.dart';
import 'package:cyberskin_app/app/widgets/floating_device_control_overlay.dart';
import 'package:cyberskin_app/core/theme/app_video_style.dart';
import 'package:cyberskin_app/features/control/domain/device_session.dart';
import 'package:cyberskin_app/features/control/presentation/control_session_controller.dart';
import 'package:cyberskin_app/features/control/presentation/widgets/device_control_pill.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/video/domain/entities/video_media.dart';
import 'package:cyberskin_app/features/video/presentation/video_player_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_video_feed_list/flutter_video_feed_list.dart';
import 'package:get/get.dart';
// 通过插件已有的平台接口提供有尺寸的画面，核验画面与进度线的真实渲染边界。
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart'
    as vp;

import '../support/ble_control_fixture.dart';

void main() {
  late FloatingControlController floating;
  late SessionController session;
  late ControlSessionController control;
  const extraDetail = '/test-detail';
  const fullScreen = '/test-full-screen';
  setUp(() {
    Get.testMode = true;
    floating = Get.put(FloatingControlController(), permanent: true);
    session = Get.put(SessionController(), permanent: true)
      ..markAuthenticated();
    control = Get.put(ControlSessionController(), permanent: true);
  });
  tearDown(() => Get.reset());

  Future<void> render(
    WidgetTester tester, {
    double textScale = 1,
    Size viewport = const Size(402, 874),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewport;
    tester.view.padding = const FakeViewPadding(top: 50, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 50, bottom: 34);
    addTearDown(tester.view.reset);
    Widget page(String title) => AppScaffold(
      currentTab: title == 'Video' ? AppTab.video : AppTab.home,
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          TextButton(
            onPressed: () => unawaited(Get.toNamed<void>(AppRoutes.profile)),
            child: const Text('Open detail'),
          ),
          const TextField(),
          ...List.generate(
            25,
            (i) => SizedBox(height: 40, child: Text('Item $i')),
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        initialRoute: AppRoutes.home,
        navigatorObservers: [
          FloatingControlObserver(
            policies: {
              ...AppRoutes.floatingControlPolicies,
              extraDetail: FloatingControlPolicy.draggable,
              fullScreen: FloatingControlPolicy.hidden,
            },
            resetRoutes: {AppRoutes.home},
          ),
        ],
        getPages: [
          GetPage(name: AppRoutes.home, page: () => page('Home')),
          GetPage(name: AppRoutes.video, page: () => page('Video')),
          GetPage(name: AppRoutes.profile, page: () => page('Profile')),
          GetPage(name: extraDetail, page: () => page('Detail')),
          GetPage(
            name: AppRoutes.login,
            page: () => const Scaffold(body: Text('Login')),
          ),
          GetPage(
            name: fullScreen,
            page: () => const Scaffold(body: Text('Fullscreen')),
          ),
        ],
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: FloatingDeviceControlOverlay(child: child!),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  Future<void> open(WidgetTester tester, String route) async {
    unawaited(Get.toNamed<void>(route));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
  }

  testWidgets(
    'stopped repeated telemetry changes Running to Paused without layout changes',
    (tester) async {
      await Get.delete<ControlSessionController>(force: true);
      final fixture = BleControlFixture(session: session, initialize: false);
      addTearDown(fixture.coordinator.onClose);
      control = Get.put(fixture.control, permanent: true);
      fixture.emit(stoppedStatus);
      await render(tester);
      final pill = find.byType(DeviceControlPill);
      final initialRect = tester.getRect(pill);
      await control.activateQuickControl();
      await tester.pump();
      expect(find.text('Running'), findsOneWidget);
      fixture.emit(stoppedStatus);
      await tester.pump();
      expect(find.text('Running'), findsNothing);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('Tap to resume'), findsOneWidget);
      expect(tester.getRect(pill), initialRect);
      await tester.tap(pill);
      await tester.pump();
      expect(find.text('Running'), findsOneWidget);
      fixture.emit(stoppedStatus);
      await tester.pump();
      expect(find.text('Paused'), findsOneWidget);
      expect(fixture.commands.sent, ['t:c|v:c', 't:c|v:c']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'single host docks without overlapping navigation and fixed routes reject dragging',
    (tester) async {
      await render(tester);
      final pill = find.byType(DeviceControlPill);
      expect(pill, findsOneWidget);
      final rect = tester.getRect(pill);
      expect(rect.right, closeTo(378, 0.01));
      expect(
        rect.bottom,
        closeTo(floating.bodyBounds.value!.bottom - 12, 0.01),
      );
      final navigation = tester.getRect(find.byType(AppPrimaryTabNavigation));
      final overlapsHorizontally =
          rect.left < navigation.right && navigation.left < rect.right;
      if (overlapsHorizontally) {
        expect(navigation.bottom + 12, lessThanOrEqualTo(rect.top));
      } else {
        expect(rect.bottom, closeTo(navigation.bottom, 0.01));
      }
      await tester.drag(pill, const Offset(-120, -200));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getRect(pill), rect);
      await open(tester, AppRoutes.video);
      final before = tester.getRect(pill);
      await tester.drag(pill, const Offset(-100, -100));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getRect(pill), before);
      expect(pill, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'narrow large-text layout stacks the docks above the bottom safe area',
    (tester) async {
      await render(tester, textScale: 2, viewport: const Size(320, 568));
      final pill = tester.getRect(find.byType(DeviceControlPill));
      final navigation = tester.getRect(find.byType(AppPrimaryTabNavigation));

      expect(pill.bottom, lessThanOrEqualTo(568 - 34 - 12));
      expect(navigation.bottom + 12, lessThanOrEqualTo(pill.top));
      expect(navigation.left, 24);
      expect(navigation.width, AppPrimaryTabNavigation.maxWidth);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'drag preserves device state, secondary position, then animates home and resets',
    (tester) async {
      session.setDeviceConnectionStatus(DeviceConnectionStatus.connected);
      control.updateState(DeviceSessionState.running);
      await render(tester);
      await open(tester, AppRoutes.profile);
      final pill = find.byType(DeviceControlPill);
      final dock = tester.getTopLeft(pill);
      await tester.drag(pill, const Offset(-100, -160));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final dragged = tester.getTopLeft(pill);
      expect(dragged.dx, lessThan(dock.dx));
      expect(dragged.dy, lessThan(dock.dy));
      expect(control.state.value, DeviceSessionState.running);
      await tester.tap(pill);
      await tester.pump();
      expect(control.state.value, DeviceSessionState.paused);
      await open(tester, extraDetail);
      expect(tester.getTopLeft(pill), dragged);
      Get.until((route) => route.settings.name == AppRoutes.home);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final moving = tester.getTopLeft(pill);
      expect(moving.dy, greaterThan(dragged.dy));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
      expect(floating.draggedPosition.value, isNull);
      expect(tester.getTopLeft(pill), floating.targetFor(tester.getSize(pill)));
      await open(tester, AppRoutes.profile);
      expect(tester.getTopLeft(pill), floating.targetFor(tester.getSize(pill)));
      expect(control.state.value, DeviceSessionState.paused);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dialogs and routes with hidden policy do not have a control above them',
    (tester) async {
      await render(tester);
      final context = tester.element(find.byType(AppScaffold));
      unawaited(
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(title: Text('Modal')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DeviceControlPill), findsNothing);
      Get.back<void>();
      await tester.pumpAndSettle();
      expect(find.byType(DeviceControlPill), findsOneWidget);
      for (final route in [AppRoutes.login, fullScreen]) {
        await open(tester, route);
        expect(find.byType(DeviceControlPill), findsNothing);
        Get.back<void>();
        await tester.pumpAndSettle();
        expect(find.byType(DeviceControlPill), findsOneWidget);
      }
    },
  );

  testWidgets('draggable default stays vertically centered after rotation', (
    tester,
  ) async {
    await render(tester);
    await open(tester, AppRoutes.profile);
    final pill = find.byType(DeviceControlPill);
    for (final viewport in [const Size(402, 874), const Size(874, 402)]) {
      tester.view.physicalSize = viewport;
      await tester.pumpAndSettle();
      expect(floating.draggedPosition.value, isNull);
      expect(
        tester.getRect(pill).center.dy,
        closeTo(floating.bodyBounds.value!.center.dy, .01),
      );
      final bounds = floating.bodyBounds.value!;
      final rect = tester.getRect(pill);
      expect(rect.top, greaterThanOrEqualTo(bounds.top));
      expect(rect.bottom, lessThanOrEqualTo(bounds.bottom));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'video controls and fullscreen pill remain usable across drag, modal and resize',
    (tester) async {
      final captureKey = GlobalKey();
      final previousPlatform = vp.VideoPlayerPlatform.instance;
      final videoPlatform = _VideoPreviewPlatform();
      vp.VideoPlayerPlatform.instance = videoPlatform;
      addTearDown(() => vp.VideoPlayerPlatform.instance = previousPlatform);
      final media = ValueNotifier(
        const VideoMedia(
          id: 'preview',
          title: 'Video preview',
          videoUrl: 'file:///video-preview.mp4',
        ),
      );
      addTearDown(media.dispose);
      await tester.runAsync(() async {
        final font = File(
          '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
        );
        await (FontLoader('VideoPreview')..addFont(
              Future.value(ByteData.sublistView(font.readAsBytesSync())),
            ))
            .load();
        final icons = File(
          '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
        );
        await (FontLoader('MaterialIcons')..addFont(
              Future.value(ByteData.sublistView(icons.readAsBytesSync())),
            ))
            .load();
      });
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(402, 847);
      tester.view.padding = const FakeViewPadding(top: 50, bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(top: 50, bottom: 34);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            fontFamily: 'VideoPreview',
          ),
          navigatorObservers: [
            FloatingControlObserver(
              policies: const {'/': FloatingControlPolicy.fixed},
              resetRoutes: const {},
            ),
          ],
          builder: (context, child) => RepaintBoundary(
            key: captureKey,
            child: FloatingDeviceControlOverlay(child: child!),
          ),
          home: ValueListenableBuilder<VideoMedia>(
            valueListenable: media,
            builder: (context, currentMedia, _) => Obx(
              () => AppScaffold(
                currentTab: AppTab.video,
                showBottomNavigation: !floating.mediaFullscreen.value,
                appBar: const PreferredSize(
                  preferredSize: Size.zero,
                  child: SizedBox.shrink(),
                ),
                body: VideoPlayerSurface(
                  // 使用真实纹理布局和受控平台帧，测试不连接网络或设备。
                  items: [currentMedia],
                  feedId: 'video-controls-audit',
                  active: false,
                  fullscreen: floating.mediaFullscreen.value,
                  onFullscreen: () => floating.mediaFullscreen.toggle(),
                  bottomPadding: 120,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final feed = tester.widget<VideoFeedView>(find.byType(VideoFeedView));
      await feed.onPlaybackProgress!(
        const VideoPlaybackProgressEvent(
          item: DefaultVideoItem(
            id: 'preview',
            videoUrl: 'preview.mp4',
            coverUrl: '',
          ),
          index: 0,
          position: Duration(seconds: 30),
          duration: Duration(minutes: 2),
          isPlaying: false,
        ),
      );
      await tester.pump();
      expect(find.byTooltip('Video list'), findsNothing);
      final seekTime = find.byKey(const ValueKey('video-seek-time'));
      expect(seekTime, findsNothing);
      expect(find.byTooltip('Play'), findsNothing);
      expect(find.byTooltip('Pause'), findsNothing);
      final slider = find.byType(Slider);
      final viewportRect = tester.getRect(find.byType(VideoPlayerSurface));
      final videoRect = tester
          .getRect(find.byKey(const ValueKey('video-test-frame')))
          .intersect(viewportRect);
      final sliderRect = tester.getRect(slider);
      final track = AppVideoStyle.playbackSliderTheme.trackShape!
          .getPreferredRect(
            parentBox: tester.renderObject<RenderBox>(slider),
            offset: sliderRect.topLeft,
            sliderTheme: AppVideoStyle.playbackSliderTheme,
          );
      expect(track.bottom, closeTo(videoRect.bottom, .01));
      expect(track.left, closeTo(videoRect.left, .01));
      expect(track.right, closeTo(videoRect.right, .01));
      expect(track.bottom, lessThan(viewportRect.bottom - 100));
      final playerState = tester.state(find.byType(VideoPlayerSurface));

      Future<void> capture(String name) async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/ui/$name.png');
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('video_controls_402x847_text1.0');
      final gesture = await tester.startGesture(
        Offset(sliderRect.width / 4, sliderRect.bottom - 12),
      );
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(seekTime, findsOneWidget);
      expect(tester.widget<Text>(seekTime).data, endsWith('/ 02:00'));
      expect(
        tester
            .getRect(seekTime)
            .overlaps(tester.getRect(find.byType(AppPrimaryTabNavigation))),
        isFalse,
      );
      expect(
        tester
            .getRect(seekTime)
            .overlaps(tester.getRect(find.byType(DeviceControlPill))),
        isFalse,
      );
      expect(tester.widget<Slider>(slider).value, greaterThan(30000));
      expect(tester.getRect(slider), sliderRect);
      await capture('video_controls_seeking_402x847_text1.0');
      await gesture.up();
      await tester.pumpAndSettle();
      expect(seekTime, findsNothing);
      expect(videoPlatform.position, greaterThan(const Duration(seconds: 30)));

      await tester.tap(find.byTooltip('Full screen'));
      await tester.pumpAndSettle();
      expect(tester.state(find.byType(VideoPlayerSurface)), same(playerState));
      final pill = find.byType(DeviceControlPill);
      expect(pill, findsOneWidget);
      expect(find.byType(AppPrimaryTabNavigation), findsNothing);
      final dock = tester.getRect(pill);
      expect(
        dock.center.dy,
        closeTo(floating.bodyBounds.value!.center.dy, .01),
      );
      expect(dock.bottom, lessThan(tester.getTopLeft(slider).dy));
      expect(tester.getRect(slider).bottom, closeTo(videoRect.bottom, .01));
      expect(seekTime, findsNothing);
      await capture('video_fullscreen_centered_402x847_text1.0');
      await tester.drag(pill, const Offset(-100, 160));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(pill).dx, lessThan(dock.left));
      expect(tester.getTopLeft(pill).dy, greaterThan(dock.top));
      expect(control.state.value, DeviceSessionState.idle);
      await capture('video_fullscreen_dragged_402x847_text1.0');

      unawaited(
        showDialog<void>(
          context: tester.element(find.byType(AppScaffold)),
          builder: (_) => const AlertDialog(title: Text('Modal')),
        ),
      );
      await tester.pumpAndSettle();
      expect(pill, findsNothing);
      Get.back<void>();
      await tester.pumpAndSettle();
      expect(pill, findsOneWidget);

      tester.view.physicalSize = const Size(847, 402);
      tester.view.padding = const FakeViewPadding(left: 34, bottom: 21);
      tester.view.viewPadding = const FakeViewPadding(left: 34, bottom: 21);
      await tester.pumpAndSettle();
      await tester.drag(pill, const Offset(2000, 2000));
      await tester.pumpAndSettle();
      expect(tester.getRect(pill).right, lessThanOrEqualTo(847));
      expect(tester.getRect(pill).bottom, lessThanOrEqualTo(402 - 21));
      await tester.drag(pill, const Offset(-200, -100));
      await tester.pumpAndSettle();
      await capture('video_fullscreen_847x402_text1.0');
      await tester.tap(find.byTooltip('Exit full screen'));
      await tester.pumpAndSettle();
      expect(floating.effectivePolicy, FloatingControlPolicy.fixed);
      final fixed = tester.getRect(pill);
      await tester.drag(pill, const Offset(-100, -100));
      await tester.pumpAndSettle();
      expect(tester.getRect(pill), fixed);
      expect(find.byType(AppPrimaryTabNavigation), findsOneWidget);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Full screen'));
      await tester.pumpAndSettle();
      expect(tester.getRect(pill).right, lessThanOrEqualTo(320));
      expect(tester.getRect(pill).bottom, lessThanOrEqualTo(568));
      await capture('video_fullscreen_320x568_text2.0');
      final largeTextDrag = await tester.startGesture(
        tester.getBottomLeft(slider) + const Offset(80, -12),
      );
      await largeTextDrag.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(seekTime, findsOneWidget);
      await capture('video_fullscreen_seeking_320x568_text2.0');
      await largeTextDrag.up();
      await tester.pumpAndSettle();
      expect(seekTime, findsNothing);
      tester.view.physicalSize = const Size(402, 847);
      tester.view.padding = const FakeViewPadding();
      tester.view.viewPadding = const FakeViewPadding();
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      floating.mediaFullscreen.value = false;
      for (final dimensions in [
        const Size(1080, 1920),
        const Size(1080, 1080),
      ]) {
        media.value = VideoMedia(
          id: 'preview',
          title: 'Video preview',
          videoUrl: 'file:///video-preview.mp4',
          width: dimensions.width.toInt(),
          height: dimensions.height.toInt(),
        );
        await tester.pumpAndSettle();
        final viewport = tester.getRect(find.byType(VideoPlayerSurface));
        final frame = tester
            .getRect(find.byKey(const ValueKey('video-test-frame')))
            .intersect(viewport);
        expect(tester.getRect(slider).bottom, closeTo(frame.bottom, .01));
        expect(tester.getRect(slider).left, closeTo(frame.left, .01));
        expect(tester.getRect(slider).right, closeTo(frame.right, .01));
        expect(frame.bottom, lessThan(viewport.bottom));
        await capture(
          'video_progress_${dimensions.width.toInt()}x${dimensions.height.toInt()}_402x847',
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'disconnected navigates, connected-idle activates session without navigating, connecting ignores clicks',
    (tester) async {
      await render(tester);
      await tester.tap(find.byType(DeviceControlPill));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, AppRoutes.home);
      expect(Get.key.currentState!.canPop(), isFalse);
      await open(tester, AppRoutes.profile);
      await tester.tap(find.byType(DeviceControlPill));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, AppRoutes.home);
      expect(Get.key.currentState!.canPop(), isFalse);
      session.setDeviceConnectionStatus(DeviceConnectionStatus.connecting);
      await tester.pump();
      await tester.tap(find.byType(DeviceControlPill));
      await tester.pump(const Duration(milliseconds: 200));
      expect(Get.currentRoute, AppRoutes.home);
      session.setDeviceConnectionStatus(DeviceConnectionStatus.connected);
      await tester.pump();
      expect(find.text('Tap to start'), findsOneWidget);
      await tester.tap(find.byType(DeviceControlPill));
      await tester.pumpAndSettle();
      expect(Get.currentRoute, AppRoutes.home);
      expect(control.state.value, DeviceSessionState.running);
    },
  );

  testWidgets(
    'keyboard, resize, large text and drag boundaries remain inside measured body',
    (tester) async {
      await render(tester, textScale: 2, viewport: const Size(320, 568));
      await open(tester, AppRoutes.profile);
      final pill = find.byType(DeviceControlPill);
      await tester.drag(pill, const Offset(-1000, -1000));
      await tester.pump();
      var rect = tester.getRect(pill);
      expect(rect.left, greaterThanOrEqualTo(floating.bodyBounds.value!.left));
      expect(rect.top, greaterThanOrEqualTo(floating.bodyBounds.value!.top));
      tester.view.viewInsets = const FakeViewPadding(bottom: 170);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      rect = tester.getRect(pill);
      expect(rect.bottom, lessThanOrEqualTo(398));
      tester.view.viewInsets = const FakeViewPadding();
      tester.view.physicalSize = const Size(874, 402);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      rect = tester.getRect(pill);
      expect(rect.right, lessThanOrEqualTo(floating.bodyBounds.value!.right));
      expect(rect.bottom, lessThanOrEqualTo(floating.bodyBounds.value!.bottom));
      expect(tester.takeException(), isNull);
    },
  );
}

/// 只替代原生解码和纹理，保留插件自身的布局、尺寸回退与 seek 调用链。
final class _VideoPreviewPlatform extends vp.VideoPlayerPlatform {
  Duration position = const Duration(seconds: 30);

  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(vp.VideoCreationOptions options) async => 1;
  @override
  Stream<vp.VideoEvent> videoEventsFor(int playerId) => Stream.value(
    vp.VideoEvent(
      eventType: vp.VideoEventType.initialized,
      duration: const Duration(minutes: 2),
      size: const Size(1920, 1080),
    ),
  );
  @override
  Widget buildViewWithOptions(vp.VideoViewOptions options) => const ColoredBox(
    key: ValueKey('video-test-frame'),
    color: Color(0xFF164B6A),
  );
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> dispose(int playerId) async {}
  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Future<void> seekTo(int playerId, Duration target) async {
    position = target;
  }
}
