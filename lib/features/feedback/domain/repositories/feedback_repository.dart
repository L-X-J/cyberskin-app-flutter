// 用户反馈与附件上传的领域访问抽象。
import '../../../../core/result/result.dart';
import '../entities/feedback.dart';

/// 用户反馈数据的领域访问入口。
abstract interface class FeedbackRepository {
  /// 请求一个反馈图片的短时预签名上传凭据。
  Future<Result<FeedbackUploadTicket>> presign(
    FeedbackAttachmentRequest request,
  );

  /// 将原始图片字节 PUT 到预签名地址。
  Future<Result<void>> uploadBytes(
    FeedbackUploadTicket ticket,
    List<int> bytes, {
    required String contentType,
  });

  /// 让服务端确认对象存储内的真实文件元数据。
  Future<Result<FeedbackAttachment>> completeUpload(
    String objectKey, {
    String? contentType,
    int? size,
  });

  /// 提交一条用户反馈并返回新记录主键。
  Future<Result<int>> createFeedback(FeedbackCreateRequest request);
}
