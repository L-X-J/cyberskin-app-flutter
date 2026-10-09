import 'package:cyberskin_app/features/control/domain/device_quick_control.dart';
import 'package:cyberskin_app/features/control/domain/device_session.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all disconnected/error states override stale running sessions', () {
    for (final connection in DeviceConnectionStatus.values) {
      if ({
        DeviceConnectionStatus.connected,
        DeviceConnectionStatus.connecting,
        DeviceConnectionStatus.lowBattery,
      }.contains(connection)) {
        continue;
      }
      for (final session in DeviceSessionState.values) {
        expect(
          resolveQuickControlState(connection, session),
          DeviceQuickControlState.disconnected,
        );
      }
    }
  });

  test('connection and session connecting states block activation', () {
    for (final session in DeviceSessionState.values) {
      expect(
        resolveQuickControlState(DeviceConnectionStatus.connecting, session),
        DeviceQuickControlState.connecting,
      );
    }
    expect(
      resolveQuickControlState(
        DeviceConnectionStatus.connected,
        DeviceSessionState.connecting,
      ),
      DeviceQuickControlState.connecting,
    );
  });

  test('low battery only replaces the running subtitle state', () {
    expect(
      resolveQuickControlState(
        DeviceConnectionStatus.connected,
        DeviceSessionState.running,
      ),
      DeviceQuickControlState.running,
    );
    expect(
      resolveQuickControlState(
        DeviceConnectionStatus.lowBattery,
        DeviceSessionState.running,
      ),
      DeviceQuickControlState.runningLowBattery,
    );
    for (final session in [
      DeviceSessionState.paused,
      DeviceSessionState.idle,
    ]) {
      expect(
        resolveQuickControlState(DeviceConnectionStatus.connected, session),
        DeviceQuickControlState.paused,
      );
      expect(
        resolveQuickControlState(DeviceConnectionStatus.lowBattery, session),
        DeviceQuickControlState.paused,
      );
    }
  });
}
