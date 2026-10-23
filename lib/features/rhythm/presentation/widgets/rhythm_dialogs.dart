// 节奏确认弹窗及进入编辑器的导航编排。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/widgets/app_liquid_glass_button.dart';
import '../../../control/domain/device_session.dart';
import '../../../control/presentation/control_session_controller.dart';
import '../../domain/entities/rhythm.dart';
import '../rhythm_session_controller.dart';
import 'rhythm_surface.dart';

/// 展示统一确认弹窗，取消或关闭均返回 false。
Future<bool> rhythmConfirm(
  String message, {
  String title = 'Prompt',
  String confirm = 'Confirm',
}) async =>
    await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: RhythmSurface(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, height: 1.35),
                  ),
                  const SizedBox(height: 44),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked =
                          MediaQuery.textScalerOf(context).scale(20) > 24;
                      final cancel = AppLiquidGlassButton(
                        label: 'Cancel',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        width: double.infinity,
                        height: stacked ? 72 : 58,
                        onPressed: () => Get.back(result: false),
                      );
                      final accept = AppLiquidGlassButton(
                        label: confirm,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        width: double.infinity,
                        height: stacked ? 72 : 58,
                        onPressed: () => Get.back(result: true),
                      );
                      return stacked
                          ? Column(
                              children: [
                                cancel,
                                const SizedBox(height: 12),
                                accept,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: cancel),
                                const SizedBox(width: 12),
                                Expanded(child: accept),
                              ],
                            );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierColor: Colors.black54,
    ) ??
    false;

/// 必要时提示暂停，取得编辑锁后进入命名路由，并在返回时释放锁。
Future<bool> openRhythmEditor({Rhythm? rhythm}) async {
  final session = Get.find<RhythmSessionController>();
  final control = Get.find<ControlSessionController>();
  if (control.state.value == DeviceSessionState.running &&
      !await rhythmConfirm(
        'During the process of creating a custom rhythm, the device will automatically pause. Are you sure to proceed to the next step?',
      )) {
    return false;
  }
  if (!await session.beginEditing()) {
    Get.snackbar(
      'Unable to edit',
      session.error.value ?? 'Unable to pause the device.',
    );
    return false;
  }
  try {
    var selected = rhythm;
    if (selected != null && !selected.hasCompleteProgram) {
      final loaded = await session.repository.getById(selected.id!);
      if (session.isClosed) return false;
      if (loaded.isFailure || loaded.valueOrNull?.hasCompleteProgram != true) {
        Get.snackbar(
          'Unable to edit',
          loaded.failureOrNull?.message ??
              'Unable to load the complete rhythm.',
        );
        return false;
      }
      selected = loaded.valueOrNull!;
    }
    // Get 的全局路由树用 `List<GetPage>` 保存页面，匹配时由 `copy()` 重新包装为
    // `GetPage<dynamic>`，所以命名路由实际总是派发出 `Route<dynamic>`。这里不能用
    // `Get.toNamed<bool>`：`Navigator.pushNamed<bool>` 会把结果强转为
    // `Route<bool?>?`，与 `Route<dynamic>` 不兼容并抛 TypeError。
    // 因此改为接收 dynamic 后再做运行时校验，同时兼容结果缺失。
    final result = await Get.toNamed<dynamic>(
      AppRoutes.rhythmEdit,
      arguments: selected,
    );
    return result == true;
  } finally {
    session.playback.finishEditing();
  }
}
