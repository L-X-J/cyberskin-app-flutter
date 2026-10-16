// 可播放媒体快照：统一官方视频和本地文件，不依赖播放器或文件选择插件。

/// 一个会话内可播放的媒体；本地地址使用 file URI，不进入远端 API。
final class VideoMedia {
  /// 创建不可变媒体快照。
  const VideoMedia({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.coverUrl = '',
    this.width,
    this.height,
    this.coverWidth,
    this.coverHeight,
  });

  /// 媒体身份；播放器适配还会结合地址隔离同 ID 的资源替换。
  final String id;

  /// 用于播放器和列表的标题。
  final String title;

  /// HTTP(S) 或 file URI。
  final String videoUrl;

  /// 网络封面；本地文件使用首帧，不生成或上传封面。
  final String coverUrl;

  /// 已考虑旋转方向的展示宽度。
  final int? width;

  /// 已考虑旋转方向的展示高度。
  final int? height;

  /// 封面实际宽度。
  final int? coverWidth;

  /// 封面实际高度。
  final int? coverHeight;
}
