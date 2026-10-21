import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/control/domain/device_command_repository.dart';
import 'package:cyberskin_app/features/control/domain/device_session.dart';
import 'package:cyberskin_app/features/control/presentation/control_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

final class _RecordingCommandRepository implements DeviceCommandRepository {
  final List<String> sent = <String>[];

  @override
  Future<Result<void>> send(
    String command, {
    int? modelId,
    String? remoteId,
  }) async {
    sent.add(command);
    return const Result.ok(null);
  }
}

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

  test('activateQuickControl sends resume command from idle and updates to running', () async {
    final commands = _RecordingCommandRepository();
    final controller = ControlSessionController(commandRepository: commands);

    expect(controller.state.value, DeviceSessionState.idle);
    await controller.activateQuickControl();

    expect(controller.state.value, DeviceSessionState.running);
    expect(commands.sent, ['t:c|v:c']);
  });

  test('activateQuickControl sends pause command from running and updates to paused', () async {
    final commands = _RecordingCommandRepository();
    final controller = ControlSessionController(commandRepository: commands);

    controller.updateState(DeviceSessionState.running);
    await controller.activateQuickControl();

    expect(controller.state.value, DeviceSessionState.paused);
    expect(commands.sent, ['t:s|v:s']);
  });

  test('activateQuickControl resumes from paused', () async {
    final commands = _RecordingCommandRepository();
    final controller = ControlSessionController(commandRepository: commands);

    controller.updateState(DeviceSessionState.paused);
    await controller.activateQuickControl();

    expect(controller.state.value, DeviceSessionState.running);
    expect(commands.sent, ['t:c|v:c']);
  });
}
