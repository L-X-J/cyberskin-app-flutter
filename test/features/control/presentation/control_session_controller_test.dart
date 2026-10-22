import 'dart:async';

import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/control/domain/device_command_repository.dart';
import 'package:cyberskin_app/features/control/domain/device_session.dart';
import 'package:cyberskin_app/features/control/presentation/control_session_controller.dart';
import 'package:cyberskin_app/features/device/domain/device_capability.dart';
import 'package:cyberskin_app/features/rhythm/domain/services/rhythm_playback.dart';
import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/ble_control_fixture.dart';
import '../../rhythm/presentation/rhythm_info_test.dart' as rhythm_fixture;

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
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'same stopped frames correct optimistic running after snapshot commit',
    () async {
      final f = BleControlFixture();
      addTearDown(f.dispose);
      final observed = <BleRuntimeStatus?>[];
      final subscription = f.coordinator.rhythmHeartbeats.listen((_) {
        observed.add(f.coordinator.runtime['a']);
        expect(
          f.coordinator.connectedDevice.value!.motorPower.value,
          f.coordinator.runtime['a']!.motorPower,
        );
      });
      addTearDown(subscription.cancel);
      f.emit(stoppedStatus);
      expect(f.control.state.value, DeviceSessionState.idle);
      for (var i = 0; i < 3; i++) {
        await f.control.activateQuickControl();
        expect(f.control.state.value, DeviceSessionState.running);
        f.emit(stoppedStatus); // 连同同一快照实例也必须逐帧通知。
        expect(f.control.state.value, DeviceSessionState.paused);
      }
      expect(observed.length, 4);
      expect(
        observed.every((status) => identical(status, stoppedStatus)),
        isTrue,
      );
    },
  );

  test('current outputs, not history or heat, decide manual running', () {
    final f = BleControlFixture();
    addTearDown(f.dispose);
    for (final status in [
      stoppedStatus.copyWith(motorPower: 30),
      stoppedStatus.copyWith(vibrateMotorPower: 80),
      stoppedStatus.copyWith(suckState: 2),
      stoppedStatus.copyWith(suckState: 3),
    ]) {
      f.emit(status);
      expect(f.control.state.value, DeviceSessionState.running);
      f.emit(stoppedStatus.copyWith(heatState: 1));
      expect(f.control.state.value, DeviceSessionState.paused);
    }
  });

  test('unknown supported outputs cannot confirm stopped; absent ones do not block', () {
    final f = BleControlFixture(
      channels: [DeviceChannel.vibration, DeviceChannel.suck],
    );
    addTearDown(f.dispose);
    f.control.updateState(DeviceSessionState.running);
    f.emit(stoppedStatus);
    expect(f.control.state.value, DeviceSessionState.running);
    f.emit(stoppedStatus.copyWith(motorPower: -1, suckState: 1));
    expect(f.control.state.value, DeviceSessionState.paused);
    f.control.updateState(DeviceSessionState.running);
    f.emit(stoppedStatus.copyWith(vibrateMotorPower: -1, suckState: 1));
    expect(f.control.state.value, DeviceSessionState.running);
    f.emit(const BleRuntimeStatus());
    expect(f.control.state.value, DeviceSessionState.running);
  });

  test(
    'foreign frames and late frames after disconnect cannot change session',
    () async {
      final f = BleControlFixture();
      addTearDown(f.dispose);
      await f.control.activateQuickControl();
      f.emit(stoppedStatus, remoteId: 'other');
      expect(f.control.state.value, DeviceSessionState.running);
      f.coordinator.handleEventForTesting(
        const BleConnectionChanged(
          remoteId: 'a',
          state: BleConnectionState.disconnected,
        ),
      );
      expect(f.control.state.value, DeviceSessionState.idle);
      f.emit(stoppedStatus.copyWith(motorPower: 30));
      expect(f.control.state.value, DeviceSessionState.idle);
    },
  );

  test(
    'failed quick commands roll back unless newer telemetry supersedes them',
    () async {
      final f = BleControlFixture();
      addTearDown(f.dispose);
      f.commands.result = commandFailure;
      await f.control.activateQuickControl();
      expect(f.control.state.value, DeviceSessionState.idle);
      f.control.updateState(DeviceSessionState.running);
      await f.control.activateQuickControl();
      expect(f.control.state.value, DeviceSessionState.running);
      f.commands.pending = Completer<Result<void>>();
      final pause = f.control.activateQuickControl();
      f.emit(stoppedStatus);
      f.commands.pending!.complete(commandFailure);
      await pause;
      expect(f.control.state.value, DeviceSessionState.paused);
      f.commands.pending = Completer<Result<void>>();
      final resume = f.control.activateQuickControl();
      f.emit(stoppedStatus.copyWith(motorPower: 30));
      f.commands.pending!.complete(commandFailure);
      await resume;
      expect(f.control.state.value, DeviceSessionState.running);
    },
  );

  test('complete frame handoff avoids transient stop and closed controller unsubscribes', () {
    final f = BleControlFixture(initialize: false);
    addTearDown(f.coordinator.onClose);
    f.emit(stoppedStatus.copyWith(motorPower: 30));
    f.control.onInit();
    expect(f.control.state.value, DeviceSessionState.running);
    final changes = <DeviceSessionState>[];
    final subscription = f.control.state.listen(changes.add);
    addTearDown(subscription.cancel);
    // 同一帧从伸缩转为震动，不能因逐字段先写伸缩 0 而产生中间 Paused。
    f.emit(stoppedStatus.copyWith(vibrateMotorPower: 80));
    expect(f.control.state.value, DeviceSessionState.running);
    expect(changes, isEmpty);
    f.control.onClose();
    f.emit(stoppedStatus);
    expect(f.control.state.value, DeviceSessionState.running);
  });

  test(
    'late command failure cannot overwrite a later command or disconnect',
    () async {
      final f = BleControlFixture();
      addTearDown(f.dispose);
      final pending = Completer<Result<void>>();
      f.commands.pending = pending;
      final resume = f.control.activateQuickControl();
      f.commands.pending = null;
      await f.control.activateQuickControl();
      pending.complete(commandFailure);
      await resume;
      expect(f.control.state.value, DeviceSessionState.paused);
      f.control.updateState(DeviceSessionState.running);
      f.commands.pending = Completer<Result<void>>();
      final pause = f.control.activateQuickControl();
      f.coordinator.handleEventForTesting(
        const BleConnectionChanged(
          remoteId: 'a',
          state: BleConnectionState.disconnected,
        ),
      );
      f.commands.pending!.complete(commandFailure);
      await pause;
      expect(f.control.state.value, DeviceSessionState.idle);
    },
  );

  test('running rhythm rest, paused rhythm and editing retain priority over telemetry', () async {
    final port = rhythm_fixture.Port();
    final playback = RhythmPlayback(port);
    final f = BleControlFixture(rhythm: playback);
    addTearDown(() async {
      f.dispose();
      await playback.dispose();
      await port.eventsController.close();
    });
    expect(
      await playback.start(rhythm_fixture.fixture(1), rhythm_fixture.caps),
      isTrue,
    );
    f.emit(stoppedStatus);
    expect(f.control.state.value, DeviceSessionState.running);
    await playback.pause();
    await Future<void>.delayed(Duration.zero);
    f.emit(stoppedStatus.copyWith(motorPower: 30));
    expect(f.control.state.value, DeviceSessionState.paused);
    await playback.stop();
    await playback.beginEditing(rhythm_fixture.caps);
    f.emit(stoppedStatus.copyWith(motorPower: 30));
    expect(f.control.state.value, DeviceSessionState.paused);
    playback.finishEditing();
    f.emit(stoppedStatus.copyWith(motorPower: 30));
    expect(f.control.state.value, DeviceSessionState.running);
  });

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
