import 'package:cyberskin_app/app/app_routes.dart';
import 'package:cyberskin_app/features/device/presentation/device_detail_page.dart';
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

    final deviceDetailPage = AppRoutes.pages.firstWhere(
      (page) => page.name == AppRoutes.deviceDetail,
    );
    expect(deviceDetailPage.customTransition, isNotNull);
    expect(
      deviceDetailPage.transitionDuration,
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

  test('uses one page for device detail and manual routes', () {
    final detailPage = AppRoutes.pages.firstWhere(
      (page) => page.name == AppRoutes.deviceDetail,
    );
    final manualPage = AppRoutes.pages.firstWhere(
      (page) => page.name == AppRoutes.deviceManual,
    );

    expect(detailPage.page(), isA<DeviceDetailPage>());
    expect(manualPage.page(), isA<DeviceDetailPage>());
  });
}
