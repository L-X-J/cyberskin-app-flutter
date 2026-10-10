import 'package:cyberskin_app/app/cyberskin_app.dart';
import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/app/widgets/app_primary_tab_navigation.dart';
import 'package:cyberskin_app/features/content/data/content_configuration_cache.dart';
import 'package:cyberskin_app/features/content/domain/entities/app_content.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// 根组件测试使用的内存配置缓存。
final class _TestContentCache implements ContentConfigurationCache {
  /// 创建带当天刷新时间的缓存，使初始化页可以立即进入设备页。
  _TestContentCache()
    : configuration = AppConfiguration(
        agreements: const <AppAgreement>[],
        features: const AppFeatureFlags(),
      ),
      lastRefreshAt = DateTime.now(),
      lastLaunchAt = DateTime.now();

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

void main() {
  testWidgets(
    'starts on the anonymous home route and switches content to video',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        CyberskinApp(contentConfigurationCache: _TestContentCache()),
      );
      // 初始化页包含无限循环背景，持续推进到设备页切换完成即可，不能等待静止。
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Add Device'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      Get.find<SessionController>().setDeviceConnectionStatus(
        DeviceConnectionStatus.connected,
      );
      await tester.pump();
      await tester.tap(find.text('Video'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Official'), findsOneWidget);
      expect(find.text('Browser'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      expect(find.byType(AppPrimaryTabNavigation), findsOneWidget);

      await tester.tap(find.text('Browser'));
      await tester.pump();
      expect(find.text('Please enter the link'), findsOneWidget);
      expect(find.byType(AppPrimaryTabNavigation), findsOneWidget);

      await tester.tap(find.text('Local'));
      await tester.pump();
      expect(find.text('Select local video'), findsOneWidget);
      expect(find.byType(AppPrimaryTabNavigation), findsOneWidget);

      await tester.tap(find.text('Device'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('My device'), findsOneWidget);
      expect(find.byType(AppPrimaryTabNavigation), findsOneWidget);
    },
  );
}
