// 跨页面共享的设备会话状态编排入口。
import 'package:get/get.dart';

import '../domain/device_session.dart';

/// 为全局设备快捷控制条提供共享状态的 GetX 控制器。
final class ControlSessionController extends GetxController {
  /// 当前会话状态；保持独立响应式字段，使状态变化时只重建控制条。
  final Rx<DeviceSessionState> state = DeviceSessionState.idle.obs;

  /// 在 Repository 或 BLE 事件到达后更新会话状态。
  void updateState(DeviceSessionState nextState) {
    if (state.value == nextState) {
      return;
    }
    state.value = nextState;
  }

  /// 暂停运行中的会话，或恢复已暂停的会话。
  void togglePause() {
    final nextState = switch (state.value) {
      DeviceSessionState.running => DeviceSessionState.paused,
      DeviceSessionState.paused => DeviceSessionState.running,
      DeviceSessionState.idle || DeviceSessionState.connecting => state.value,
    };
    updateState(nextState);
  }
}
