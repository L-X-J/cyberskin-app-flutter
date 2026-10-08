// 启动配置、CMS 页面和广告位的领域模型。

/// 一个法律或协议文档入口。
final class AppAgreement {
  /// 创建协议入口。
  const AppAgreement({this.code, this.title, this.contentUrl});

  /// 开放的协议代码。
  final String? code;

  /// 展示标题。
  final String? title;

  /// 发布文档地址。
  final String? contentUrl;
}

/// 后台驱动的 App 功能开关。
final class AppFeatureFlags {
  /// 创建功能开关；缺失开关均按 fail-closed 的 `false` 处理。
  const AppFeatureFlags({
    this.emailLoginEnabled = false,
    this.appleLoginEnabled = false,
    this.googleLoginEnabled = false,
    this.feedbackEnabled = false,
    this.officialVideoEnabled = false,
  });

  /// 是否开放邮箱验证码登录。
  final bool emailLoginEnabled;

  /// 是否开放 Apple 登录。
  final bool appleLoginEnabled;

  /// 是否开放 Google 登录。
  final bool googleLoginEnabled;

  /// 是否允许用户提交反馈。
  final bool feedbackEnabled;

  /// 是否展示官方视频。
  final bool officialVideoEnabled;
}

/// App 启动阶段读取的后台配置。
final class AppConfiguration {
  /// 创建启动配置。
  AppConfiguration({
    this.version,
    this.loggedIn = false,
    List<AppAgreement> agreements = const <AppAgreement>[],
    this.features = const AppFeatureFlags(),
  }) : agreements = List<AppAgreement>.unmodifiable(agreements);

  /// 服务端生成的配置版本。
  final String? version;

  /// 服务端确认的当前 App 会话状态；旧缓存缺失时按未登录处理。
  final bool loggedIn;

  /// 协议文档入口列表。
  final List<AppAgreement> agreements;

  /// 功能开关集合。
  final AppFeatureFlags features;
}

/// 后台发布的 CMS 页面。
final class CmsPage {
  /// 创建 CMS 页面。
  const CmsPage({
    this.id,
    this.code,
    this.titleEn,
    this.contentUrl,
    this.contentHtml,
  });

  /// 页面主键。
  final int? id;

  /// 页面代码。
  final String? code;

  /// 英文标题。
  final String? titleEn;

  /// 已发布 HTML 的对象地址。
  final String? contentUrl;

  /// 为旧客户端回填的 HTML。
  final String? contentHtml;
}

/// 一个有效投放窗口内的广告位条目。
final class AppAdvertisement {
  /// 创建广告条目。
  const AppAdvertisement({
    this.id,
    this.imageUrl,
    this.titleEn,
    this.subtitleEn,
    this.jumpType,
    this.jumpTarget,
    this.sort,
  });

  /// 广告主键。
  final int? id;

  /// 图片地址。
  final String? imageUrl;

  /// 英文标题。
  final String? titleEn;

  /// 英文副标题。
  final String? subtitleEn;

  /// 开放的跳转类型。
  final String? jumpType;

  /// 跳转目标。
  final String? jumpTarget;

  /// 服务端排序值。
  final int? sort;
}
