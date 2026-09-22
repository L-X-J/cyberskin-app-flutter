// 官方视频领域模型与分页结果。

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
