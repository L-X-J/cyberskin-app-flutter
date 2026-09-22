// 用户反馈与对象存储预签名 App API 的远端 Repository 实现。
import 'package:http/http.dart' as http;

import '../../../core/error/app_failure.dart';
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/network/json_decoder.dart';
import '../../../core/network/network_request_monitor.dart';
import '../../../core/result/result.dart';
import '../domain/entities/feedback.dart';
import '../domain/repositories/feedback_repository.dart';

/// FeedbackRepository 的 App API 实现。
final class FeedbackRemoteRepository extends BaseRemoteRepository
    implements FeedbackRepository {
  /// 创建反馈远端 Repository；[byteUploader] 支持在测试中替换原始 PUT。
  FeedbackRemoteRepository({
    required super.transport,
    required super.sessionStore,
    required this._byteUploader,
    required this._monitor,
  });

  /// 对预签名对象存储 URL 发送原始字节的可替换函数。
  final Future<http.Response> Function(
    String url,
    List<int> bytes,
    String contentType,
  )
  _byteUploader;

  /// 预签名上传同样使用的无敏感数据请求状态监控服务。
  final NetworkRequestMonitor _monitor;

  @override
  Future<Result<FeedbackUploadTicket>> presign(
    FeedbackAttachmentRequest attachmentRequest,
  ) {
    final body = <String, Object?>{
      'filename': attachmentRequest.filename,
      'contentType': attachmentRequest.contentType,
    };
    final size = attachmentRequest.size;
    if (size != null) {
      body['size'] = size;
    }
    return request<FeedbackUploadTicket>(
      AppApiOperation.presignUpload,
      body: body,
      decode: _decodeTicket,
    );
  }

  @override
  Future<Result<void>> uploadBytes(
    FeedbackUploadTicket ticket,
    List<int> bytes, {
    required String contentType,
  }) async {
    final uploadUrl = ticket.uploadUrl;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      return const Result.failure(
        AppFailure(code: FailureCode.invalidData, message: '预签名上传地址缺失。'),
      );
    }
    final uploadUri = Uri.tryParse(uploadUrl);
    final started = _monitor.start(
      operation: 'presignedUpload',
      method: 'PUT',
      path: uploadUri?.path.isNotEmpty == true ? uploadUri!.path : '/unknown',
    );
    try {
      final response = await _byteUploader(uploadUrl, bytes, contentType);
      _monitor.finish(
        started,
        httpStatus: response.statusCode,
        errorMessage: response.statusCode >= 200 && response.statusCode < 300
            ? null
            : '附件上传失败。',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const Result.ok(null);
      }
      return Result.failure(
        AppFailure(
          code: FailureCode.network,
          message: '附件上传失败。',
          httpStatus: response.statusCode,
        ),
      );
    } on Object catch (error) {
      _monitor.finish(started, errorMessage: '附件上传未能完成。');
      return Result.failure(
        AppFailure(
          code: FailureCode.network,
          message: '附件上传未能完成。',
          cause: error,
        ),
      );
    }
  }

  @override
  Future<Result<FeedbackAttachment>> completeUpload(
    String objectKey, {
    String? contentType,
    int? size,
  }) {
    final body = <String, Object?>{'objectKey': objectKey};
    if (contentType != null) {
      body['contentType'] = contentType;
    }
    if (size != null) {
      body['size'] = size;
    }
    return request<FeedbackAttachment>(
      AppApiOperation.completeUpload,
      body: body,
      decode: _decodeAttachment,
    );
  }

  @override
  Future<Result<int>> createFeedback(FeedbackCreateRequest feedbackRequest) =>
      request<int>(
        AppApiOperation.createFeedback,
        body: <String, Object?>{
          'content': feedbackRequest.content,
          if (feedbackRequest.imageUrls.isNotEmpty)
            'imageUrls': feedbackRequest.imageUrls,
        },
        decode: (Object? data) {
          if (data is int) return data;
          if (data is num && data == data.roundToDouble()) return data.toInt();
          if (data is String) {
            final parsed = int.tryParse(data);
            if (parsed != null) return parsed;
          }
          throw const FormatException('反馈记录 ID 必须是整数。');
        },
      );

  /// 解码短时上传票据；上传地址只在调用期使用，不进入持久化存储。
  FeedbackUploadTicket _decodeTicket(Object? data) {
    final json = ApiJson.object(data);
    return FeedbackUploadTicket(
      uploadUrl: ApiJson.string(json, 'uploadUrl'),
      objectKey: ApiJson.string(json, 'objectKey'),
      accessUrl: ApiJson.string(json, 'accessUrl'),
      expireSeconds: ApiJson.integer(json, 'expireSeconds'),
    );
  }

  /// 解码服务端根据对象存储真实元数据确认的附件信息。
  FeedbackAttachment _decodeAttachment(Object? data) {
    final json = ApiJson.object(data);
    return FeedbackAttachment(
      accessUrl: ApiJson.string(json, 'accessUrl'),
      objectKey: ApiJson.string(json, 'objectKey'),
      size: ApiJson.integer(json, 'size'),
      contentType: ApiJson.string(json, 'contentType'),
    );
  }
}
