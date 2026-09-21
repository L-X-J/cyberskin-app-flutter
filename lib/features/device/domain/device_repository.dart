// 设备领域的数据访问抽象。
import '../../../core/result/result.dart';
import 'device.dart';

/// 用户设备数据的领域访问入口。
abstract interface class DeviceRepository {
  /// 加载缓存、远端或两者合并后的设备摘要。
  Future<Result<List<Device>>> loadDevices();
}
