// 主页顶部蓝牙卡片的 UI 状态与业务阶段。
import 'package:flutter/material.dart';

/// 顶部蓝牙卡片的业务阶段。
enum HomeBleCardPhase {
  /// 正在读取系统蓝牙状态或加载后台设备配置。
  checking,

  /// 系统蓝牙未开启。
  bluetoothOff,

  /// 蓝牙权限未授予或被系统拒绝。
  permissionRequired,

  /// 当前设备不支持 BLE。
  unavailable,

  /// 蓝牙可用，但用户必须登录后才能连接设备。
  loginRequired,

  /// 蓝牙可用，等待用户开始扫描。
  ready,

  /// 正在扫描附近设备。
  scanning,

  /// 已发现需要用户确认的新设备。
  deviceFound,

  /// 本轮扫描结束但没有找到设备。
  noDevice,

  /// 正在连接已发现或已记住的设备。
  connecting,

  /// 最近一次连接失败。
  connectionFailed,

  /// 设备绑定被服务端拒绝（如型号未发布）。
  bindFailed,
}

/// 顶部蓝牙卡片的不可变展示状态和英文文案。
final class HomeBleCardState {
  /// 创建蓝牙卡片状态。
  const HomeBleCardState({
    required this.phase,
    required this.adapterOn,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionIcon,
    required this.showSpinner,
    required this.showStop,
    required this.actionEnabled,
  });

  /// 初始检查状态。
  const HomeBleCardState.checking()
    : this(
        phase: HomeBleCardPhase.checking,
        adapterOn: false,
        title: 'Checking Bluetooth',
        description: 'Checking Bluetooth access so we can discover and reconnect your Cyberskin device.',
        actionLabel: 'Please wait',
        actionIcon: Icons.bluetooth_searching,
        showSpinner: true,
        showStop: false,
        actionEnabled: false,
      );

  /// 根据业务阶段生成英文展示状态。
  ///
  /// [errorMessage] 可选的服务端或协调器错误消息；仅 [HomeBleCardPhase.bindFailed]
  /// 等需要展示动态原因的阶段会使用它替换默认描述文案。
  factory HomeBleCardState.fromPhase(
    HomeBleCardPhase phase, {
    required bool adapterOn,
    String? errorMessage,
  }) {
    return switch (phase) {
      HomeBleCardPhase.checking => const HomeBleCardState.checking(),
      HomeBleCardPhase.bluetoothOff => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'Bluetooth is off',
        description: 'Bluetooth is required to find, connect to, and control your Cyberskin device.',
        actionLabel: 'Turn on Bluetooth',
        actionIcon: Icons.bluetooth_disabled,
        showSpinner: false,
        showStop: false,
        actionEnabled: true,
      ),
      HomeBleCardPhase.permissionRequired => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'Bluetooth permission needed',
        description: 'We use Bluetooth only to find and control a nearby Cyberskin device. Allow access to continue.',
        actionLabel: 'Allow Bluetooth access',
        actionIcon: Icons.security,
        showSpinner: false,
        showStop: false,
        actionEnabled: true,
      ),
      HomeBleCardPhase.unavailable => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'Bluetooth unavailable',
        description: 'This device cannot provide Bluetooth Low Energy, so a Cyberskin device cannot be connected here.',
        actionLabel: 'Open Settings',
        actionIcon: Icons.settings,
        showSpinner: false,
        showStop: false,
        actionEnabled: true,
      ),
      HomeBleCardPhase.loginRequired => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'Log in to connect',
        description: 'Log in to connect and control your Cyberskin device.',
        actionLabel: 'Log in now',
        actionIcon: Icons.login,
        showSpinner: false,
        showStop: false,
        actionEnabled: true,
      ),
      HomeBleCardPhase.ready => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'Ready to connect',
        description: 'Turn on your device and keep it nearby. Bluetooth lets the app discover and control it.',
        actionLabel: 'Scan',
        actionIcon: Icons.bluetooth_searching,
        showSpinner: false,
        showStop: false,
        actionEnabled: true,
      ),
      HomeBleCardPhase.scanning => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'Searching for your device',
        description: 'Keep your Cyberskin device powered on and nearby. Remembered devices reconnect automatically.',
        actionLabel: 'Stop',
        actionIcon: Icons.bluetooth_searching,
        showSpinner: true,
        showStop: true,
        actionEnabled: false,
      ),
      HomeBleCardPhase.deviceFound => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'Device found nearby',
        description: 'Review the device below and connect it to your account when you are ready.',
        actionLabel: 'Device found',
        actionIcon: Icons.bluetooth_connected,
        showSpinner: false,
        showStop: true,
        actionEnabled: false,
      ),
      HomeBleCardPhase.noDevice => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'No device found',
        description: 'Keep the device powered on and nearby, then scan again. Bluetooth must stay on while connecting.',
        actionLabel: 'Scan again',
        actionIcon: Icons.refresh,
        showSpinner: false,
        showStop: false,
        actionEnabled: true,
      ),
      HomeBleCardPhase.connecting => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'Connecting to your device',
        description:
            'Keep your device nearby while we finish the Bluetooth connection.',
        actionLabel: 'Connecting',
        actionIcon: Icons.bluetooth_connected,
        showSpinner: true,
        showStop: false,
        actionEnabled: false,
      ),
      HomeBleCardPhase.connectionFailed => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'Could not connect',
        description: 'Move closer to your device and try again. Bluetooth is needed for a stable connection.',
        actionLabel: 'Try again',
        actionIcon: Icons.refresh,
        showSpinner: false,
        showStop: false,
        actionEnabled: true,
      ),
      HomeBleCardPhase.bindFailed => HomeBleCardState(
        phase: phase,
        adapterOn: adapterOn,
        title: 'Device not registered',
        description: errorMessage?.isNotEmpty == true
            ? errorMessage!
            : 'The device connected but could not be linked to your account. Please try again or contact support.',
        actionLabel: 'Scan again',
        actionIcon: Icons.refresh,
        showSpinner: false,
        showStop: false,
        actionEnabled: true,
      ),
    };
  }

  /// 当前 BLE 卡片业务阶段。
  final HomeBleCardPhase phase;

  /// 系统蓝牙是否已开启。
  final bool adapterOn;

  /// 卡片标题。
  final String title;

  /// 解释当前状态和为什么需要蓝牙的正文。
  final String description;

  /// 主操作按钮文案。
  final String actionLabel;

  /// 主操作按钮图标。
  final IconData actionIcon;

  /// 是否展示扫描/连接中的动画。
  final bool showSpinner;

  /// 是否展示停止扫描按钮。
  final bool showStop;

  /// 主操作按钮是否可点击。
  final bool actionEnabled;
}
