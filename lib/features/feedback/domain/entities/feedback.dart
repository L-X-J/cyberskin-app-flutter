// 用户反馈与预签名附件上传的领域模型。

/// 请求反馈附件预签名上传的输入值对象。
final class FeedbackAttachmentRequest {
  /// 创建附件上传请求。
  const FeedbackAttachmentRequest({
    required this.filename,
    required this.contentType,
    this.size,
  });

  /// 原始文件名。
  final String filename;

  /// 图片 MIME 类型。
  final String contentType;

  /// 可选的本地字节数声明。
  final int? size;
}

/// 服务端签发的短时原始字节 PUT 地址。
final class FeedbackUploadTicket {
  /// 创建预签名上传凭据。
  const FeedbackUploadTicket({
    this.uploadUrl,
    this.objectKey,
    this.accessUrl,
    this.expireSeconds,
  });

  /// 对象存储短时 PUT URL。
  final String? uploadUrl;

  /// 需要原样回传给完成接口的对象键。
  final String? objectKey;

  /// 预期公开访问地址。
  final String? accessUrl;

  /// 上传 URL 有效期（秒）。
  final int? expireSeconds;
}

/// 对象存储已确认的附件元数据。
final class FeedbackAttachment {
  /// 创建已完成确认的反馈附件。
  const FeedbackAttachment({
    this.accessUrl,
    this.objectKey,
    this.size,
    this.contentType,
  });

  /// 公共访问地址。
  final String? accessUrl;

  /// 对象存储键。
  final String? objectKey;

  /// 服务端 HeadObject 读取的真实字节数。
  final int? size;

  /// 服务端确认的 MIME 类型。
  final String? contentType;
}

/// 用户反馈提交内容。
final class FeedbackCreateRequest {
  /// 创建用户反馈提交请求。
  FeedbackCreateRequest({
    required this.content,
    List<String> imageUrls = const <String>[],
  }) : imageUrls = List<String>.unmodifiable(imageUrls);

  /// 反馈正文。
  final String content;

  /// 已确认上传的图片访问地址。
  final List<String> imageUrls;
}
