// 节奏设备类型的兼容名称；实际端口由 control 领域统一维护。
import '../../../control/domain/repositories/device_playback_port.dart';

/// 兼容已有节奏调用方的物理设备身份。
typedef RhythmDeviceTarget = DevicePlaybackTarget;

/// 兼容已有节奏调用方的设备事件。
typedef RhythmDeviceEvent = DevicePlaybackEvent;

/// 兼容已有节奏调用方的通用播放端口。
typedef RhythmDevicePort = DevicePlaybackPort;
