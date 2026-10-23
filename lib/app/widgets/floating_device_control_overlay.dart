// 单实例悬浮宿主：组装设备状态、动作与定位，不在业务组件中隐藏依赖。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_device_control_style.dart';
import '../../features/control/domain/device_quick_control.dart';
import '../../features/control/domain/device_session.dart';
import '../../features/control/presentation/control_session_controller.dart';
import '../../features/control/presentation/widgets/device_control_pill.dart';
import '../app_routes.dart';
import '../floating_control_controller.dart';
import '../session_controller.dart';

/// 在根 Navigator 外保留唯一宿主，路由变化不会重复挂载设备控制组件。
final class FloatingDeviceControlOverlay extends StatefulWidget {
  /// 接收应用 Navigator；未占用的区域不拦截页面手势。
  const FloatingDeviceControlOverlay({super.key, required this.child});

  /// 应用导航树，由悬浮层在其上方绘制控件。
  final Widget child;

  @override
  State<FloatingDeviceControlOverlay> createState() =>
      _FloatingDeviceControlOverlayState();
}

final class _FloatingDeviceControlOverlayState
    extends State<FloatingDeviceControlOverlay> {
  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _controlKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FloatingControlController>();
    final textScaler = MediaQuery.textScalerOf(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final fontFamily = Theme.of(context).textTheme.labelLarge?.fontFamily;
    return Stack(
      key: _stackKey,
      fit: StackFit.expand,
      children: [
        widget.child,
        Obx(() {
          final policy = controller.policy.value;
          final bounds = controller.bodyBounds.value;
          if (controller.mediaFullscreen.value ||
              policy == FloatingControlPolicy.hidden ||
              bounds == null ||
              bounds.width <= 48) {
            return const SizedBox.shrink();
          }
          final size = AppDeviceControlStyle.sizeFor(
            textScaler: textScaler,
            maxWidth: bounds.width - 48,
            fontFamily: fontFamily,
          );
          if (bounds.height < size.height) return const SizedBox.shrink();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) controller.updateControlSize(size);
          });
          final globalTarget = controller.targetFor(size);
          final box =
              _stackKey.currentContext?.findRenderObject() as RenderBox?;
          final localTarget = box?.hasSize == true
              ? box!.globalToLocal(globalTarget)
              : globalTarget;
          final viewportWidth = box?.hasSize == true
              ? box!.size.width
              : MediaQuery.sizeOf(context).width;
          final isDocked =
              policy == FloatingControlPolicy.fixed ||
              controller.draggedPosition.value == null;
          // 页面转场会改变内容区域的横坐标；停靠点始终以宿主右边缘为准。
          final target = Offset(
            isDocked
                ? viewportWidth -
                      MediaQuery.paddingOf(context).right -
                      size.width -
                      24
                : localTarget.dx,
            localTarget.dy,
          );
          return AnimatedPositioned(
            key: const ValueKey('floating-device-position'),
            left: target.dx,
            top: target.dy,
            width: size.width,
            height: size.height,
            duration: disableAnimations || controller.isDragging.value
                ? Duration.zero
                : const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: viewportWidth - target.dx, end: 0),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, offset, child) =>
                  Transform.translate(offset: Offset(offset, 0), child: child),
              child: GestureDetector(
                key: _controlKey,
                behavior: HitTestBehavior.opaque,
                onPanStart: policy == FloatingControlPolicy.draggable
                    ? (_) {
                        final rendered =
                            _controlKey.currentContext?.findRenderObject()
                                as RenderBox?;
                        if (rendered != null && rendered.hasSize) {
                          controller.startDrag(
                            rendered.localToGlobal(Offset.zero),
                          );
                        }
                      }
                    : null,
                onPanUpdate: policy == FloatingControlPolicy.draggable
                    ? (details) => controller.dragBy(details.delta)
                    : null,
                onPanEnd: policy == FloatingControlPolicy.draggable
                    ? (_) => controller.endDrag()
                    : null,
                onPanCancel: policy == FloatingControlPolicy.draggable
                    ? controller.endDrag
                    : null,
                child: const _DeviceControlContent(),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// 设备状态订阅仅包围控件，不让高频状态改变触发整个宿主或 Navigator 重建。
final class _DeviceControlContent extends StatelessWidget {
  const _DeviceControlContent();

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionController>();
    final control = Get.find<ControlSessionController>();
    return Obx(
      () => DeviceControlPill(
        state: resolveQuickControlState(
          session.deviceStatus.value,
          control.state.value,
        ),
        hasSession: control.state.value != DeviceSessionState.idle,
        onPressed: () => _activate(session, control),
      ),
    );
  }

  /// 点击时重新读取当前状态，避免转场或断连后执行过期操作。
  void _activate(SessionController session, ControlSessionController control) {
    final state = resolveQuickControlState(
      session.deviceStatus.value,
      control.state.value,
    );
    if (state == DeviceQuickControlState.connecting) return;
    if (state == DeviceQuickControlState.disconnected) {
      AppRoutes.returnToHome();
      return;
    }
    // 已连接设备点击时向设备发送控制指令（启动/恢复或暂停），不离开当前页面。
    unawaited(control.activateQuickControl());
  }
}
