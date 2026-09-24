import 'package:cyberskin_app/app/app_route_logger.dart';
import 'package:cyberskin_app/core/logging/app_log.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final class _RecordingLog implements AppLog {
  String? previous;
  String? current;
  bool? isBack;
  int routeCount = 0;

  @override
  bool get apiLoggingEnabled => false;

  @override
  void apiExchange({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, Object?> queryParameters = const <String, Object?>{},
    Object? body,
    required int? statusCode,
    required Duration duration,
    Object? response,
    Object? error,
    bool isFileTransfer = false,
  }) {}

  @override
  Future<void> close() async {}

  @override
  void debug(String message, {Object? data}) {}

  @override
  void error(
    String message, {
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {}

  @override
  void info(String message, {Object? data}) {}

  @override
  void route({
    required String previous,
    required String current,
    required bool isBack,
    String? removed,
    String? routeType,
  }) {
    routeCount++;
    this.previous = previous;
    this.current = current;
    this.isBack = isBack;
  }

  @override
  void warning(String message, {Object? data, Object? error}) {}
}

void main() {
  test('记录页面前后路由和返回方向', () {
    final log = _RecordingLog();

    AppRouteLogger.record(
      log,
      Routing(previous: '/device', current: '/profile', isBack: false),
    );
    AppRouteLogger.record(log, null);

    expect(log.routeCount, 1);
    expect(log.previous, '/device');
    expect(log.current, '/profile');
    expect(log.isBack, isFalse);
  });

  test('不把弹窗当作页面路由记录', () {
    final log = _RecordingLog();

    AppRouteLogger.record(log, Routing(current: '/profile', isDialog: true));

    expect(log.routeCount, 0);
  });
}
