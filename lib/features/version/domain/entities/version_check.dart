// App 版本检查的领域模型。

/// 后台返回的可用版本检查结果。
final class VersionCheck {
  /// 创建版本检查结果；空对象代表后端暂无发布版本。
  const VersionCheck({
    this.platform,
    this.versionName,
    this.versionCode,
    this.minimumSupportedVersion,
    this.forceUpdate = false,
    this.releaseNotesEn,
    this.packageUrl,
    this.publishedAt,
    this.hasUpdate = false,
  });

  /// 版本适用的平台标识。
  final String? platform;

  /// 版本展示名称。
  final String? versionName;

  /// 版本号。
  final int? versionCode;

  /// 最低支持版本号。
  final int? minimumSupportedVersion;

  /// 是否必须升级；缺失字段按 false 处理。
  final bool forceUpdate;

  /// 英文更新说明。
  final String? releaseNotesEn;

  /// 安装包地址。
  final String? packageUrl;

  /// 发布时间。
  final DateTime? publishedAt;

  /// 是否存在可更新版本；缺失字段按 false 处理。
  final bool hasUpdate;
}
