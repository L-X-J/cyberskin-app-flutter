// 自定义节奏 App API 的远端 Repository 实现。
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/result/result.dart';
import '../domain/entities/rhythm.dart';
import '../domain/repositories/rhythm_repository.dart';

/// RhythmRepository 的 App API 实现。
final class RhythmRemoteRepository extends BaseRemoteRepository
    implements RhythmRepository {
  /// 创建节奏远端 Repository。
  RhythmRemoteRepository({
    required super.transport,
    required super.sessionStore,
  });

  @override
  Future<Result<List<Rhythm>>> list({int? deviceModelId}) =>
      request<List<Rhythm>>(
        AppApiOperation.listRhythms,
        queryParameters: <String, Object?>{'deviceModelId': deviceModelId},
        decode: (data) =>
            ApiJson.objectList(data).map(_decodeRhythm).toList(growable: false),
      );

  @override
  Future<Result<Rhythm>> getById(int id) => request<Rhythm>(
    AppApiOperation.rhythmDetail,
    pathParameters: <String, Object?>{'id': id},
    decode: _decodeRhythmObject,
  );

  @override
  Future<Result<Rhythm>> create(RhythmCreateRequest request) =>
      this.request<Rhythm>(
        AppApiOperation.createRhythm,
        body: <String, Object?>{
          'deviceModelId': request.deviceModelId,
          'name': request.name,
          'segments': request.segments.map((item) => item.payload).toList(),
        },
        decode: _decodeRhythmObject,
      );

  @override
  Future<Result<Rhythm>> update(int id, RhythmUpdateRequest request) =>
      this.request<Rhythm>(
        AppApiOperation.updateRhythm,
        pathParameters: <String, Object?>{'id': id},
        body: <String, Object?>{
          if (request.deviceModelId != null)
            'deviceModelId': request.deviceModelId,
          if (request.name != null) 'name': request.name,
          if (request.segments != null)
            'segments': request.segments!.map((item) => item.payload).toList(),
        },
        decode: _decodeRhythmObject,
      );

  @override
  Future<Result<void>> delete(int id) => requestVoid(
    AppApiOperation.deleteRhythm,
    pathParameters: <String, Object?>{'id': id},
  );

  /// 将单条节奏响应转换为领域模型。
  Rhythm _decodeRhythmObject(Object? data) =>
      _decodeRhythm(ApiJson.object(data));

  /// 解码开放节奏片段协议，并复制为不可变值对象。
  Rhythm _decodeRhythm(Map<String, dynamic> json) {
    final rawSegments = json['segments'];
    return Rhythm(
      id: ApiJson.integer(json, 'id'),
      deviceModelId: ApiJson.integer(json, 'deviceModelId'),
      name: ApiJson.string(json, 'name'),
      segmentCount: ApiJson.integer(json, 'segmentCount'),
      createTime: DateTime.tryParse('${json['createTime'] ?? ''}'),
      deviceModelName: ApiJson.string(json, 'deviceModelName'),
      segments: rawSegments == null
          ? const <RhythmSegment>[]
          : ApiJson.objectList(
              rawSegments,
              field: 'segments',
            ).map(RhythmSegment.new).toList(growable: false),
    );
  }
}
