import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/core/theme/app_theme.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_manual_controller.dart';
import 'package:cyberskin_app/features/device/presentation/device_manual_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final class _FakeDeviceCatalogRepository implements DeviceCatalogRepository {
  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() async =>
      const Result.ok(<DeviceModelSummary>[]);

  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) async =>
      throw UnimplementedError();

  @override
  Future<Result<DeviceManual>> getManual(int id) async => Result.ok(
    DeviceManual(
      deviceModelId: id,
      items: <DeviceManualItem>[
        DeviceManualItem(
          tab: 'Overview',
          contentHtml:
              '<h2>Introducing the Premium Male Masturbation Cup</h2>'
              '<p>Introducing the Premium Male Masturbation Cup, a high-quality '
              'personal care product designed exclusively for adult men. Crafted from '
              'medical-grade TPE material, this product is safe, non-toxic, and '
              'skin-friendly, having passed multiple international safety '
              'certifications including SGS.</p>',
        ),
        DeviceManualItem(
          tab: 'Care',
          contentHtml: '<p>Clean after each use.</p>',
        ),
        DeviceManualItem(
          tab: 'Wash',
          contentHtml: '<p>Rinse the device with warm water.</p>',
        ),
      ],
    ),
  );
}

void main() {
  tearDown(Get.reset);

  testWidgets('renders ordered tabs and switches readable content', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      final font = File(
        '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
      );
      if (font.existsSync()) {
        final loader = FontLoader('DeviceManualPreview')
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
    tester.view.physicalSize = const Size(402, 1042);
    tester.view.padding = const FakeViewPadding(top: 50, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 50, bottom: 34);
    addTearDown(tester.view.reset);
    final controller = DeviceManualController(
      _FakeDeviceCatalogRepository(),
      modelId: 389,
      productName: 'Cyberskin Air',
    );
    await controller.load();
    Get.put<DeviceManualController>(controller);
    const captureKey = ValueKey('device-manual-capture');

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark().copyWith(
          textTheme: AppTheme.dark().textTheme.apply(
            fontFamily: 'DeviceManualPreview',
          ),
        ),
        home: const MediaQuery(
          data: MediaQueryData(
            padding: EdgeInsets.only(top: 50, bottom: 34),
            viewPadding: EdgeInsets.only(top: 50, bottom: 34),
          ),
          child: RepaintBoundary(key: captureKey, child: DeviceManualPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final context = tester.element(find.byType(DeviceManualPage));
      await Future.wait([
        precacheImage(
          const AssetImage('assets/images/home/device_pro_connected_alt.png'),
          context,
        ),
        precacheImage(
          const AssetImage('assets/images/home/device_air_banner.png'),
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
      MediaQuery.viewPaddingOf(tester.element(find.byType(DeviceManualPage)))
          .top,
      50,
    );
    expect(
      tester.getTopLeft(find.text('Cyberskin Air')).dy,
      greaterThanOrEqualTo(132),
    );

    expect(find.text('Cyberskin Air'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('Care'), findsWidgets);
    expect(find.text('Wash'), findsWidgets);
    expect(
      find.text('Introducing the Premium Male Masturbation Cup'),
      findsOneWidget,
    );
    expect(find.text('Clean after each use.'), findsNothing);

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final output = Directory('build/ui')..createSync(recursive: true);
        File('${output.path}/device_manual_402x1042_text1.0.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });

    await tester.tap(find.text('Care').last);
    await tester.pump();

    expect(find.text('Clean after each use.'), findsOneWidget);
    expect(
      find.text('Introducing the Premium Male Masturbation Cup'),
      findsNothing,
    );
  });
}
