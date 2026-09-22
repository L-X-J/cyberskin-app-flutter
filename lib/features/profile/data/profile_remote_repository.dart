// 用户资料 App API 的远端 Repository 实现。
import '../../../core/network/app_api_operation.dart';
import '../../../core/network/base_remote_repository.dart';
import '../../../core/result/result.dart';
import '../domain/repositories/profile_repository.dart';

/// ProfileRepository 的 App API 实现。
final class ProfileRemoteRepository extends BaseRemoteRepository
    implements ProfileRepository {
  /// 创建资料远端 Repository。
  ProfileRemoteRepository({
    required super.transport,
    required super.sessionStore,
  });

  @override
  Future<Result<void>> updateProfile(ProfileUpdateRequest request) =>
      requestVoid(
        AppApiOperation.updateProfile,
        body: <String, Object?>{
          if (request.nickname != null) 'nickname': request.nickname,
          if (request.avatarUrl != null) 'avatarUrl': request.avatarUrl,
        },
      );
}
