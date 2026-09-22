// 用户资料更新的领域访问抽象。
import '../../../../core/result/result.dart';

/// 用户资料更新请求。
final class ProfileUpdateRequest {
  /// 创建仅包含需要修改字段的用户资料请求。
  const ProfileUpdateRequest({this.nickname, this.avatarUrl});

  /// 新昵称；`null` 表示保持原值。
  final String? nickname;

  /// 新头像 URL；`null` 表示保持原值。
  final String? avatarUrl;
}

/// 用户资料远端访问入口。
abstract interface class ProfileRepository {
  /// 更新当前用户昵称和头像。
  Future<Result<void>> updateProfile(ProfileUpdateRequest request);
}
