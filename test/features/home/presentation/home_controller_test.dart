import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/features/device/domain/device.dart';
import 'package:cyberskin_app/features/home/presentation/home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses disconnected as the default device state', () {
    final controller = HomeController(SessionController());

    expect(controller.deviceStatus.value, DeviceConnectionStatus.disconnected);
  });
}
