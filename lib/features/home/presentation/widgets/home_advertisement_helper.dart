// 首页与内容模块共享的广告图片缓存与跳转逻辑助手。
import 'dart:async';
import 'dart:io';

import 'package:extended_image/extended_image.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../content/domain/entities/app_content.dart';

/// 广告公共功能助手：承载广告图片本地缓存判断、预下载及跳转路由处理。
abstract final class AppAdvertisementHelper {
  /// 判断指定广告图片的本地缓存状态。
  ///
  /// 本地资源与有效本地文件直接返回 `true`；网络图片检查 `extended_image` 缓存文件是否存在。
  static Future<bool> isImageCached(String? url) async {
    final clean = url?.trim();
    if (clean == null || clean.isEmpty) return false;
    if (clean.startsWith('assets/') || clean.startsWith('asset:')) return true;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      try {
        final file = await getCachedImageFile(clean);
        return file != null && file.existsSync();
      } on Object {
        return false;
      }
    }
    try {
      return File(clean).existsSync();
    } on Object {
      return false;
    }
  }

  /// 将指定的广告网络图片预加载并保存到本地缓存。
  ///
  /// 若已缓存则直接返回 `true`；网络图片通过 `extended_image` 预加载下载。
  static Future<bool> cacheImage(String? url) async {
    final clean = url?.trim();
    if (clean == null || clean.isEmpty) return false;
    if (await isImageCached(clean)) return true;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      try {
        final data = await getNetworkImageData(clean, useCache: true);
        return data != null && data.isNotEmpty;
      } on Object {
        return false;
      }
    }
    return isImageCached(clean);
  }

  /// 从原始广告列表中筛选出图片已完整保存到本地的广告条目。
  static Future<List<AppAdvertisement>> filterCachedAdvertisements(
    List<AppAdvertisement> advertisements,
  ) async {
    final cached = <AppAdvertisement>[];
    for (final ad in advertisements) {
      if (await isImageCached(ad.imageUrl)) {
        cached.add(ad);
      }
    }
    return List<AppAdvertisement>.unmodifiable(cached);
  }

  /// 预加载列表中的所有广告图片，并通过 Stream 实时推送当前所有图片已完成本地缓存的广告。
  static Stream<List<AppAdvertisement>> syncCachedAdvertisements(
    List<AppAdvertisement> advertisements,
  ) async* {
    if (advertisements.isEmpty) {
      yield const <AppAdvertisement>[];
      return;
    }

    // 1. 优先推送当前已完成本地缓存的广告
    final ready = await filterCachedAdvertisements(advertisements);
    yield ready;

    final readySet = Set<AppAdvertisement>.from(ready);
    final remaining = advertisements
        .where((ad) => !readySet.contains(ad))
        .toList();

    if (remaining.isEmpty) return;

    // 2. 后台并行预加载剩余广告图片，每当有图片下载缓存成功，更新并推送
    final controller = StreamController<List<AppAdvertisement>>();
    var currentReadyList = List<AppAdvertisement>.from(ready);

    var pendingCount = remaining.length;
    for (final ad in remaining) {
      unawaited(
        cacheImage(ad.imageUrl).then((success) {
          if (success) {
            // 保持原始广告的排序位置
            currentReadyList = advertisements
                .where((item) => currentReadyList.contains(item) || item == ad)
                .toList();
            if (!controller.isClosed) {
              controller.add(
                List<AppAdvertisement>.unmodifiable(currentReadyList),
              );
            }
          }
          pendingCount--;
          if (pendingCount <= 0 && !controller.isClosed) {
            controller.close();
          }
        }),
      );
    }

    yield* controller.stream;
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
