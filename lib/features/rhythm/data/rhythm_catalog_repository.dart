// 聚合已绑定型号和后台能力，并缓存离线运行所需的最小能力快照。
import '../../../core/error/app_failure.dart';
import '../../../core/result/result.dart';
import '../../device/domain/repositories/device_catalog_repository.dart';
import '../../device/domain/repositories/user_device_repository.dart';
import '../domain/entities/rhythm_program.dart';
import '../domain/repositories/rhythm_catalog.dart';
import 'rhythm_local_store.dart';

/// 为编辑器提供已绑定型号，为执行器提供已发布能力。
final class RhythmCatalogRepository implements RhythmCatalog {
  /// 创建实例；依赖及初始状态由调用方提供。
  RhythmCatalogRepository(this.devices, this.catalog, this.store);

  /// 当前账号设备绑定数据源。
  final UserDeviceRepository devices;

  /// 已绑定型号及已发布能力的访问边界。
  final DeviceCatalogRepository catalog;

  /// 会话隔离的安全缓存。
  final RhythmLocalStore store;
  @override
  Future<Result<List<RhythmModel>>> models() => _protect(() async {
    final owner = await store.owner();
    final result = await devices.listUserDevices();
    if (owner == null || await store.owner() != owner) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.unauthorized,
          message: 'Please sign in again.',
        ),
      );
    }
    if (result.isSuccess) {
      final names = <int, String>{};
      for (final d in result.valueOrNull!) {
        if (d.deviceModelId != null) {
          names[d.deviceModelId!] = d.modelName ?? 'Device ${d.deviceModelId}';
        }
      }

      final models = names.entries
          .map((e) => RhythmModel(e.key, e.value))
          .toList();
      await store.write(
        'models',
        owner,
        models.map((m) => {'id': m.id, 'name': m.name}).toList(),
      );
      return Result.ok(models);
    }
    if (result.failureOrNull?.code == FailureCode.network) {
      final raw = await store.read('models', owner);
      if (raw is List) {
        return Result.ok(
          raw
              .cast<Map<String, dynamic>>()
              .map((m) => RhythmModel(m['id'] as int, m['name'] as String))
              .toList(),
        );
      }
    }
    return Result.failure(result.failureOrNull!);
  });

  @override
  Future<Result<List<RhythmChannelCapability>>> capabilities(int modelId) =>
      _protect(() async {
        final owner = await store.owner();
        final result = await catalog.getDeviceModelDetail(modelId);
        if (owner == null || await store.owner() != owner) {
          return const Result.failure(
            AppFailure(
              code: FailureCode.unauthorized,
              message: 'Please sign in again.',
            ),
          );
        }
        if (result.isSuccess) {
          final caps = RhythmChannelCapability.fromModel(result.valueOrNull!);
          await store.write(
            'model.$modelId',
            owner,
            caps
                .map(
                  (c) => {
                    'channel': c.channel.name,
                    'modes': c.modes,
                    'variableSpeed': c.variableSpeed,
                    'gearMax': c.gearMax,
                    'defaultValue': c.defaultValue,
                  },
                )
                .toList(),
          );
          return Result.ok(caps);
        }
        if (result.failureOrNull?.code == FailureCode.network) {
          final raw = await store.read('model.$modelId', owner);
          if (raw is List) {
            return Result.ok(
              raw
                  .cast<Map<String, dynamic>>()
                  .map(
                    (c) => RhythmChannelCapability(
                      channel: RhythmChannel.parse(c['channel'] as String),
                      modes: List<String>.from(c['modes'] as List),
                      variableSpeed: c['variableSpeed'] == true,
                      gearMax: c['gearMax'] as int?,
                      defaultValue: c['defaultValue'] as int,
                    ),
                  )
                  .toList(),
            );
          }
        }
        return Result.failure(result.failureOrNull!);
      });

  Future<Result<T>> _protect<T>(Future<Result<T>> Function() load) async {
    try {
      return await load();
    } catch (_) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.invalidData,
          message: 'Device settings could not be read. Please refresh and try again.',
        ),
      );
    }
  }
}
