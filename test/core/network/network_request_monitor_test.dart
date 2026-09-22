import 'package:cyberskin_app/core/network/network_request_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'tracks concurrent requests and keeps bounded metadata-only history',
    () {
      final monitor = NetworkRequestMonitor(historyLimit: 1);
      final first = monitor.start(
        operation: 'first',
        method: 'GET',
        path: '/one',
      );
      final second = monitor.start(
        operation: 'second',
        method: 'POST',
        path: '/two',
      );

      expect(monitor.activeRequestCount.value, 2);

      monitor.finish(first, httpStatus: 200, businessCode: 200);
      monitor.finish(
        second,
        httpStatus: 500,
        businessCode: 500,
        errorMessage: 'Rejected',
      );

      expect(monitor.activeRequestCount.value, 0);
      expect(monitor.history, hasLength(1));
      expect(monitor.history.single.operation, 'second');
      expect(monitor.history.single.errorMessage, 'Rejected');
      expect(monitor.history.single.path, '/two');
    },
  );
}
