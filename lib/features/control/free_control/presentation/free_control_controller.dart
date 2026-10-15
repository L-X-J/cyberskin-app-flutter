// 自由控制页面控制器：负责加载设备详情中的动态布局配置、维持控制状态与会话生命周期。

import 'package:get/get.dart';

import '../../../device/data/cyberskin_ble_runtime_coordinator.dart';
import '../../../device/domain/connected_device_state.dart';
import '../../../device/domain/repositories/device_catalog_repository.dart';
import '../../domain/device_session.dart';
import '../../presentation/control_session_controller.dart';
import '../domain/entities/free_control_layout.dart';

final class FreeControlController extends GetxController {
  FreeControlController({
    required this.catalogRepository,
    required this.bleCoordinator,
    required this.sessionController,
  });

  final DeviceCatalogRepository catalogRepository;
  final CyberskinBleRuntimeCoordinator bleCoordinator;
  final ControlSessionController sessionController;

  /// 当前动态布局配置
  final Rx<FreeControlLayout?> layout = Rx<FreeControlLayout?>(null);

  /// 当前选中的预设样式索引 (1-5)
  final RxInt currentPreset = 1.obs;

  /// 加载中状态
  final RxBool isLoading = true.obs;

  /// 错误提示
  final Rx<String?> errorMessage = Rx<String?>(null);

  /// 当前连接的设备状态（如果有）
  ConnectedDeviceState? get connectedDevice => bleCoordinator.connectedDevice.value;

  /// 设备名称
  String get deviceName {
    final connected = connectedDevice;
    if (connected != null && connected.device.name.isNotEmpty) {
      return connected.device.name;
    }
    return 'Cyberskin Pro';
  }

  /// 设备连接状态提示文案
  String get connectionStatusText {
    final connected = connectedDevice;
    if (connected != null) {
      return 'Connected';
    }
    return 'Connected';
  }

  @override
  void onInit() {
    super.onInit();
    loadLayout();
    // 按照 PRD 6.3 交互规则："进入页面即按当前模块值自动运行，底部 pill 显示 Running"
    sessionController.updateState(DeviceSessionState.running);
  }

  /// 加载后端配置的自由控制积木式布局
  Future<void> loadLayout() async {
    isLoading.value = true;
    errorMessage.value = null;

    final connected = connectedDevice;
    final modelId = connected != null ? int.tryParse(connected.device.model.trim()) : null;

    if (modelId != null) {
      final detailResult = await catalogRepository.getDeviceModelDetail(modelId);
      final detail = detailResult.valueOrNull;

      if (detail != null && detail.layout != null) {
        layout.value = FreeControlLayout.fromJson(
          deviceName: deviceName,
          layoutJson: detail.layout,
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
