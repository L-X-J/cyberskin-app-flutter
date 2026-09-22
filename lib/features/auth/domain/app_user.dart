// 认证领域的当前用户不可变模型。

/// 当前 App 用户的身份与资料摘要。
final class AppUser {
  /// 创建用户资料摘要。
  const AppUser({
    this.id,
    this.nickname,
    this.avatarUrl,
    this.email,
    this.profileCompleted = false,
    this.status,
    this.lastLoginAt,
    this.registerChannel,
  });

  /// 后端用户主键。
  final int? id;

  /// 展示昵称。
  final String? nickname;

  /// 头像访问地址。
  final String? avatarUrl;

  /// 登录邮箱；第三方登录时可能为空。
  final String? email;

  /// 资料是否已由用户补充完成；缺失字段按 fail-closed 处理。
  final bool profileCompleted;

  /// 原始账号状态字符串，避免将开放后端字段错误收窄为枚举。
  final String? status;

  /// 最近登录时间。
  final DateTime? lastLoginAt;

  /// 原始注册渠道字符串。
  final String? registerChannel;
}
