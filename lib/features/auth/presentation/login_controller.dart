// 登录流程控制器：编排发码、验证码提交、重发冷却及配置协议链接。
import 'dart:async';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_routes.dart';
import '../../../app/session_controller.dart';
import '../../../core/error/app_failure.dart';
import '../../../core/result/result.dart';
import '../../content/domain/entities/app_content.dart';
import '../../content/domain/repositories/content_repository.dart';
import '../domain/auth_repository.dart';

/// 登录页输入校验、认证调用与结果状态控制器。
final class LoginController extends GetxController {
  /// 创建登录控制器。
  LoginController(
    this._authRepository,
    this._contentRepository,
    this._session, {
    Future<bool> Function(Uri)? openAgreementUrl,
    DateTime Function()? clock,
  }) : _openAgreementUrl = openAgreementUrl ?? _launchAgreementUrl,
       _clock = clock ?? DateTime.now;

  final AuthRepository _authRepository;
  final ContentRepository _contentRepository;
  final SessionController _session;
  final Future<bool> Function(Uri) _openAgreementUrl;
  final DateTime Function() _clock;
  Timer? _resendTimer;
  DateTime? _resendAvailableAt;
  String? _lastCodeEmail;
  int _emailFlowGeneration = 0;

  /// 当前配置提供的协议入口；为空时页面仍展示文案但不可跳转。
  final agreementUrls = <String, Uri>{}.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(loadAgreements());
  }

  /// 从配置仓库获取协议地址；缓存缺失时请求配置，不使用客户端固定链接兜底。
  Future<void> loadAgreements() async {
    try {
      final cached = await _contentRepository.readCachedConfiguration();
      if (cached != null) {
        _setAgreements(cached);
        return;
      }
      final refreshed = await _contentRepository.refreshConfiguration();
      if (refreshed case Success<AppConfiguration>(:final value)) {
        _setAgreements(value);
      }
    } catch (_) {
      // 配置暂不可用时不使用客户端固定地址，保持协议入口不可点击。
      agreementUrls.clear();
    }
  }

  void _setAgreements(AppConfiguration configuration) {
    final urls = <String, Uri>{};
    for (final agreement in configuration.agreements) {
      final raw = agreement.contentUrl;
      final uri = raw == null ? null : Uri.tryParse(raw);
      if (agreement.code != null &&
          uri != null &&
          uri.scheme == 'https' &&
          uri.host.isNotEmpty) {
        urls[agreement.code!] = uri;
      }
    }
    agreementUrls.assignAll(urls);
  }

  /// 打开配置中的 H5 协议；无效配置和平台打开失败均反馈到当前登录页。
  Future<void> openAgreement(String code) async {
    // 初始化可能在后台刷新配置；点击时重新读取仓库缓存，避免沿用旧版本协议。
    try {
      final latest = await _contentRepository.readCachedConfiguration();
      if (latest != null) _setAgreements(latest);
    } catch (_) {
      agreementUrls.clear();
    }
    final uri = agreementUrls[code];
    if (uri == null) {
      failure.value = const AppFailure(
        code: FailureCode.business,
        message: 'Agreement is unavailable. Please try again later.',
      );
      return;
    }
    try {
      if (await _openAgreementUrl(uri)) {
        failure.value = null;
        return;
      }
    } catch (_) {
      // 平台插件可能不可用；统一展示可理解的失败状态，不暴露底层异常。
    }
    failure.value = const AppFailure(
      code: FailureCode.business,
      message: 'Unable to open the agreement. Please try again.',
    );
  }

  static Future<bool> _launchAgreementUrl(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.inAppBrowserView);

  /// 邮箱输入值。
  final email = ''.obs;

  /// 验证码输入值。
  final code = ''.obs;

  /// 是否已成功发送邮箱验证码。
  final codeSent = false.obs;

  /// 是否正在发送验证码。
  final sendingCode = false.obs;

  /// 是否正在提交登录。
  final signingIn = false.obs;

  /// 当前可展示错误。
  final failure = Rxn<AppFailure>();

  /// 发码成功的邮箱，展示和验证码提交均以此值为准。
  final verificationEmail = ''.obs;

  /// 距离下一次可重发的秒数，后台停留后按截止时间重新计算。
  final resendSecondsRemaining = 0.obs;

  /// 首次发码；只有成功返回 true 时，页面才切换到验证码步骤。
  Future<bool> sendCode() async {
    final value = email.value.trim();
    if (!_isEmail(value)) {
      failure.value = const AppFailure(
        code: FailureCode.business,
        message: 'Enter a valid email address.',
      );
      return false;
    }
    updateResendCountdown();
    // 返回修改邮箱后若仍使用同一地址，可继续输入已发送的验证码，不绕过冷却重复发码。
    if (_lastCodeEmail == value && resendSecondsRemaining.value > 0) {
      verificationEmail.value = value;
      codeSent.value = true;
      return true;
    }
    return _sendCodeTo(value);
  }

  /// 向已经确认的邮箱重发，冷却期间或正在提交时不重复请求。
  Future<bool> resendCode() async {
    updateResendCountdown();
    if (verificationEmail.value.isEmpty || resendSecondsRemaining.value > 0) {
      return false;
    }
    return _sendCodeTo(verificationEmail.value);
  }

  /// 在请求期间防重复发送，并忽略返回上一步后过期请求的状态结果。
  Future<bool> _sendCodeTo(String value) async {
    if (sendingCode.value || signingIn.value) return false;
    final generation = _emailFlowGeneration;
    sendingCode.value = true;
    failure.value = null;
    try {
      final result = await _authRepository.sendEmailCode(value);
      if (isClosed || generation != _emailFlowGeneration) return false;
      if (result case Success<void>()) {
        email.value = value;
        verificationEmail.value = value;
        code.value = '';
        codeSent.value = true;
        _lastCodeEmail = value;
        _startResendCooldown();
        return true;
      }
      failure.value = result.failureOrNull;
      return false;
    } finally {
      if (!isClosed) sendingCode.value = false;
    }
  }

  /// 回到邮箱输入时清除本轮验证码，但保留已输入邮箱。
  void resetEmailVerification() {
    _emailFlowGeneration++;
    verificationEmail.value = '';
    code.value = '';
    codeSent.value = false;
    failure.value = null;
    // 返回不撤销已发送邮件的冷却，防止来回切换步骤绕过 60 秒限制。
  }

  /// 成功发送后开启接口约定的 60 秒冷却，不依赖动画帧数累计。
  void _startResendCooldown() {
    _resendTimer?.cancel();
    _resendAvailableAt = _clock().add(const Duration(seconds: 60));
    updateResendCountdown();
    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => updateResendCountdown(),
    );
  }

  /// 每秒及从后台恢复时同步剩余时间，避免计时器暂停造成倒计时漂移。
  void updateResendCountdown() {
    final deadline = _resendAvailableAt;
    if (deadline == null || isClosed) return;
    final milliseconds = deadline.difference(_clock()).inMilliseconds;
    resendSecondsRemaining.value = milliseconds <= 0
        ? 0
        : (milliseconds / 1000).ceil();
    if (resendSecondsRemaining.value == 0) _resendTimer?.cancel();
  }

  @override
  void onClose() {
    _emailFlowGeneration++;
    _resendTimer?.cancel();
    super.onClose();
  }

  /// 使用邮箱和验证码完成登录。
  Future<void> signInWithEmail() async {
    if (sendingCode.value || signingIn.value) return;
    final emailValue = verificationEmail.value;
    final codeValue = code.value.trim();
    if (!_isEmail(emailValue)) {
      failure.value = const AppFailure(
        code: FailureCode.business,
        message: 'Enter a valid email address.',
      );
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(codeValue)) {
      failure.value = const AppFailure(
        code: FailureCode.business,
        message: 'Enter the 6-digit verification code.',
      );
      return;
    }
    await _runLogin(
      () => _authRepository.loginWithEmail(
        EmailLoginRequest(email: emailValue, code: codeValue),
      ),
    );
  }

  /// 处理 Google 登录入口；真实授权插件接入后替换此方法的 token 来源。
  Future<void> signInWithGoogle() async {
    await _unsupportedSocialLogin('Google Sign-In is not configured yet.');
  }

  /// 处理 Apple 登录入口；真实授权插件接入后替换此方法的 token 来源。
  Future<void> signInWithApple() async {
    await _unsupportedSocialLogin('Apple Sign-In is not configured yet.');
  }

  Future<void> _unsupportedSocialLogin(String message) async {
    failure.value = AppFailure(code: FailureCode.unsupported, message: message);
  }

  Future<void> _runLogin<T>(Future<Result<T>> Function() request) async {
    if (signingIn.value) return;
    signingIn.value = true;
    failure.value = null;
    final result = await request();
    signingIn.value = false;
    if (result.isSuccess) {
      // 登录响应已持久化凭证；无注入存储的测试会话由显式状态切换收敛。
      await _session.refreshFromCredentials();
      _session.markAuthenticated();
      // 配置刷新由首页自动触发，此处不重复发起，避免竞态覆盖刚建立的登录态。
      // 保留匿名首页及其 BLE 订阅，避免旧路由清理销毁新首页的同类型控制器。
      AppRoutes.returnToHome();
      return;
    }
    failure.value = result.failureOrNull;
  }

  bool _isEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
}
