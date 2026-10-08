import 'package:cyberskin_app/app/cyberskin_app.dart';
import 'package:cyberskin_app/features/content/data/content_configuration_cache.dart';
import 'package:cyberskin_app/features/content/domain/entities/app_content.dart';
import 'package:flutter_test/flutter_test.dart';

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
  testWidgets('starts on the anonymous home route and navigates to video', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      CyberskinApp(contentConfigurationCache: _TestContentCache()),
    );
    // 初始化页包含无限循环背景，持续推进到设备页切换完成即可，不能等待静止。
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Home'), findsWidgets);
    expect(find.text('No device connected'), findsOneWidget);
    expect(find.text('Video'), findsOneWidget);

    await tester.tap(find.text('Video'));
    await tester.pumpAndSettle();

    expect(find.text('Video experiences'), findsOneWidget);
    expect(
      find.text(
        'Official, browser, and local video sources will be configured here.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('No device connected'), findsOneWidget);
  });
}
