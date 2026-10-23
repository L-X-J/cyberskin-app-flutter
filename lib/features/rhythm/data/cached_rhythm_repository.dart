// 节奏元数据的会话隔离缓存；完整 JSON 交给公共文件缓存，最长有效 30 天。
import '../../../core/error/app_failure.dart';
import '../../../core/result/result.dart';
import '../../control/data/common_program_file_cache.dart';
import '../domain/entities/rhythm.dart';
import '../domain/repositories/rhythm_repository.dart';
import 'rhythm_local_store.dart';

/// 列表只存摘要，详情必须成功取得完整 JSON 后才可编辑或播放。
final class CachedRhythmRepository implements RhythmRepository {
  /// 文件缓存由应用组装层共享给各类通用程序，不在页面创建。
  CachedRhythmRepository(this.remote, this.store, {required this.programFiles});

  /// 远端 CRUD 仅返回文件身份、快照和统计。
  final RhythmRepository remote;

  /// 当前登录会话可见的元数据快照。
  final RhythmLocalStore store;

  /// 节奏与 Training 可共用的 30 天原始 JSON 文件缓存。
  final CommonProgramFileCache programFiles;

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
              programUrl: r['programUrl'] as String?,
              totalSeconds: r['totalSeconds'] as int?,
              previewSegments: (r['previewSegments'] as List)
                  .map(
                    (s) => RhythmSegment(Map<String, dynamic>.from(s as Map)),
                  )
                  .toList(),
            ),
          )
          .toList();
    } on Object {
      return [];
    }
  }

  // 不在安全存储复制完整程序或签名 URL，避免绕过文件缓存的 30 天有效期。
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
            'programUrl': r.programUrl,
            'totalSeconds': r.totalSeconds,
            'previewSegments': r.previewSegments.map((s) => s.payload).toList(),
          },
        )
        .toList(),
  );

  Future<bool> _sameOwner(String? owner) async =>
      owner != null && await store.owner() == owner;

  Result<T> _signedOut<T>() => const Result.failure(
    AppFailure(
      code: FailureCode.unauthorized,
      message: 'Please sign in again.',
    ),
  );

  @override
  Future<Result<List<Rhythm>>> list({int? deviceModelId}) async {
    final owner = await store.owner();
    final result = await remote.list(deviceModelId: deviceModelId);
    if (!await _sameOwner(owner)) return _signedOut();
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
  Future<Result<Rhythm>> getById(int id, {bool loadProgram = true}) async {
    final owner = await store.owner();
    final result = await remote.getById(id);
    if (!await _sameOwner(owner)) return _signedOut();
    if (result.isSuccess) {
      final metadata = result.valueOrNull!;
      await _merge(owner, metadata);
      if (!loadProgram) return result;
      // 已取得新版元数据后下载失败不能回退为旧版程序。
      return _hydrate(metadata, owner, cachedOnly: false);
    }
    if (result.failureOrNull?.code == FailureCode.network) {
      final matches = (await _read(owner)).where((r) => r.id == id);
      if (matches.isNotEmpty) {
        if (!loadProgram) return Result.ok(matches.first);
        return _hydrate(matches.first, owner, cachedOnly: true);
      }
    }
    return result;
  }

  Future<Result<Rhythm>> _hydrate(
    Rhythm metadata,
    String? owner, {
    required bool cachedOnly,
  }) async {
    final url = metadata.programUrl;
    try {
      if (url == null || url.isEmpty) {
        throw const FormatException('Missing program JSON URL.');
      }
      final cues = cachedOnly
          ? await programFiles.readCached(url)
          : await programFiles.load(
              url: url,
              downloadUrl: metadata.programDownloadUrl ?? url,
            );
      if (cues == null) {
        return const Result.failure(
          AppFailure(
            code: FailureCode.network,
            message: 'Connect to the internet to download this rhythm.',
          ),
        );
      }
      var cursor = 0;
      for (final cue in cues) {
        if (cue.startSeconds != cursor || cue.durationSeconds > 1200) {
          throw const FormatException('Invalid rhythm timeline.');
        }
        cursor = cue.endSeconds;
      }
      if (cues.length > 30 ||
          cues.length != metadata.segmentCount ||
          cursor != metadata.totalSeconds) {
        throw const FormatException(
          'Rhythm JSON does not match its statistics.',
        );
      }
      if (!await _sameOwner(owner)) return _signedOut();
      return Result.ok(
        metadata.withProgram(
          cues.map((cue) => RhythmSegment(cue.toJson())).toList(),
        ),
      );
    } on FormatException catch (error) {
      if (url != null) await programFiles.remove(url);
      return Result.failure(
        AppFailure(
          code: FailureCode.invalidData,
          message: error.message,
          cause: error,
        ),
      );
    } on AppFailure catch (error) {
      return Result.failure(error);
    } on Object catch (error) {
      return Result.failure(
        AppFailure(
          code: FailureCode.network,
          message: 'Unable to download rhythm JSON. Please try again.',
          cause: error,
        ),
      );
    }
  }

  Future<void> _merge(String? owner, Rhythm rhythm) async => _write(owner, [
    rhythm,
    ...(await _read(owner)).where((r) => r.id != rhythm.id),
  ]);

  @override
  Future<Result<Rhythm>> create(RhythmCreateRequest request) async {
    final owner = await store.owner();
    final result = await remote.create(request);
    if (!await _sameOwner(owner)) return _signedOut();
    if (result.isSuccess) await _merge(owner, result.valueOrNull!);
    return result;
  }

  @override
  Future<Result<Rhythm>> update(int id, RhythmUpdateRequest request) async {
    final owner = await store.owner();
    final prior = (await _read(owner)).where((r) => r.id == id).firstOrNull;
    final result = await remote.update(id, request);
    if (!await _sameOwner(owner)) return _signedOut();
    if (result.isSuccess) {
      final value = result.valueOrNull!;
      await _merge(owner, value);
      if (prior?.programUrl != null && prior!.programUrl != value.programUrl) {
        await programFiles.remove(prior.programUrl!);
      }
    }
    return result;
  }

  @override
  Future<Result<void>> delete(int id) async {
    final owner = await store.owner();
    final prior = await _read(owner);
    final result = await remote.delete(id);
    if (!await _sameOwner(owner)) return _signedOut();
    if (result.isSuccess) {
      await _write(owner, prior.where((r) => r.id != id).toList());
      final url = prior.where((r) => r.id == id).firstOrNull?.programUrl;
      if (url != null) await programFiles.remove(url);
    }
    return result;
  }
}
