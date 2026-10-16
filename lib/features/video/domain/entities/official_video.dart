// 官方视频领域模型与分页结果。
import 'video_media.dart';

/// 一个后台发布的官方视频条目。
final class OfficialVideo {
  /// 创建官方视频条目。
  const OfficialVideo({
    this.id,
    this.titleEn,
    this.coverUrl,
    this.videoUrl,
    this.durationSeconds,
    this.sort,
    this.videoWidth,
    this.videoHeight,
    this.videoCoverWidth,
    this.videoCoverHeight,
  });

  /// 视频主键。
  final int? id;

  /// 英文标题。
  final String? titleEn;

  /// 封面地址。
  final String? coverUrl;

  /// 播放地址。
  final String? videoUrl;

  /// 时长（秒）。
  final int? durationSeconds;

  /// 服务端排序值。
  final int? sort;

  /// 服务端提供的视频展示宽度。
  final int? videoWidth;

  /// 服务端提供的视频展示高度。
  final int? videoHeight;

  /// 服务端提供的封面实际宽度。
  final int? videoCoverWidth;

  /// 服务端提供的封面实际高度。
  final int? videoCoverHeight;

  /// 转为播放快照；API 解码已保证上架视频的必需字段完整。
  VideoMedia get media => VideoMedia(
    id: '$id',
    title: titleEn ?? '',
    videoUrl: videoUrl ?? '',
    coverUrl: coverUrl ?? '',
    width: videoWidth,
    height: videoHeight,
    coverWidth: videoCoverWidth,
    coverHeight: videoCoverHeight,
  );
}

/// 官方视频分页结果。
final class OfficialVideoPage {
  /// 创建分页结果。
  OfficialVideoPage({
    this.total,
    List<OfficialVideo> rows = const <OfficialVideo>[],
  }) : rows = List<OfficialVideo>.unmodifiable(rows);

  /// 符合条件的总记录数。
  final int? total;

  /// 当前页视频列表。
  final List<OfficialVideo> rows;
}
