import 'package:cyberskin_app/app/app_routes.dart';
import 'package:cyberskin_app/features/device/presentation/device_manual_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

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

  test('declares editor route result as an accepted value type', () {
    // 编辑页以 Get.back(result: true/false) 回传结果。Get 的全局路由树以
    // List<GetPage> 保存页面并在匹配时 copy() 成 GetPage<dynamic>，
    // 所以这里声明的泛型只表达意图，不能使调用侧依赖 Get.toNamed<bool>。
    final editPage = AppRoutes.pages.firstWhere(
      (page) => page.name == AppRoutes.rhythmEdit,
    );

    expect(editPage, isA<GetPage<bool>>());
  });

  testWidgets('pushing the editor route dispatches a Route<dynamic>', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(home: const SizedBox.shrink(), getPages: AppRoutes.pages),
    );
    await tester.pumpAndSettle();

    // 即使 AppRoutes.rhythmEdit 声明为 GetPage<bool>，Get 在分派前会把页面
    // 重包为 GetPage<dynamic>，最终派发 Route<dynamic>。调用侧因此不能用
    // Get.toNamed<bool>，否则 Navigator.pushNamed<bool> 的
    // `route as Route<bool?>?` 会抛 TypeError。
    final navigator = Get.key.currentState!;
    expect(
      () => navigator.pushNamed<bool>(AppRoutes.rhythmEdit),
      throwsA(isA<TypeError>()),
    );

    final route = navigator.pushNamed<dynamic>(AppRoutes.rhythmEdit);
    expect(tester.takeException(), isNull);
    expect(route, isNotNull);
    expect(Get.key.currentState!.canPop(), isTrue);
  });
}
