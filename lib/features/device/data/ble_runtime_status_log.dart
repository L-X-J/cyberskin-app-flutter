// 设备运行态上报诊断日志：把 SDK 解析后的 BleRuntimeStatus 以人类可读形式打印到 console。

import 'package:cyberskin_device_sdk/cyberskin_device_sdk.dart';
import 'package:flutter/foundation.dart';

/// BLE 诊断日志开关：仅在 debug 模式下输出，release 构建自动关闭。
const bool kBleDiagnosticLog = kDebugMode;

/// 输出 BLE 诊断日志，仅在调试模式下打印。
void bleLog(String message) {
  if (kBleDiagnosticLog) debugPrint('[BLE] $message');
}

/// 设备运行态上报诊断日志器。
///
/// 职责是**只读打印**：不缓存、不修改、不节流任何上报内容，因此不会影响控件刷新时序。
/// 0xDD00 帧由设备每秒上报一次，真正的遥测日志默认按秒聚合，避免刷屏；
/// 每一帧只打印在 [verbose] 级别。
///
/// 输出示例：
/// ```
/// [BLE:RT] id=AA:BB:CC:DD:EE:FF t=12s 帧数=12 伸缩=52/52 震动=38/38 吮吸=2(吸气) 加热=1(开) 电量=76% 充电=false
/// [BLE:RT] 变化: 伸缩 0→52, 吮吸 1(待机)→2(吸气), 加热 0(关)→1(开)
/// ```
final class BleRuntimeStatusLogger {
  /// 创建运行态日志器；[verbose] 为 true 时额外逐帧打印原始解析结果。
  BleRuntimeStatusLogger({this.verbose = false});

  /// 是否逐帧打印（默认关闭，仅按秒聚合输出）。
  final bool verbose;

  /// 最近一次打印的聚合快照，用于计算字段级变化。
  BleRuntimeStatus? _last;

  /// 最近一次打印时间。
  DateTime? _lastPrintedAt;

  /// 上次打印以来累计的帧数。
  int _framesSincePrint = 0;

  /// 累计帧数，用于日志中的 t= 时间轴。
  int _totalFrames = 0;

  /// 记录一帧解析后的运行态；[remoteId] 为设备 BLE 地址。
  ///
  /// 逐帧调用：仅在 [verbose] 时立即打印，否则每秒聚合一次打印。
  void onStatus(String remoteId, BleRuntimeStatus status) {
    if (!kBleDiagnosticLog) return;
    _framesSincePrint++;
    _totalFrames++;
    if (verbose) {
      debugPrint('[BLE:RT:帧] id=$remoteId ${describe(status)}');
    }
    final now = DateTime.now();
    final last = _lastPrintedAt;
    if (last != null && now.difference(last).inMilliseconds < 1000) return;
    final previous = _last;
    _last = status;
    _lastPrintedAt = now;
    final frames = _framesSincePrint;
    _framesSincePrint = 0;
    debugPrint(
      '[BLE:RT] id=$remoteId t=${_totalFrames}s 帧数=$frames ${describe(status)}',
    );
    if (previous != null) {
      final diff = describeChanges(previous, status);
      if (diff.isNotEmpty) debugPrint('[BLE:RT] 变化: $diff');
    }
  }

  /// 设备断开或视图重建时重置聚合状态，避免跨会话比较出错误的变化。
  void reset() {
    _last = null;
    _lastPrintedAt = null;
    _framesSincePrint = 0;
    _totalFrames = 0;
  }

  /// 把运行态快照描述为一段中文字段串。
  static String describe(BleRuntimeStatus status) {
    final parts = <String>[
      '伸缩=${_power(status.motorPower)}/${_power(status.lastReportedMotorPower)}',
      '震动=${_power(status.vibrateMotorPower)}/'
          '${_power(status.lastReportedVibrateMotorPower)}',
      '吮吸=${status.suckState}(${_suckLabel(status.suckState)})',
      '加热=${status.heatState}(${_heatLabel(status.heatState)})',
      '电量=${status.batteryLevel < 0 ? '未知' : '${status.batteryLevel}%'}',
      '充电=${status.isCharging}',
      if (status.isShuttingDown) '关机中=true',
    ];
    return parts.join(' ');
  }

  /// 计算两个快照之间的字段级变化，返回空串表示无变化。
  static String describeChanges(BleRuntimeStatus a, BleRuntimeStatus b) {
    final changes = <String>[];
    void diff(String label, int before, int after) {
      if (before != after) changes.add('$label $before→$after');
    }

    diff('伸缩', a.motorPower, b.motorPower);
    diff('震动', a.vibrateMotorPower, b.vibrateMotorPower);
    if (a.suckState != b.suckState) {
      changes.add(
        '吮吸 ${a.suckState}(${_suckLabel(a.suckState)})→'
        '${b.suckState}(${_suckLabel(b.suckState)})',
      );
    }
    if (a.heatState != b.heatState) {
      changes.add(
        '加热 ${a.heatState}(${_heatLabel(a.heatState)})→'
        '${b.heatState}(${_heatLabel(b.heatState)})',
      );
    }
    diff('电量', a.batteryLevel, b.batteryLevel);
    if (a.isCharging != b.isCharging) {
      changes.add('充电 ${a.isCharging}→${b.isCharging}');
    }
    if (a.isShuttingDown != b.isShuttingDown) {
      changes.add('关机中 ${a.isShuttingDown}→${b.isShuttingDown}');
    }
    return changes.join(', ');
  }

  static String _power(int value) => value < 0 ? '未知' : '$value';

  /// 吮吸状态码 → 中文语义（0xDD00 帧 `0x03` 通道）。
  static String _suckLabel(int state) => switch (state) {
    -1 => '未知',
    1 => '待机',
    2 => '吸气',
    3 => '放气',
    _ => '未定义',
  };

  /// 加热状态码 → 中文语义（0xDD00 帧 `0x04` 通道）。
  static String _heatLabel(int state) => switch (state) {
    -1 => '未知',
    0 => '关',
    1 => '开',
    _ => '未定义',
  };
}
