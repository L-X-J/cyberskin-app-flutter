// 自由控制页面控制器：负责加载设备详情中的动态布局配置、维持控制状态与会话生命周期。

import 'dart:async';

import 'package:get/get.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/logging/app_log.dart';
import '../../../../core/protocol/common_business_command.dart';
import '../../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../../../device/domain/connected_device_state.dart';
import '../../../device/domain/repositories/device_catalog_repository.dart';
import '../../domain/device_command_repository.dart';
import '../../domain/device_session.dart';
import '../../presentation/control_session_controller.dart';
import '../domain/entities/free_control_layout.dart';
import '../domain/free_control_command_mapper.dart';

final class FreeControlController extends GetxController {
  FreeControlController({
    required this.catalogRepository,
    required this.bleCoordinator,
    required this.sessionController,
    required this.commandRepository,
    this.log = const NoopAppLog(),
  });

  final DeviceCatalogRepository catalogRepository;
  final CyberskinBleRuntimeCoordinator bleCoordinator;
  final ControlSessionController sessionController;

  /// 语义指令下发入口；控制器只产出 `t/v/s/h` 语义命令，不接触 BLE 帧。
  final DeviceCommandRepository commandRepository;

  /// 指令下发失败时记录可恢复警告。
  final AppLog log;

  Worker? _deviceWorker;
  Worker? _connectionWorker;

  /// 待下发指令，按通道键保留最新一条；LinkedHashMap 保证跨通道 FIFO。
  final Map<String, CommonBusinessCommand> _pendingCommands =
      <String, CommonBusinessCommand>{};

  /// 是否已有串行下发循环在运行。
  bool _draining = false;

  /// 当前动态布局配置
  final Rx<FreeControlLayout?> layout = Rx<FreeControlLayout?>(null);

  /// 当前选中的预设样式索引 (1-5)
  final RxInt currentPreset = 1.obs;

  /// 加载中状态
  final RxBool isLoading = true.obs;

  /// 错误提示
  final Rx<String?> errorMessage = Rx<String?>(null);

  /// 当前连接的设备状态（如果有）
  ConnectedDeviceState? get connectedDevice =>
      bleCoordinator.connectedDevice.value;

  /// 设备名称
  String get deviceName {
    final connected = connectedDevice;
    if (connected != null && connected.device.name.isNotEmpty) {
      return connected.device.name;
    }
    return 'Cyberskin Pro';
  }

  /// 设备连接状态提示文案
  String get connectionStatusText =>
      connectedDevice != null ? 'Connected' : 'Disconnected';

  // ── 设备遥测（在 Obx 内读取时自动订阅对应 Rx 字段） ────────────────────────

  /// 设备上报的加热是否开启；未上报（-1）按关闭处理。
  bool get heatOn => connectedDevice?.heatState.value == 1;

  /// 设备上报的吮吸原始状态：-1=未知，1=待机，2=吸气，3=放气。
  int get suckState => connectedDevice?.suckState.value ?? -1;

  /// 吮吸是否处于运行中（吸气或放气）；待机与未知都视为未开启。
  bool get suckOn => suckState == 2 || suckState == 3;

  /// 伸缩/震动通道上报的逻辑强度 0–100；未上报或其他通道返回 `null`。
  int? reportedPercent(FreeControlComponentType type) {
    final power = switch (type) {
      FreeControlComponentType.telescopic => connectedDevice?.motorPower.value,
      FreeControlComponentType.vibration =>
        connectedDevice?.vibrateMotorPower.value,
      _ => null,
    };
    return power == null || power < 0 ? null : power;
  }

  /// 由上报强度反算的分档档位；从未上报过任何功率时返回 `null`。
  ///
  /// 设备停止（功率 0）时返回 0（空档），与 [SteppedCapsuleControl] 支持 gear=0 对齐；
  /// 尚未上报过（power=-1 / null）时返回 null，让控件保留上次用户操作的档位。
  int? reportedGear(FreeControlComponentConfig config) {
    final device = connectedDevice;
    final current = switch (config.type) {
      FreeControlComponentType.telescopic => device?.motorPower.value,
      FreeControlComponentType.vibration => device?.vibrateMotorPower.value,
      _ => null,
    };
    // 未上报（null 或 -1）：返回 null，控件保留当前显示值。
    if (current == null || current < 0) return null;
    // 停止（功率 0）：返回 0，控件归零。
    if (current == 0) return 0;
    return FreeControlCommandMapper.gearFromPercent(config, current);
  }

  // ── 用户操作 → 语义指令 ───────────────────────────────────────────────────

  /// 无级变速滑杆调节伸缩/震动逻辑强度。
  void onIntensityChanged(FreeControlComponentType type, int percent) =>
      _enqueue(FreeControlCommandMapper.intensity(type, percent));

  /// 分档控件选中第 [gear] 档。
  void onGearSelected(FreeControlComponentConfig config, int gear) =>
      _enqueue(FreeControlCommandMapper.gear(config, gear));

  /// 吮吸/加热开关切换。
  void onToggleChanged(FreeControlComponentType type, bool on) =>
      _enqueue(FreeControlCommandMapper.toggle(type, on));

  /// 吮吸模式切换；模式号为后台模式列表下标 + 1，未知模式名直接忽略。
  void onSuckModeSelected(FreeControlComponentConfig config, String mode) {
    final index = config.modes.indexOf(mode);
    if (index < 0) return;
    _enqueue(FreeControlCommandMapper.suckMode(index + 1));
  }

  /// 把指令放入待下发队列并确保串行下发循环在运行。
  ///
  /// 拖动滑杆每跨 1% 就会触发一次回调，频率远高于 BLE 写入速度；同一通道只保留
  /// 最新一条（latest-wins），在途写入完成后再发最新值，避免指令积压与延迟累积。
  /// 开关与模式指令使用独立键，不会被同通道的强度指令覆盖。
  void _enqueue(CommonBusinessCommand command) {
    final module = command.instructions.first.module.key;
    final kind = command.isModeCommand
        ? 'mode'
        : int.tryParse(command.instructions.first.value) != null
        ? 'level'
        : 'switch';
    _pendingCommands['$module:$kind'] = command;
    if (_draining) return;
    unawaited(_drainCommands());
  }

  /// 串行下发队列中的指令；单一循环保证同一时刻只有一个 BLE 写入在途。
  Future<void> _drainCommands() async {
    _draining = true;
    try {
      while (_pendingCommands.isNotEmpty && !isClosed) {
        final key = _pendingCommands.keys.first;
        final command = _pendingCommands.remove(key)!;
        final device = connectedDevice;
        if (device == null) {
          // 设备已断开：剩余指令已无目标，直接丢弃；断连跳转由连接 worker 负责。
          _pendingCommands.clear();
          break;
        }
        final result = await commandRepository.send(
          command.toString(),
          modelId: int.tryParse(device.device.model.trim()),
          remoteId: device.remoteId,
        );
        final failure = result.failureOrNull;
        if (failure != null) {
          // 失败不重试：下一次用户操作或设备遥测会给出最新真实状态。
          log.warning(
            'Free control command failed',
            data: {'command': command.toString()},
            error: failure.message,
          );
        }
      }
    } finally {
      _draining = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadLayout();
    // 按照 PRD 6.3 交互规则："进入页面即按当前模块值自动运行，底部 pill 显示 Running"
    sessionController.updateState(DeviceSessionState.running);
    _bindDeviceConnectionWorker();
  }

  void _bindDeviceConnectionWorker() {
    _deviceWorker = ever(bleCoordinator.connectedDevice, (connected) {
      if (connected == null) {
        _handleDeviceDisconnected();
      }
    });
    _connectionWorker = ever(bleCoordinator.connectionStates, (_) {
      if (!bleCoordinator.hasConnectedDevice) {
        _handleDeviceDisconnected();
      }
    });
  }

  void _handleDeviceDisconnected() {
    sessionController.updateState(DeviceSessionState.idle);
    if (AppRoutes.requiresConnectedDevice(Get.currentRoute)) {
      AppRoutes.returnToHome();
    }
  }

  @override
  void onClose() {
    _deviceWorker?.dispose();
    _connectionWorker?.dispose();
    _pendingCommands.clear();
    sessionController.updateState(DeviceSessionState.idle);
    super.onClose();
  }

  /// 加载后端配置的自由控制积木式布局
  Future<void> loadLayout() async {
    isLoading.value = true;
    errorMessage.value = null;

    final connected = connectedDevice;
    final modelId = connected != null
        ? int.tryParse(connected.device.model.trim())
        : null;

    if (modelId != null) {
      final detailResult = await catalogRepository.getDeviceModelDetail(
        modelId,
      );
      final detail = detailResult.valueOrNull;

      if (detail != null && detail.layout != null) {
        layout.value = FreeControlLayout.fromJson(
          deviceName: deviceName,
          layoutJson: detail.layout,
          supportedActions: detail.supportedActions,
        );
        isLoading.value = false;
        return;
      }
    }

    // 若无网络或后台未配置专属布局，展示标准的默认动态布局 (img_free_control 样式 1)
    layout.value = FreeControlLayout.defaultPreset(deviceName: deviceName);
    isLoading.value = false;
  }

  /// 切换预设布局（与用户上传设计图中的 5 张图 img_free_control ... img_free_control_5 严格对齐）
  void applyMockPreset(int presetIndex) {
    currentPreset.value = presetIndex;
    switch (presetIndex) {
      case 1:
        // img_free_control:
        // row 0: Heat(1x1, col:0), Suck(1x1, col:1)
        // row 1: Telescopic(3x1, col:0, rows:3), Vibration(3x1, col:1, rows:3)
        // row 4: OneClickClimax(2x2, col:0, rows:2, cols:2)
        layout.value = FreeControlLayout.defaultPreset(deviceName: deviceName);
        break;

      case 2:
        // img_free_control_2:
        // row 0: Telescopic 模式水平条 (1x2, cols:2)
        // row 1: Vibration 模式水平条 (1x2, cols:2)
        // row 2: Heat 条形 (1x2, cols:2)
        // row 3: Telescopic 变速水平条 (1x2, cols:2)
        // row 4: Vibration 变速水平条 (1x2, cols:2)
        layout.value = FreeControlLayout(
          deviceName: deviceName,
          columns: 2,
          components: const [
            FreeControlComponentConfig(
              type: FreeControlComponentType.telescopic,
              variant: 'telescopic_mode_1x2',
              rows: 1,
              cols: 2,
              row: 0,
              col: 0,
              order: 1,
              gearMax: 6,
              gearCurrent: 4,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.vibration,
              variant: 'vibration_mode_1x2',
              rows: 1,
              cols: 2,
              row: 1,
              col: 0,
              order: 2,
              gearMax: 6,
              gearCurrent: 2,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.heat,
              variant: 'heat_bar_1x2',
              rows: 1,
              cols: 2,
              row: 2,
              col: 0,
              order: 3,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.telescopic,
              variant: 'telescopic_variable_1x2',
              rows: 1,
              cols: 2,
              row: 3,
              col: 0,
              order: 4,
              variableSpeedSupported: true,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.vibration,
              variant: 'vibration_variable_1x2',
              rows: 1,
              cols: 2,
              row: 4,
              col: 0,
              order: 5,
              variableSpeedSupported: true,
            ),
          ],
        );
        break;

      case 3:
        // img_free_control_5:
        // row 0: Telescopic 无级变速垂直滑块 (3x1, col:0, rows:3)
        // row 0: Vibration 无级变速垂直滑块 (3x1, col:1, rows:3)
        // row 3: Suck 多档带模式选择 (2x2, col:0, rows:2, cols:2)
        layout.value = FreeControlLayout(
          deviceName: deviceName,
          columns: 2,
          components: const [
            FreeControlComponentConfig(
              type: FreeControlComponentType.telescopic,
              variant: 'telescopic_variable_3x1',
              rows: 3,
              cols: 1,
              row: 0,
              col: 0,
              order: 1,
              variableSpeedSupported: true,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.vibration,
              variant: 'vibration_variable_3x1',
              rows: 3,
              cols: 1,
              row: 0,
              col: 1,
              order: 2,
              variableSpeedSupported: true,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.suck,
              variant: 'suck_multi_2x2',
              rows: 2,
              cols: 2,
              row: 3,
              col: 0,
              order: 3,
            ),
          ],
        );
        break;

      case 4:
        // img_free_control_3:
        // row 0: Telescopic 模式水平条 (1x2, cols:2)
        // row 1: Vibration 模式水平条 (1x2, cols:2)
        // row 2: Telescopic 变速水平条 (1x2, cols:2)
        // row 3: Vibration 变速水平条 (1x2, cols:2)
        layout.value = FreeControlLayout(
          deviceName: deviceName,
          columns: 2,
          components: const [
            FreeControlComponentConfig(
              type: FreeControlComponentType.telescopic,
              variant: 'telescopic_mode_1x2',
              rows: 1,
              cols: 2,
              row: 0,
              col: 0,
              order: 1,
              gearMax: 6,
              gearCurrent: 4,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.vibration,
              variant: 'vibration_mode_1x2',
              rows: 1,
              cols: 2,
              row: 1,
              col: 0,
              order: 2,
              gearMax: 6,
              gearCurrent: 3,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.telescopic,
              variant: 'telescopic_variable_1x2',
              rows: 1,
              cols: 2,
              row: 2,
              col: 0,
              order: 3,
              variableSpeedSupported: true,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.vibration,
              variant: 'vibration_variable_1x2',
              rows: 1,
              cols: 2,
              row: 3,
              col: 0,
              order: 4,
              variableSpeedSupported: true,
            ),
          ],
        );
        break;

      case 5:
        // img_free_control_4:
        // row 0: Mode 模式选择卡片 (2x2, cols:2, rows:2)
        layout.value = FreeControlLayout(
          deviceName: deviceName,
          columns: 2,
          components: const [
            FreeControlComponentConfig(
              type: FreeControlComponentType.mode,
              variant: 'mode_2x2',
              rows: 2,
              cols: 2,
              row: 0,
              col: 0,
              order: 1,
            ),
          ],
        );
        break;

      default:
        layout.value = FreeControlLayout.defaultPreset(deviceName: deviceName);
    }
  }
}
