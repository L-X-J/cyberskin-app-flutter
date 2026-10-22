// 通用程序 JSON 的磁盘缓存与下载边界；节奏、Training 共用，最长有效 30 天。
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../core/error/app_failure.dart';
import '../domain/entities/common_program_segment.dart';

/// 以稳定文件 URL 为键缓存原始 JSON，不把临时签名地址或登录凭证写入磁盘。
class CommonProgramFileCache {
  /// 应用组装层只创建一个实例；测试可以替换缓存和文件下载器。
  CommonProgramFileCache({BaseCacheManager? cache, FileService? downloads})
    : _cache =
          cache ??
          CacheManager(
            Config(
              'cyberskin_common_program_v1',
              stalePeriod: maxAge,
              maxNrOfCacheObjects: 200,
            ),
          ),
      _downloads = downloads ?? HttpFileService();

  /// 从下载成功起计时，读取缓存不会续期；到期后不能离线播放该文件。
  static const maxAge = Duration(days: 30);
  static const _maxBytes = 256 * 1024;
  final BaseCacheManager _cache;
  final FileService _downloads;
  final _pending = <String, Future<List<CommonProgramSegment>>>{};

  /// 命中有效缓存直接读取，否则用最新签名地址下载；同一文件合并在途请求。
  Future<List<CommonProgramSegment>> load({
    required String url,
    required String downloadUrl,
  }) async {
    _validateUrl(url);
    final future = _pending.putIfAbsent(url, () => _load(url, downloadUrl));
    try {
      return await future;
    } finally {
      _pending.removeWhere(
        (key, value) => key == url && identical(value, future),
      );
    }
  }

  /// 仅离线读取未过期文件；损坏、丢失、到期均视为未命中并移除。
  Future<List<CommonProgramSegment>?> readCached(String url) async {
    try {
      final info = await _cache.getFileFromCache(url);
      if (info == null) return null;
      if (!info.validTill.isAfter(DateTime.now())) {
        await remove(url);
        return null;
      }
      if (await info.file.length() > _maxBytes) {
        throw const FormatException('Program JSON is too large.');
      }
      return _decode(await info.file.readAsBytes());
    } on Object {
      await remove(url);
      return null;
    }
  }

  Future<List<CommonProgramSegment>> _load(
    String url,
    String downloadUrl,
  ) async {
    final cached = await readCached(url);
    if (cached != null) return cached;
    _validateUrl(downloadUrl);
    // 文件服务直接请求对象存储，不附带 App 的 Authorization 或 clientid。
    final response = await _downloads
        .get(downloadUrl, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      await response.content.take(0).drain<void>();
      throw AppFailure(
        code: response.statusCode >= 400 && response.statusCode < 500
            ? FailureCode.business
            : FailureCode.network,
        message: 'Unable to download program JSON. Please try again.',
        httpStatus: response.statusCode,
      );
    }
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response.content.timeout(
      const Duration(seconds: 15),
    )) {
      if (builder.length + chunk.length > _maxBytes) {
        throw const FormatException('Program JSON is too large.');
      }
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    final segments = _decode(bytes);
    try {
      // 使用明确的 maxAge，避免服务端超长 Cache-Control 延长播放文件有效期。
      await _cache.putFile(
        url,
        bytes,
        key: url,
        maxAge: maxAge,
        fileExtension: 'json',
      );
    } on Object {
      // 磁盘不可写不影响本次已下载并校验的程序。
    }
    return segments;
  }

  List<CommonProgramSegment> _decode(List<int> bytes) {
    final json = jsonDecode(utf8.decode(bytes));
    if (json is! List || json.isEmpty) {
      throw const FormatException('Program JSON must be a non-empty array.');
    }
    return List.unmodifiable(
      json.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid program segment.');
        }
        return CommonProgramSegment.fromJson(item);
      }),
    );
  }

  void _validateUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !const {'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Invalid program JSON URL.');
    }
  }

  /// 更新、删除或发现文件与统计不一致时清理旧缓存；失败不覆盖云端成功。
  Future<void> remove(String url) async {
    try {
      await _cache.removeFile(url);
    } on Object {
      // 缓存只是加速层，仍由有效期和远端文件身份约束读取。
    }
  }
}
