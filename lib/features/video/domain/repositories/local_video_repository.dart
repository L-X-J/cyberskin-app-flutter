// 系统本地视频选择的领域契约；不暴露平台文件句柄或插件类型。
import '../../../../core/result/result.dart';
import '../entities/video_media.dart';

/// 本地视频的两种系统选择入口。
enum LocalVideoSource {
  /// 系统相册单选视频。
  gallery,
  /// 系统文件选择器。
  files,
}

/// 用户授权后的单文件访问，不扫描相册或上传本地内容。
abstract interface class LocalVideoRepository {
  /// 成功返回媒体；用户取消返回成功的 null，权限或系统失败返回显式错误。
  Future<Result<VideoMedia?>> choose(LocalVideoSource source);
}
