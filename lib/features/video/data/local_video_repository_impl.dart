// 系统相册和文件选择适配：只返回可播放的本地 URI，不读取整文件或上传。
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/result/result.dart';
import '../domain/entities/video_media.dart';
import '../domain/repositories/local_video_repository.dart';

/// 将系统授权的单个媒体文件映射为会话内媒体。
final class LocalVideoRepositoryImpl implements LocalVideoRepository {
  /// 创建系统选择适配。
  LocalVideoRepositoryImpl();

  /// 只调用系统选择器，避免申请整库媒体读取权限。
  @override
  Future<Result<VideoMedia?>> choose(LocalVideoSource source) async {
    try {
      final file = switch (source) {
        LocalVideoSource.gallery => await ImagePicker().pickVideo(
          source: ImageSource.gallery,
        ),
        LocalVideoSource.files => await openFile(
          acceptedTypeGroups: const [
            XTypeGroup(
              label: 'Videos',
              extensions: ['mp4', 'mov', 'm4v', 'webm'],
              mimeTypes: ['video/*'],
              uniformTypeIdentifiers: ['public.movie'],
            ),
          ],
        ),
      };
      if (file == null) return const Result.ok(null);
      final uri = Uri.file(file.path).toString();
      return Result.ok(VideoMedia(id: uri, title: file.name, videoUrl: uri));
    } on PlatformException catch (_) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.unsupported,
          message: 'Unable to open this video. Check access in Settings and try again.',
        ),
      );
    } catch (_) {
      return const Result.failure(
        AppFailure(
          code: FailureCode.unknown,
          message: 'Unable to select a video. Please try again.',
        ),
      );
    }
  }
}
