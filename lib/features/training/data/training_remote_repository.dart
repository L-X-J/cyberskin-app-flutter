// 训练课程 App API 的远端 Repository 实现。
import '../../../core/error/app_failure.dart';
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/result/result.dart';
import '../../control/data/common_program_file_cache.dart';
import '../domain/entities/training.dart';
import '../domain/repositories/training_repository.dart';

/// TrainingRepository 的 App API 实现。
final class TrainingRemoteRepository extends BaseRemoteRepository
    implements TrainingRepository {
  /// 创建训练远端 Repository。
  TrainingRemoteRepository({
    required super.transport,
    required super.sessionStore,
    required this.programFiles,
  });

  /// 与 rhythm 共享的原始 JSON 文件缓存，仅由 Start 请求读取。
  final CommonProgramFileCache programFiles;

  @override
  Future<Result<List<TrainingSummary>>> listTrainings({int? deviceModelId}) =>
      request<List<TrainingSummary>>(
        AppApiOperation.listTrainings,
        queryParameters: {'deviceModelId': ?deviceModelId},
        decode: (data) =>
            ApiJson.objectList(data).map(decodeSummary).toList(growable: false),
      );

  @override
  Future<Result<TrainingDetail>> getTraining(int id) => request<TrainingDetail>(
    AppApiOperation.trainingDetail,
    pathParameters: <String, Object?>{'id': id},
    decode: _decodeDetail,
  );

  /// 解码训练列表与详情共享的摘要字段。
  static TrainingSummary decodeSummary(Map<String, dynamic> json) =>
      /// 创建训练展示组件。
      TrainingSummary(
        id: ApiJson.integer(json, 'id'),
        nameEn: ApiJson.string(json, 'nameEn'),
        coverUrl: ApiJson.string(json, 'coverUrl'),
        totalSeconds: ApiJson.integer(json, 'totalSeconds'),
        stageCount: ApiJson.integer(json, 'stageCount'),
        intensity: ApiJson.string(json, 'intensity'),
        sort: ApiJson.integer(json, 'sort'),
        deviceModelId: ApiJson.integer(json, 'deviceModelId'),
      );

  /// 解码详情元数据和最多 3 段预览，不在此阶段下载完整程序。
  TrainingDetail _decodeDetail(Object? data) {
    final json = ApiJson.object(data);
    return TrainingDetail(
      summary: decodeSummary(json),
      purposeSummary: ApiJson.string(json, 'purposeSummary'),
      purposeUrl: ApiJson.string(json, 'purposeUrl'),
      programUrl: ApiJson.string(json, 'programUrl'),
      programDownloadUrl: ApiJson.string(json, 'programDownloadUrl'),
      previewSegments: _decodeCustomModes(json['previewSegments'])
          .take(3)
          .toList(),
    );
  }

  @override
  Future<Result<String>> loadPurpose(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.userInfo.isNotEmpty) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.invalidData,
          message: 'Training purpose address is invalid.',
        ),
      );
    }
    try {
      final html = await transport.fetchText(uri);
      if (html.trim().isEmpty) {
        throw const FormatException('Training purpose is empty.');
      }
      return Result.ok(html);
    } on FormatException catch (failure) {
      return Result.failure(
        AppFailure(
          code: FailureCode.invalidData,
          message: failure.message,
          cause: failure,
        ),
      );
    } on Object catch (failure) {
      return Result.failure(
        AppFailure(
          code: FailureCode.network,
          message: 'Unable to load training purpose. Please try again.',
          cause: failure,
        ),
      );
    }
  }

  /// 解码稳定 customMode 字段，同时保留未知字段供协议演进使用。
  List<TrainingCustomMode> _decodeCustomModes(Object? value) => value == null
      ? const <TrainingCustomMode>[]
      : ApiJson.objectList(value, field: 'previewSegments')
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

  @override
  Future<Result<TrainingDetail>> loadProgram(TrainingDetail metadata) async {
    var selected = metadata;
    var url = selected.programUrl;
    try {
      if (url == null || url.isEmpty || selected.summary.id == null) {
        throw const FormatException(
          'Training JSON is unavailable. Please republish this course.',
        );
      }
      var cues = await programFiles.readCached(url);
      if (cues == null) {
        // 预览可能停留超过签名有效期；下载前刷新详情，但绝不回退到旧版本文件。
        final refreshed = await getTraining(selected.summary.id!);
        if (refreshed.isFailure) {
          return Result.failure(refreshed.failureOrNull!);
        }
        selected = refreshed.valueOrNull!;
        if (selected.summary.id != metadata.summary.id) {
          throw const FormatException(
            'Training response does not match this course.',
          );
        }
        url = selected.programUrl;
        if (url == null || url.isEmpty || selected.programDownloadUrl == null) {
          throw const FormatException(
            'Training JSON is unavailable. Please republish this course.',
          );
        }
        cues = await programFiles.load(
          url: url,
          downloadUrl: selected.programDownloadUrl!,
        );
      }
      var cursor = 0;
      for (final cue in cues) {
        if (cue.startSeconds < cursor) {
          throw const FormatException(
            'Training timeline overlaps or is out of order.',
          );
        }
        cursor = cue.endSeconds;
      }
      if (cues.isEmpty ||
          cues.length > 200 ||
          cues.length != selected.summary.stageCount ||
          cursor != selected.summary.totalSeconds) {
        throw const FormatException(
          'Training JSON does not match its statistics. Please republish this course.',
        );
      }
      return Result.ok(
        selected.withProgram(
          cues
              .map(
                (cue) => TrainingCustomMode(
                  range: cue.toJson()['start-end'] as String,
                  description: cue.description,
                  commandData: cue.command.toString(),
                  additionalProperties: const {},
                ),
              )
              .toList(),
        ),
      );
    } on FormatException catch (failure) {
      if (url != null) await programFiles.remove(url);
      return Result.failure(
        AppFailure(
          code: FailureCode.invalidData,
          message: failure.message,
          cause: failure,
        ),
      );
    } on AppFailure catch (failure) {
      return Result.failure(failure);
    } on Object catch (failure) {
      return Result.failure(
        AppFailure(
          code: FailureCode.network,
          message: 'Unable to download training JSON. Please try again.',
          cause: failure,
        ),
      );
    }
  }
}
