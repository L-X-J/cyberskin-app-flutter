// 设备领域的内存 Repository 占位实现，供真实 API、缓存和 BLE 接入前使用。
import '../../../core/result/result.dart';
import '../domain/device.dart';
import '../domain/device_repository.dart';

/// 在真实 API、缓存和 BLE 服务接入前使用的临时 Repository。
///
/// 明确返回空列表，既避免初始壳层展示虚构硬件，又保留生产环境的 Repository
/// 依赖边界。
final class InMemoryDeviceRepository implements DeviceRepository {
  /// 创建始终返回空设备列表的 Repository。
  const InMemoryDeviceRepository();

  @override
  Future<Result<List<Device>>> loadDevices() async =>
      const Result.ok(<Device>[]);
}
