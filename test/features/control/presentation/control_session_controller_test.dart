import 'package:cyberskin_app/features/control/domain/device_session.dart';
import 'package:cyberskin_app/features/control/presentation/control_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toggles only between running and paused states', () {
    final controller = ControlSessionController();

    controller.togglePause();
    expect(controller.state.value, DeviceSessionState.idle);

    controller.updateState(DeviceSessionState.running);
    controller.togglePause();
    expect(controller.state.value, DeviceSessionState.paused);

    controller.togglePause();
    expect(controller.state.value, DeviceSessionState.running);
  });
}
