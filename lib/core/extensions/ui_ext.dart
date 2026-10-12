import 'package:get/get.dart';

extension UiSizeExt on num {
  /// 获取状态栏高度
  double get statusBarHeight {
    return toDouble() + Get.mediaQuery.viewPadding.top;
  }

  /// 获取底部安全区距离
  double get navigationBarHeight {
    return toDouble() + Get.mediaQuery.viewPadding.bottom;
  }
}
