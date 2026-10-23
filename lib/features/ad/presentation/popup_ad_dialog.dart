// 登录后弹窗广告展示组件：全屏蒙层 + 居中图片卡片 + 关闭按钮。
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../content/domain/entities/app_content.dart';
import '../../home/presentation/widgets/home_advertisement_helper.dart';

/// 弹窗广告对话框；点击图片执行跳转，点击蒙层或关闭按钮退出。
class PopupAdDialog extends StatelessWidget {
  /// 创建弹窗广告视图。
  const PopupAdDialog({required this.ad, super.key});

  /// 待展示的广告条目。
  final AppAdvertisement ad;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // 半透明蒙层，点击关闭。
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Get.back<void>(),
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.6)),
            ),
          ),
          // 居中广告卡片。
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Get.back<void>();
                    unawaited(AppAdvertisementHelper.openAdvertisement(ad));
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ad.imageUrl != null && ad.imageUrl!.isNotEmpty
                        ? Image.network(
                            ad.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              height: 180,
                              child: ColoredBox(color: Colors.grey),
                            ),
                          )
                        : const SizedBox(
                            height: 180,
                            child: ColoredBox(color: Colors.grey),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // 关闭按钮。
                IconButton(
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
