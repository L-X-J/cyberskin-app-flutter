// 首页与内容模块共享的广告图片缓存与跳转逻辑助手。
import 'dart:async';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../content/domain/entities/app_content.dart';

/// 广告公共功能助手：承载广告图片本地缓存判断、预下载及跳转路由处理。
abstract final class AppAdvertisementHelper {
  /// 返回可直接渲染的本地路径；网络图片只有下载完成并落盘后才返回缓存文件。
  static Future<String?> cachedImagePath(String? url) async {
    final clean = url?.trim();
    if (clean == null || clean.isEmpty) return null;
    if (clean.startsWith('assets/') || clean.startsWith('asset:')) return clean;
    try {
      if (clean.startsWith('http://') || clean.startsWith('https://')) {
        final file = await getCachedImageFile(clean);
        return file != null && await file.exists() && await file.length() > 0
            ? file.path
            : null;
      }
      final file = File(clean);
      return await file.exists() && await file.length() > 0 ? clean : null;
    } on Object {
      return null;
    }
  }

  /// 判断图片是否已完整保存在设备本地。
  static Future<bool> isImageCached(String? url) async =>
      await cachedImagePath(url) != null;

  /// 下载网络图片并核验磁盘缓存，而不将未落盘的内存数据用于展示。
  static Future<String?> cacheImage(String? url) async {
    final clean = url?.trim();
    if (clean == null || clean.isEmpty) return null;
    final existing = await cachedImagePath(clean);
    if (existing != null) return existing;
    final uri = Uri.tryParse(clean);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme)) return null;
    try {
      await getNetworkImageData(clean, useCache: true);
      return await cachedImagePath(clean);
    } on Object {
      return null;
    }
  }

  /// 在广告原始对象之外保存图片本地路径，避免修改服务端跳转数据。
  static Future<List<({AppAdvertisement ad, String imagePath})>>
  filterCachedAdvertisements(List<AppAdvertisement> advertisements) async {
    final ready = <({AppAdvertisement ad, String imagePath})>[];
    for (final ad in advertisements) {
      final path = await cachedImagePath(ad.imageUrl);
      if (path != null) ready.add((ad: ad, imagePath: path));
    }
    return List.unmodifiable(ready);
  }

  /// 先发布已缓存的图片，再逐张发布新落盘的图片，保持服务端排序。
  static Stream<List<({AppAdvertisement ad, String imagePath})>>
  syncCachedAdvertisements(List<AppAdvertisement> advertisements) async* {
    final ready = await filterCachedAdvertisements(advertisements);
    yield ready;
    final paths = <AppAdvertisement, String>{
      for (final item in ready) item.ad: item.imagePath,
    };
    final remaining = advertisements.where((ad) => !paths.containsKey(ad));
    if (remaining.isEmpty) return;
    final updates =
        StreamController<List<({AppAdvertisement ad, String imagePath})>>();
    var pending = 0;
    for (final ad in remaining) {
      pending++;
      unawaited(
        cacheImage(ad.imageUrl).then((path) {
          if (path != null) {
            paths[ad] = path;
            if (!updates.isClosed) {
              updates.add(
                List.unmodifiable([
                  for (final item in advertisements)
                    if (paths[item] case final imagePath?)
                      (ad: item, imagePath: imagePath),
                ]),
              );
            }
          }
          if (--pending == 0 && !updates.isClosed) updates.close();
        }),
      );
    }
    yield* updates.stream;
  }

  /// 统一处理广告点击跳转逻辑。
  ///
  /// 支持 `product_detail`（跳转至指定型号产品详情或说明书）和
  /// `external_url`（系统浏览器打开外部 HTTP/HTTPS 链接）。
  static Future<void> openAdvertisement(
    AppAdvertisement ad, {
    void Function(int modelId)? onOpenProductDetail,
    void Function(String title, String message)? onError,
  }) async {
    if (ad.jumpType == 'product_detail') {
      final id = int.tryParse(ad.jumpTarget ?? '');
      if (id != null && id > 0) {
        onOpenProductDetail?.call(id);
      }
      return;
    }
    if (ad.jumpType != 'external_url') return;
    final uri = Uri.tryParse(ad.jumpTarget ?? '');
    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      return;
    }
    try {
      if (await launchUrl(uri, mode: LaunchMode.platformDefault)) return;
    } on Object {
      /* 平台拒绝的链接或异常。 */
    }
    if (onError != null) {
      onError('Unable to open link', 'Please try again.');
    } else {
      Get.snackbar('Unable to open link', 'Please try again.');
    }
  }
}
