// 设备语义指令的领域访问边界。
import '../../../core/result/result.dart';

/// 向当前物理设备发送通用语义命令。
abstract interface class DeviceCommandRepository {
  /// 发送 `t/v/s/h` 语义指令；Repository 不接收原始十六进制帧。
  Future<Result<void>> send(String command, {int? modelId, String? remoteId});
}
