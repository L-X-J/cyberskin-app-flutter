// App OpenAPI 操作注册表，集中维护路径、方法与鉴权元数据。

/// App API 支持的 HTTP 请求方法。
enum ApiHttpMethod {
  /// GET 请求。
  get,

  /// POST 请求。
  post,

  /// PUT 请求。
  put,

  /// DELETE 请求。
  delete,
}

/// OpenAPI `docs/openapi/app-openapi.json` 中的全部 App 操作标识。
enum AppApiOperation {
  /// 获取节奏详情。
  rhythmDetail,

  /// 更新节奏。
  updateRhythm,

  /// 删除节奏。
  deleteRhythm,

  /// 重命名用户绑定设备。
  renameUserDevice,

  /// 解绑用户设备。
  unbindUserDevice,

  /// 更新当前用户资料。
  updateProfile,

  /// 获取节奏列表。
  listRhythms,

  /// 创建节奏。
  createRhythm,

  /// 获取对象存储预签名地址。
  presignUpload,

  /// 确认对象存储上传完成。
  completeUpload,

  /// 获取用户设备绑定列表。
  listUserDevices,

  /// 绑定用户设备。
  bindUserDevice,

  /// 创建用户反馈。
  createFeedback,

  /// 远端登出。
  logout,

  /// Google 登录。
  googleLogin,

  /// 发送邮箱验证码。
  sendEmailCode,

  /// 邮箱验证码登录。
  emailLogin,

  /// Apple 登录。
  appleLogin,

  /// 获取官方视频分页。
  officialVideos,

  /// 检查 App 版本。
  checkVersion,

  /// 获取训练列表。
  listTrainings,

  /// 获取训练详情。
  trainingDetail,

  /// 获取设备型号列表。
  listDeviceModels,

  /// 获取设备型号详情。
  deviceModelDetail,

  /// 获取设备说明书。
  deviceManual,

  /// 获取启动配置。
  appConfig,

  /// 获取 CMS 页面。
  cmsPage,

  /// 获取当前用户。
  currentUser,

  /// 获取广告列表。
  listAds,
}

/// 单项 App API 的静态传输契约。
final class AppApiOperationSpec {
  /// 创建操作传输契约。
  const AppApiOperationSpec({
    required this.method,
    required this.path,
    required this.requiresAuthentication,
    this.allowsSessionCredentials = false,
  });

  /// HTTP 方法。
  final ApiHttpMethod method;

  /// 带 `{name}` 占位符的相对路径。
  final String path;

  /// 是否必须同时附带 Bearer token 与 `clientid`。
  final bool requiresAuthentication;

  /// 公开接口是否应在本地存在会话时附带会话头。
  final bool allowsSessionCredentials;
}

/// App OpenAPI 的受控代码化索引。
///
/// 这不是第二份可手改的接口文档；每次 OpenAPI 更新后由契约测试强制校验，
/// 使数据层无法在新增或删除接口时静默漂移。
abstract final class AppApiOperations {
  /// 返回 [operation] 的路径、方法和鉴权要求。
  static AppApiOperationSpec spec(AppApiOperation operation) =>
      _specs[operation]!;

  /// OpenAPI 29 个操作到稳定传输契约的私有映射。
  static const Map<AppApiOperation, AppApiOperationSpec> _specs =
      <AppApiOperation, AppApiOperationSpec>{
        /// 查询当前用户某条自定义节奏的详情。
        AppApiOperation.rhythmDetail: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/rhythms/{id}',
          requiresAuthentication: true,
        ),

        /// 部分更新当前用户的一条自定义节奏。
        AppApiOperation.updateRhythm: AppApiOperationSpec(
          method: ApiHttpMethod.put,
          path: '/app/v1/rhythms/{id}',
          requiresAuthentication: true,
        ),

        /// 软删除当前用户的一条自定义节奏。
        AppApiOperation.deleteRhythm: AppApiOperationSpec(
          method: ApiHttpMethod.delete,
          path: '/app/v1/rhythms/{id}',
          requiresAuthentication: true,
        ),

        /// 修改当前用户绑定设备的自定义名称。
        AppApiOperation.renameUserDevice: AppApiOperationSpec(
          method: ApiHttpMethod.put,
          path: '/app/v1/me/devices/{id}',
          requiresAuthentication: true,
        ),

        /// 解绑当前用户名下的一条设备记录。
        AppApiOperation.unbindUserDevice: AppApiOperationSpec(
          method: ApiHttpMethod.delete,
          path: '/app/v1/me/devices/{id}',
          requiresAuthentication: true,
        ),

        /// 更新当前用户昵称和头像资料。
        AppApiOperation.updateProfile: AppApiOperationSpec(
          method: ApiHttpMethod.put,
          path: '/app/v1/auth/profile',
          requiresAuthentication: true,
        ),

        /// 查询当前用户的自定义节奏列表。
        AppApiOperation.listRhythms: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/rhythms',
          requiresAuthentication: true,
        ),

        /// 为当前用户创建一条自定义节奏。
        AppApiOperation.createRhythm: AppApiOperationSpec(
          method: ApiHttpMethod.post,
          path: '/app/v1/rhythms',
          requiresAuthentication: true,
        ),

        /// 获取附件上传的短时对象存储预签名地址。
        AppApiOperation.presignUpload: AppApiOperationSpec(
          method: ApiHttpMethod.post,
          path: '/app/v1/oss/presign',
          requiresAuthentication: true,
        ),

        /// 确认预签名附件已经上传并读取其真实元数据。
        AppApiOperation.completeUpload: AppApiOperationSpec(
          method: ApiHttpMethod.post,
          path: '/app/v1/oss/complete',
          requiresAuthentication: true,
        ),

        /// 查询当前用户已经绑定的设备列表。
        AppApiOperation.listUserDevices: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/me/devices',
          requiresAuthentication: true,
        ),

        /// 为当前用户绑定一个已发布的设备型号。
        AppApiOperation.bindUserDevice: AppApiOperationSpec(
          method: ApiHttpMethod.post,
          path: '/app/v1/me/devices',
          requiresAuthentication: true,
        ),

        /// 提交当前用户的一条反馈记录。
        AppApiOperation.createFeedback: AppApiOperationSpec(
          method: ApiHttpMethod.post,
          path: '/app/v1/feedbacks',
          requiresAuthentication: true,
        ),

        /// 注销当前 App 会话。
        AppApiOperation.logout: AppApiOperationSpec(
          method: ApiHttpMethod.post,
          path: '/app/v1/auth/logout',
          requiresAuthentication: true,
        ),

        /// 使用 Google ID token 登录或注册。
        AppApiOperation.googleLogin: AppApiOperationSpec(
          method: ApiHttpMethod.post,
          path: '/app/v1/auth/google',
          requiresAuthentication: false,
        ),

        /// 向指定邮箱发送登录验证码。
        AppApiOperation.sendEmailCode: AppApiOperationSpec(
          method: ApiHttpMethod.post,
          path: '/app/v1/auth/email/send-code',
          requiresAuthentication: false,
        ),

        /// 使用邮箱和验证码登录或注册。
        AppApiOperation.emailLogin: AppApiOperationSpec(
          method: ApiHttpMethod.post,
          path: '/app/v1/auth/email/login',
          requiresAuthentication: false,
        ),

        /// 使用 Apple identity token 登录或注册。
        AppApiOperation.appleLogin: AppApiOperationSpec(
          method: ApiHttpMethod.post,
          path: '/app/v1/auth/apple',
          requiresAuthentication: false,
        ),

        /// 分页查询线上官方视频。
        AppApiOperation.officialVideos: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/videos/official',
          requiresAuthentication: false,
        ),

        /// 检查指定平台是否存在可用 App 版本。
        AppApiOperation.checkVersion: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/version/check',
          requiresAuthentication: false,
        ),

        /// 查询已发布且启用的训练课程列表。
        AppApiOperation.listTrainings: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/trainings',
          requiresAuthentication: false,
        ),

        /// 查询单个已发布训练课程的详情。
        AppApiOperation.trainingDetail: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/trainings/{id}',
          requiresAuthentication: false,
        ),

        /// 查询已发布且启用的设备型号列表。
        AppApiOperation.listDeviceModels: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/device-models',
          requiresAuthentication: false,
        ),

        /// 查询设备型号的能力、布局和 BLE 详情。
        AppApiOperation.deviceModelDetail: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/device-models/{id}',
          requiresAuthentication: false,
        ),

        /// 查询设备型号的已发布说明书。
        AppApiOperation.deviceManual: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/device-models/{id}/manual',
          requiresAuthentication: false,
        ),

        /// 查询 App 启动配置和后台功能开关。
        AppApiOperation.appConfig: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/config',
          requiresAuthentication: false,
          allowsSessionCredentials: true,
        ),

        /// 按页面代码查询已发布的 CMS 页面。
        AppApiOperation.cmsPage: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/cms/{code}',
          requiresAuthentication: false,
        ),

        /// 查询当前登录用户的资料摘要。
        AppApiOperation.currentUser: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/auth/me',
          requiresAuthentication: true,
        ),

        /// 查询当前投放窗口内的广告列表。
        AppApiOperation.listAds: AppApiOperationSpec(
          method: ApiHttpMethod.get,
          path: '/app/v1/ads',
          requiresAuthentication: false,
        ),
      };
}
