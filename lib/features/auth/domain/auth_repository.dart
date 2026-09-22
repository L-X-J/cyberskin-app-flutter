// 认证领域的远端访问抽象与登录请求值对象。
import '../../../core/result/result.dart';
import 'app_user.dart';

/// 邮箱验证码登录的输入值对象。
final class EmailLoginRequest {
  /// 创建邮箱验证码登录请求。
  const EmailLoginRequest({required this.email, required this.code});

  /// 用户输入的邮箱。
  final String email;

  /// 六位验证码。
  final String code;
}

/// Apple 登录的输入值对象。
final class AppleLoginRequest {
  /// 创建 Apple 登录请求。
  const AppleLoginRequest({
    required this.identityToken,
    this.email,
    this.fullName,
  });

  /// Apple 授权返回的身份令牌。
  final String identityToken;

  /// 首次授权可能携带的邮箱。
  final String? email;

  /// 首次授权可能携带的姓名。
  final String? fullName;
}

/// 账号和会话数据的领域访问入口。
abstract interface class AuthRepository {
  /// 向指定邮箱发送登录验证码。
  Future<Result<void>> sendEmailCode(String email);

  /// 使用邮箱验证码登录并持久化会话。
  Future<Result<AppUser>> loginWithEmail(EmailLoginRequest request);

  /// 使用 Google ID token 登录并持久化会话。
  Future<Result<AppUser>> loginWithGoogle(String idToken);

  /// 使用 Apple identity token 登录并持久化会话。
  Future<Result<AppUser>> loginWithApple(AppleLoginRequest request);

  /// 获取当前已登录用户资料。
  Future<Result<AppUser>> currentUser();

  /// 请求远端登出并无条件清理本地会话。
  Future<Result<void>> logout();
}
