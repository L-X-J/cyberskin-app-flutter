// 用户绑定设备列表的两级缓存装饰器：内存优先，磁盘兜底，网络成功后双写。
import '../../../core/result/result.dart';
import '../domain/repositories/user_device_repository.dart';
import 'user_device_cache.dart';

/// 为 [UserDeviceRepository] 提供内存 + 磁盘两级缓存的透明装饰器。
///
/// 读取策略：
/// - 内存命中 → 直接返回，不发网络请求。
/// - 内存未命中 → 发起网络请求。
///   - 网络成功 → 写内存 + 写磁盘，返回新数据。
///   - 网络失败 → 降级读磁盘，有则返回磁盘数据，无则透传失败。
///
/// 写操作（bind / rename / unbind）成功后主动失效内存缓存，
/// 确保下一次 [listUserDevices] 能拿到最新列表。磁盘缓存不在写操作时清除，
/// 保留冷启动兜底能力，等下一次网络成功后自然覆盖。
///
/// 注销时由 [CyberskinBleRuntimeCoordinator] 调用 [invalidateCache]，
/// 防止旧账号数据在新登录后从内存命中。
final class CachedUserDeviceRepository implements UserDeviceRepository {
  CachedUserDeviceRepository({
    required UserDeviceRepository remote,
    required UserDeviceCache cache,
  }) : _remote = remote,
       _cache = cache;

  final UserDeviceRepository _remote;
  final UserDeviceCache _cache;

  // 内存缓存；null 表示未填充，需要网络或磁盘加载。
  List<UserDevice>? _memory;

  @override
  Future<Result<List<UserDevice>>> listUserDevices() async {
    // 内存命中：本次 App 生命周期内已成功加载过，直接返回。
    final cached = _memory;
    if (cached != null) return Result.ok(cached);

    // 网络请求。
    final result = await _remote.listUserDevices();
    final devices = result.valueOrNull;
    if (devices != null) {
      // 网络成功：填充内存缓存，异步刷新磁盘，不阻塞返回。
      _memory = devices;
      _cache.write(devices);
      return Result.ok(devices);
    }

    // 网络失败：尝试降级到磁盘缓存。
    final disk = await _cache.read();
    if (disk != null) return Result.ok(disk);

    // 磁盘也没有：透传网络失败原因。
    return result;
  }

  @override
  Future<Result<UserDevice>> bind(UserDeviceBindRequest request) async {
    final result = await _remote.bind(request);
    if (result.isSuccess) _memory = null; // 绑定成功，内存失效。
    return result;
  }

  @override
  Future<Result<void>> rename(int id, String customName) async {
    final result = await _remote.rename(id, customName);
    if (result.isSuccess) _memory = null; // 改名成功，内存失效。
    return result;
  }

  @override
  Future<Result<void>> unbind(int id) async {
    final result = await _remote.unbind(id);
    if (result.isSuccess) _memory = null; // 解绑成功，内存失效。
    return result;
  }

  /// 清除内存缓存；注销时由协调器调用，防止旧账号数据泄给新登录用户。
  ///
  /// 磁盘缓存不清除，保留冷启动兜底能力。
  @override
  void invalidateCache() {
    _memory = null;
  }
}
