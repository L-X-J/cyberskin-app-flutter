import 'package:cyberskin_app/app/app_routes.dart';
import 'package:cyberskin_app/features/device/presentation/device_manual_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the custom init exit transition', () {
    final initPage = AppRoutes.pages.firstWhere(
      (page) => page.name == AppRoutes.init,
    );

    expect(initPage.customTransition, isNotNull);
    expect(initPage.transitionDuration, const Duration(milliseconds: 420));

    final devicePage = AppRoutes.pages.firstWhere(
      (page) => page.name == AppRoutes.device,
    );
    expect(devicePage.customTransition, isNotNull);
    expect(devicePage.transitionDuration, const Duration(milliseconds: 1200));

    final deviceManualPage = AppRoutes.pages.firstWhere(
      (page) => page.name == AppRoutes.deviceManual,
    );
    expect(deviceManualPage.customTransition, isNotNull);
    expect(
      deviceManualPage.transitionDuration,
      const Duration(milliseconds: 520),
    );
  });

  test('keeps email login in the login route', () {
    expect(
      AppRoutes.pages.where((page) => page.name == AppRoutes.login),
      hasLength(1),
    );
    expect(
      AppRoutes.pages.map((page) => page.name),
      isNot(contains('/login/email')),
    );
  });

  test('uses DeviceManualPage for the manual route', () {
    final manualPage = AppRoutes.pages.firstWhere(
      (page) => page.name == AppRoutes.deviceManual,
    );

    expect(manualPage.page(), isA<DeviceManualPage>());
  });

  test('identifies routes requiring connected device', () {
    expect(AppRoutes.requiresConnectedDevice(AppRoutes.freeControl), isTrue);
    expect(AppRoutes.requiresConnectedDevice(AppRoutes.device), isTrue);
    expect(AppRoutes.requiresConnectedDevice('/control/custom_rhythm'), isTrue);

    expect(AppRoutes.requiresConnectedDevice(AppRoutes.home), isFalse);
    expect(AppRoutes.requiresConnectedDevice(AppRoutes.profile), isFalse);
    expect(AppRoutes.requiresConnectedDevice(AppRoutes.video), isFalse);
    expect(AppRoutes.requiresConnectedDevice(AppRoutes.login), isFalse);
    expect(AppRoutes.requiresConnectedDevice(null), isFalse);
  });
}
