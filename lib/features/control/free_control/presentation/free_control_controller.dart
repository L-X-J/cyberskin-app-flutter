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

    // 若无网络或后台未配置专属布局，展示标准的默认动态布局
    layout.value = FreeControlLayout.defaultPreset(deviceName: deviceName);
    isLoading.value = false;
  }

  /// 切换预设布局（供开发/演示查看不同样式，如 img_free_control, img_free_control_2, 3, 4, 5）
  void applyMockPreset(int presetIndex) {
    switch (presetIndex) {
      case 1:
        // img_free_control
        layout.value = FreeControlLayout.defaultPreset(deviceName: deviceName);
        break;
      case 2:
        // img_free_control_2
        layout.value = FreeControlLayout(
          deviceName: deviceName,
          columns: 2,
          components: const [
            FreeControlComponentConfig(
              type: FreeControlComponentType.telescopic,
              variant: 'telescopic_mode_1x2',
              rows: 1,
              cols: 2,
              order: 1,
              gearMax: 6,
              gearCurrent: 4,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.vibration,
              variant: 'vibration_mode_1x2',
              rows: 1,
              cols: 2,
              order: 2,
              gearMax: 6,
              gearCurrent: 2,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.heat,
              variant: 'heat_bar_1x2',
              rows: 1,
              cols: 2,
              order: 3,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.telescopic,
              variant: 'telescopic_variable_1x2',
              rows: 1,
              cols: 2,
              order: 4,
              variableSpeedSupported: true,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.vibration,
              variant: 'vibration_variable_1x2',
              rows: 1,
              cols: 2,
              order: 5,
              variableSpeedSupported: true,
            ),
          ],
        );
        break;
      case 3:
        // img_free_control_5 (垂直变速 + 吸附多档)
        layout.value = FreeControlLayout(
          deviceName: deviceName,
          columns: 2,
          components: const [
            FreeControlComponentConfig(
              type: FreeControlComponentType.telescopic,
              variant: 'telescopic_variable_3x1',
              rows: 3,
              cols: 1,
              order: 1,
              variableSpeedSupported: true,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.vibration,
              variant: 'vibration_variable_3x1',
              rows: 3,
              cols: 1,
              order: 2,
              variableSpeedSupported: true,
            ),
            FreeControlComponentConfig(
              type: FreeControlComponentType.suck,
              variant: 'suck_multi_2x2',
              rows: 2,
              cols: 2,
              order: 3,
            ),
          ],
        );
        break;
      case 4:
        // img_free_control_4 (模式卡片)
        layout.value = FreeControlLayout(
          deviceName: deviceName,
          columns: 2,
          components: const [
            FreeControlComponentConfig(
              type: FreeControlComponentType.mode,
              variant: 'mode_2x2',
              rows: 2,
              cols: 2,
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
