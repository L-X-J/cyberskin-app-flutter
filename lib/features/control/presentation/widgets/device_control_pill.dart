// 液态玻璃设备快捷控件：只接收状态与回调，不查找全局依赖或执行导航。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_device_control_style.dart';
import '../../domain/device_quick_control.dart';

/// 展示四态及连接中过渡态；手势拖动由外部应用宿主负责。
final class DeviceControlPill extends StatefulWidget {
  /// 创建控件；连接中始终不可激活，待运行的 Paused 显示开始提示。
  const DeviceControlPill({
    super.key,
    required this.state,
    required this.onPressed,
    this.hasSession = true,
  });

  /// 来自领域映射的状态，不由组件自行推断设备连接。
  final DeviceQuickControlState state;

  /// 应用组装层提供的操作；为空时不可点击。
  final VoidCallback? onPressed;

  /// 只有真实暂停会话才显示恢复提示。
  final bool hasSession;

  @override
  State<DeviceControlPill> createState() => _DeviceControlPillState();
}

final class _DeviceControlPillState extends State<DeviceControlPill> {
  bool _focused = false;

  /// 连接中的禁用不降低表面透明度，保持四态相同的玻璃外框。
  bool get _enabled =>
      widget.state != DeviceQuickControlState.connecting &&
      widget.onPressed != null;

  /// 副文案使用动作语义，不把尚无会话的设备称为可恢复会话。
  String get _subtitle => switch (widget.state) {
    DeviceQuickControlState.running => 'Tap to pause',
    DeviceQuickControlState.runningLowBattery => 'Low battery',
    DeviceQuickControlState.paused =>
      widget.hasSession ? 'Tap to resume' : 'Tap to start',
    _ => '',
  };

  /// 主文案保持 Ardot 英文状态名称。
  String get _title => switch (widget.state) {
    DeviceQuickControlState.running ||
    DeviceQuickControlState.runningLowBattery => 'Running',
    DeviceQuickControlState.paused => 'Paused',
    DeviceQuickControlState.connecting => 'Connecting',
    DeviceQuickControlState.disconnected => 'Not connected',
  };

  /// 键盘与触控共享同一禁用边界。
  void _activate() {
    if (_enabled) widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppDeviceControlStyle.title.copyWith(
      fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
    );
    return FocusableActionDetector(
      enabled: _enabled,
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: widget.state == DeviceQuickControlState.disconnected
            ? 'Not connected, Open device controls'
            : '$_title${_subtitle.isEmpty ? '' : ', $_subtitle'}',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _enabled ? _activate : null,
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = AppDeviceControlStyle.sizeFor(
                  textScaler: MediaQuery.textScalerOf(context),
                  maxWidth: constraints.hasBoundedWidth
                      ? constraints.maxWidth
                      : double.infinity,
                  fontFamily: style.fontFamily,
                );
                return LGContainer(
                  width: size.width,
                  height: size.height,
                  useOwnLayer: true,
                  quality: LGQuality.standard,
                  settings: AppDeviceControlStyle.glass,
                  shape: LiquidRoundedRectangle(borderRadius: size.height / 2),
                  clipBehavior: Clip.antiAlias,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppDeviceControlStyle.surface,
                      borderRadius: BorderRadius.circular(size.height / 2),
                      border: _focused
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Padding(
                      padding: AppDeviceControlStyle.contentPadding,
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: AppDeviceControlStyle.iconSize,
                            child: Center(child: _buildIcon()),
                          ),
                          SizedBox(
                            width:
                                widget.state ==
                                    DeviceQuickControlState.disconnected
                                ? 2
                                : AppDeviceControlStyle.iconGap,
                          ),
                          Expanded(child: _buildText(style)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 原始图标交换后表达点击动作；loading 保留蓝牙和独立进度动画。
  Widget _buildIcon() {
    if (widget.state == DeviceQuickControlState.connecting) {
      return const SizedBox.square(
        dimension: 24,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
            Icon(Icons.bluetooth, size: 14, color: Colors.white),
          ],
        ),
      );
    }
    return SvgPicture.asset(
      switch (widget.state) {
        DeviceQuickControlState.disconnected =>
          AppDeviceControlStyle.disconnectedAsset,
        DeviceQuickControlState.paused => AppDeviceControlStyle.playAsset,
        _ => AppDeviceControlStyle.pauseAsset,
      },
      width: widget.state == DeviceQuickControlState.disconnected ? 24 : 32,
      height: widget.state == DeviceQuickControlState.disconnected ? 24 : 32,
    );
  }

  /// 图标与文案不参与玻璃背景滤镜，低电量只替换副文案。
  Widget _buildText(TextStyle titleStyle) {
    if (widget.state == DeviceQuickControlState.disconnected) {
      return Text(
        'Not\nconnected',
        style: AppDeviceControlStyle.disconnected.copyWith(
          fontFamily: titleStyle.fontFamily,
        ),
      );
    }
    final subtitle = AppDeviceControlStyle.subtitle.copyWith(
      fontFamily: titleStyle.fontFamily,
    );
    if (widget.state == DeviceQuickControlState.connecting) {
      // 过渡态沿用外框，不用较长文字扩大四个主设计态的固定尺寸。
      return Text(_title, style: subtitle.copyWith(fontSize: 10));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_title, style: titleStyle),
        if (widget.state == DeviceQuickControlState.runningLowBattery)
          Row(
            children: [
              SvgPicture.asset(
                AppDeviceControlStyle.batteryAsset,
                width: 10,
                height: 10,
              ),
              const SizedBox(width: 2),
              Expanded(child: Text(_subtitle, style: subtitle)),
            ],
          )
        else if (_subtitle.isNotEmpty)
          Text(_subtitle, style: subtitle),
      ],
    );
  }
}
