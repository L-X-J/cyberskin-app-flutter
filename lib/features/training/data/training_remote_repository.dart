// 训练课程 App API 的远端 Repository 实现。
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/result/result.dart';
import '../domain/entities/training.dart';
import '../domain/repositories/training_repository.dart';

/// TrainingRepository 的 App API 实现。
final class TrainingRemoteRepository extends BaseRemoteRepository
    implements TrainingRepository {
  /// 创建训练远端 Repository。
  TrainingRemoteRepository({
    required super.transport,
    required super.sessionStore,
  });

  @override
  Future<Result<List<TrainingSummary>>> listTrainings() =>
      request<List<TrainingSummary>>(
        AppApiOperation.listTrainings,
        decode: (data) =>
            ApiJson.objectList(data)
                .map(_decodeSummary)
                .toList(growable: false),
      );

  @override
  Future<Result<TrainingDetail>> getTraining(int id) => request<TrainingDetail>(
    AppApiOperation.trainingDetail,
    pathParameters: <String, Object?>{'id': id},
    decode: _decodeDetail,
  );

  /// 解码训练列表与详情共享的摘要字段。
  TrainingSummary _decodeSummary(Map<String, dynamic> json) => TrainingSummary(
    id: ApiJson.integer(json, 'id'),
    nameEn: ApiJson.string(json, 'nameEn'),
    coverUrl: ApiJson.string(json, 'coverUrl'),
    totalSeconds: ApiJson.integer(json, 'totalSeconds'),
    stageCount: ApiJson.integer(json, 'stageCount'),
    intensity: ApiJson.string(json, 'intensity'),
    sort: ApiJson.integer(json, 'sort'),
    deviceModelId: ApiJson.integer(json, 'deviceModelId'),
  );

  /// 解码训练详情，阶段协议保持开放以兼容后台新增控制字段。
  TrainingDetail _decodeDetail(Object? data) {
    final json = ApiJson.object(data);
    return TrainingDetail(
      summary: _decodeSummary(json),
      purposeHtml: ApiJson.string(json, 'purposeHtml'),
      stages: _decodeStages(json['stages']),
      customModes: _decodeCustomModes(json['customMode']),
    );
  }

  /// 解码可选阶段数组并冻结各阶段的开放协议对象。
  List<TrainingStage> _decodeStages(Object? value) => value == null
      ? const <TrainingStage>[]
      : ApiJson.objectList(
          value,
          field: 'stages',
        ).map(TrainingStage.new).toList(growable: false);

  /// 解码稳定 customMode 字段，同时保留未知字段供协议演进使用。
  List<TrainingCustomMode> _decodeCustomModes(Object? value) => value == null
      ? const <TrainingCustomMode>[]
      : ApiJson.objectList(value, field: 'customMode')
            .map(
              (json) => TrainingCustomMode(
                range: ApiJson.string(json, 'start-end'),
                description: ApiJson.string(json, 'des'),
                commandData: ApiJson.string(json, 'command_data'),
                additionalProperties: ApiJson.additionalProperties(
                  json,
                  <String>{'start-end', 'des', 'command_data'},
                ),
              ),
            )
            .toList(growable: false);
}
