// 当前已连接设备的实时运行时视图；把服务端元数据与 BLE 遥测合并为单一可观察对象。
import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:get/get.dart';

import 'device.dart';

/// 当前连接设备的完整运行时视图。
///
/// [device] 是连接建立后从 Repository 冻结的服务端元数据快照，不随遥测变化。
/// 各遥测字段各自独立 Rx 包裹，Obx 只重建订阅该字段的子组件，而不是整棵设备卡树。
/// 0xDD00 帧每秒上报一次，由协调器调用 [applyStatus] 将快照分发到各字段。
final class ConnectedDeviceState {
  /// 创建连接设备视图；[device] 为服务端元数据，[remoteId] 为 BLE 物理地址。
  ConnectedDeviceState({required this.device, required this.remoteId});

  /// 连接建立时从 Repository 获取的不可变设备元数据（名称、型号、卡片色等）。
  final Device device;

  /// BLE 物理地址，用于向协调器发送命令时定位目标设备。
  final String remoteId;

  // ── 遥测字段 ─────────────────────────────────────────────────────────────
  // 每字段独立 Rx，点位级刷新，避免单一大对象替换触发全树重建。

  /// 主伸缩马达当前功率 0–100；-1 表示未知或未启用。
  final RxInt motorPower = (-1).obs;

  /// 上次上报的主马达非零功率，用于恢复历史档位。
  final RxInt lastReportedMotorPower = (-1).obs;

  /// 震动马达当前功率 0–100；-1 表示未知或未启用。
  final RxInt vibrateMotorPower = (-1).obs;

  /// 上次上报的震动马达非零功率，用于恢复历史档位。
  final RxInt lastReportedVibrateMotorPower = (-1).obs;

  /// 吸吮状态：-1=未知，1=待机，2=吸气，3=放气。
  final RxInt suckState = (-1).obs;

  /// 加热状态：-1=未知，0=关，1=开。
  final RxInt heatState = (-1).obs;

  /// 电量百分比 0–100；-1 表示未获取。
  final RxInt batteryLevel = (-1).obs;

  /// 是否正在充电。
  final RxBool isCharging = false.obs;

  /// 是否正在关机（设备关机前上报一次 0x01）。
  final RxBool isShuttingDown = false.obs;

  /// 将 SDK 下发的 [BleRuntimeStatus] 快照逐字段写入响应式属性。
  ///
  /// 由协调器在收到 [BleRuntimeChanged] 事件时调用；只更新值有变化的字段，
  /// 避免无意义的 Rx 通知。
  void applyStatus(BleRuntimeStatus status) {
    if (motorPower.value != status.motorPower) {
      motorPower.value = status.motorPower;
    }
    if (lastReportedMotorPower.value != status.lastReportedMotorPower) {
      lastReportedMotorPower.value = status.lastReportedMotorPower;
    }
    if (vibrateMotorPower.value != status.vibrateMotorPower) {
      vibrateMotorPower.value = status.vibrateMotorPower;
    }
    if (lastReportedVibrateMotorPower.value !=
        status.lastReportedVibrateMotorPower) {
      lastReportedVibrateMotorPower.value =
          status.lastReportedVibrateMotorPower;
    }
    if (suckState.value != status.suckState) {
      suckState.value = status.suckState;
    }
    if (heatState.value != status.heatState) {
      heatState.value = status.heatState;
    }
    if (batteryLevel.value != status.batteryLevel) {
      batteryLevel.value = status.batteryLevel;
    }
    if (isCharging.value != status.isCharging) {
      isCharging.value = status.isCharging;
    }
    if (isShuttingDown.value != status.isShuttingDown) {
      isShuttingDown.value = status.isShuttingDown;
    }
  }
}
