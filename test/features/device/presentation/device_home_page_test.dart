import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/core/theme/app_theme.dart';
import 'package:cyberskin_app/core/widgets/app_img_group_80_card.dart';
import 'package:cyberskin_app/core/widgets/app_layered_gradient_card.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/device/domain/device_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_home_controller.dart';
import 'package:cyberskin_app/features/device/presentation/device_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final class _FakeDeviceRepository implements DeviceRepository {
  _FakeDeviceRepository(this.result);

  final Result<List<Device>> result;

  @override
  Future<Result<List<Device>>> loadDevices() async => result;
}

Device _device({String model = '389'}) => Device(
  id: 'device-1',
  model: model,
  name: 'Cyberskin Air',
  status: DeviceConnectionStatus.connected,
  capabilities: DeviceCapabilities(channels: const <ChannelCapability>[]),
  batteryPercent: 67,
  cardColor: '#5E185F',
  tags: 'Connected, Ready',
);

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('renders the connected device hierarchy from model fields', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final font = File(
        '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
      );
      if (font.existsSync()) {
        final loader = FontLoader('DeviceHomePreview')
          ..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          );
        await loader.load();
      }
      final icons = File(
        '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (icons.existsSync()) {
        final loader = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(ByteData.sublistView(await icons.readAsBytes())),
          );
        await loader.load();
      }
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(402, 949);
    tester.view.padding = const FakeViewPadding(top: 50, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 50, bottom: 34);
    addTearDown(tester.view.reset);
    final controller = DeviceHomeController(
      _FakeDeviceRepository(Result.ok(<Device>[_device()])),
    );
    Get.put<DeviceHomeController>(controller);
    await controller.load();

    const captureKey = ValueKey('device-home-capture');
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark().copyWith(
          textTheme: AppTheme.dark().textTheme.apply(
            fontFamily: 'DeviceHomePreview',
          ),
        ),
        home: const RepaintBoundary(key: captureKey, child: DeviceHomePage()),
      ),
    );
    await tester.pump();

    await tester.runAsync(() async {
      final context = tester.element(find.byType(DeviceHomePage));
      await Future.wait([
        precacheImage(
          const AssetImage('assets/images/home/go_user_profile.png'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/home/device_pro_connected.png'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/home/training_thumb.png'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/home/banner_device.png'),
          context,
        ),
      ]);
    });
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      MediaQuery.viewPaddingOf(tester.element(find.byType(DeviceHomePage))).top,
      50,
    );
    expect(
      tester.getTopLeft(find.text('My device')).dy,
      greaterThanOrEqualTo(84),
    );

    expect(find.text('My device'), findsOneWidget);
    expect(find.text('Cyberskin Air'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('Product manual'), findsOneWidget);
    expect(find.text('Free control\nmode'), findsOneWidget);
    expect(find.text('Customrhythm'), findsOneWidget);
    expect(find.text('Training mode'), findsOneWidget);
    expect(find.text('New product launch'), findsOneWidget);
    expect(find.byType(AppLayeredGradientCard), findsNWidgets(3));
    expect(find.byType(AppImgGroup80Card), findsNWidgets(2));
    expect(find.byType(AppBar), findsNothing);

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = Directory('build/ui')..createSync(recursive: true);
        File('${output.path}/device_home_402x949_text1.0.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
  });

  testWidgets('keeps empty and error states functional', (tester) async {
    final emptyController = DeviceHomeController(
      _FakeDeviceRepository(const Result.ok(<Device>[])),
    );
    Get.put<DeviceHomeController>(emptyController);
    await emptyController.load();

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark(), home: const DeviceHomePage()),
    );
    await tester.pump();
    expect(find.text('No devices yet'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    Get.reset();
    final errorController = DeviceHomeController(
      _FakeDeviceRepository(
        const Result.failure(
          AppFailure(code: FailureCode.network, message: 'Network unavailable'),
        ),
      ),
    );
    Get.put<DeviceHomeController>(errorController);
    await errorController.load();

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.dark(), home: const DeviceHomePage()),
    );
    await tester.pump();
    expect(find.text('Network unavailable'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
