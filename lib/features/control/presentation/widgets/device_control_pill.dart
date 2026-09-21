// 底部导航上方的全局设备快捷控制组件。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../domain/device_session.dart';
import '../control_session_controller.dart';

/// 展示当前设备会话状态并提供暂停或继续操作的全局控制条。
final class DeviceControlPill extends StatelessWidget {
  /// 创建设备快捷控制条。
  const DeviceControlPill({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ControlSessionController>();
    return Obx(() {
      final state = controller.state.value;
      final canToggle =
          state == DeviceSessionState.running ||
          state == DeviceSessionState.paused;
      return Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(28),
        color: Theme.of(context).colorScheme.inverseSurface,
        child: InkWell(
          onTap: canToggle ? controller.togglePause : null,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state == DeviceSessionState.connecting
                      ? Icons.bluetooth_searching
                      : state == DeviceSessionState.running
                      ? Icons.pause_circle_outline
                      : state == DeviceSessionState.paused
                      ? Icons.play_circle_outline
                      : Icons.bluetooth_disabled,
                  color: Theme.of(context).colorScheme.onInverseSurface,
                ),
                const SizedBox(width: 10),
                Flexible(child: _PillText(state: state)),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// 根据会话状态渲染控制条主副文案。
final class _PillText extends StatelessWidget {
  const _PillText({required this.state});

  final DeviceSessionState state;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onInverseSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.label,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        ),
        Text(
          state.subtitle,
          style: TextStyle(color: foreground.withValues(alpha: 0.76)),
        ),
      ],
    );
  }
}
