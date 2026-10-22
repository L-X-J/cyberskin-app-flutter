// 节奏远端访问的缓存装饰器；只在网络失败时读缓存，写入以服务端成功为准。
import '../../../core/error/app_failure.dart';
import '../../../core/result/result.dart';
import '../domain/entities/rhythm.dart';
import '../domain/repositories/rhythm_repository.dart';
import 'rhythm_local_store.dart';

/// 以远端结果为准，仅网络失败时读取当前登录会话的节奏缓存。
final class CachedRhythmRepository implements RhythmRepository {
  /// 创建实例；依赖及初始状态由调用方提供。
  CachedRhythmRepository(this.remote, this.store);

  /// 已有远端 CRUD 实现，缓存不改变其错误语义。
  final RhythmRepository remote;

  /// 会话隔离的安全缓存。
  final RhythmLocalStore store;
  Future<List<Rhythm>> _read(String? owner) async {
    try {
      final rows = await store.read('library', owner) as List? ?? [];
      return rows
          .cast<Map<String, dynamic>>()
          .map(
            (r) => Rhythm(
              id: r['id'] as int?,
              deviceModelId: r['deviceModelId'] as int?,
              name: r['name'] as String?,
              deviceModelName: r['deviceModelName'] as String?,
              createTime: DateTime.tryParse('${r['createTime']}'),
              segmentCount: r['segmentCount'] as int?,
              segments: (r['segments'] as List)
                  .map(
                    (s) => RhythmSegment(Map<String, dynamic>.from(s as Map)),
                  )
                  .toList(),
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // 缓存只保存远端确认的数据，不把离线草稿当作云端结果。
  Future<void> _write(String? owner, List<Rhythm> rhythms) => store.write(
    'library',
    owner,
    rhythms
        .map(
          (r) => {
            'id': r.id,
            'deviceModelId': r.deviceModelId,
            'name': r.name,
            'deviceModelName': r.deviceModelName,
            'createTime': r.createTime?.toIso8601String(),
            'segmentCount': r.segmentCount,
            'segments': r.segments.map((s) => s.payload).toList(),
          },
        )
        .toList(),
  );
  @override
  Future<Result<List<Rhythm>>> list({int? deviceModelId}) async {
    final owner = await store.owner();
    final result = await remote.list(deviceModelId: deviceModelId);
    if (owner == null || await store.owner() != owner) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.unauthorized,
          message: 'Please sign in again.',
        ),
      );
    }
    if (result.isSuccess) {
      final values = result.valueOrNull!;
      final prior = deviceModelId == null
          ? <Rhythm>[]
          : (await _read(owner))
                .where((r) => r.deviceModelId != deviceModelId)
                .toList();
      await _write(owner, [...prior, ...values]);
    } else if (result.failureOrNull?.code == FailureCode.network) {
      final cached = await _read(owner);
      if (cached.isNotEmpty) {
        return Result.ok(
          cached
              .where(
                (r) =>
                    deviceModelId == null || r.deviceModelId == deviceModelId,
              )
              .toList(),
        );
      }
    }
    return result;
  }

  @override
  Future<Result<Rhythm>> getById(int id) async {
    final owner = await store.owner();
    final result = await remote.getById(id);
    if (owner == null || await store.owner() != owner) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.unauthorized,
          message: 'Please sign in again.',
        ),
      );
    }
    if (result.isSuccess) await _merge(owner, result.valueOrNull!);
    if (result.failureOrNull?.code == FailureCode.network) {
      final matches = (await _read(owner)).where((r) => r.id == id);
      if (matches.isNotEmpty) return Result.ok(matches.first);
    }
    return result;
  }

  Future<void> _merge(String? owner, Rhythm rhythm) async => _write(owner, [
    rhythm,
    ...(await _read(owner)).where((r) => r.id != rhythm.id),
  ]);
  @override
  Future<Result<Rhythm>> create(RhythmCreateRequest request) async {
    final owner = await store.owner();
    final result = await remote.create(request);
    if (owner == null || await store.owner() != owner) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.unauthorized,
          message: 'Please sign in again.',
        ),
      );
    }
    if (result.isSuccess) await _merge(owner, result.valueOrNull!);
    return result;
  }

  @override
  Future<Result<Rhythm>> update(int id, RhythmUpdateRequest request) async {
    final owner = await store.owner();

    final result = await remote.update(id, request);
    if (owner == null || await store.owner() != owner) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.unauthorized,
          message: 'Please sign in again.',
        ),
      );
    }
    if (result.isSuccess) await _merge(owner, result.valueOrNull!);
    return result;
  }

  @override
  Future<Result<void>> delete(int id) async {
    final owner = await store.owner();

    final result = await remote.delete(id);
    if (owner == null || await store.owner() != owner) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.unauthorized,
          message: 'Please sign in again.',
        ),
      );
    }
    if (result.isSuccess) {
      await _write(
        owner,
        (await _read(owner)).where((r) => r.id != id).toList(),
      );
    }
    return result;
  }
}
