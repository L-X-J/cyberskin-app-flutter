// 自定义节奏列表页：进入运行、创建/编辑、长按菜单及删除确认。
import 'dart:math' as math;

import 'package:cyberskin_app/app/app_routes.dart';
import 'package:cyberskin_app/core/theme/app_rhythm_style.dart';
import 'package:cyberskin_app/core/widgets/app_liquid_glass_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/entities/rhythm.dart';
import '../../rhythm_session_controller.dart';
import '../../widgets/rhythm_dialogs.dart';
import '../../widgets/rhythm_page_frame.dart';
import '../../widgets/rhythm_surface.dart';
import 'rhythm_home_controller.dart';
import 'widgets/rhythm_home_header.dart';
import 'widgets/rhythm_list_entrance.dart';
import 'widgets/rhythm_list_tile.dart';

/// 节奏列表及创建、运行、编辑、删除入口。
final class RhythmHomePage extends StatefulWidget {
  /// 创建实例；依赖及初始状态由调用方提供。
  const RhythmHomePage({super.key});

  @override
  State<RhythmHomePage> createState() => _RhythmHomePageState();
}

final class _RhythmHomePageState extends State<RhythmHomePage> {
  final controller = Get.find<RhythmHomeController>();
  final _seen = <Object>{};
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<RhythmSessionController>();
    return RhythmPageFrame(
      onBack: () => Get.back<void>(),
      showToolbar: false,
      topOverlay: LayoutBuilder(
        builder: (context, constraints) {
          final padding = MediaQuery.paddingOf(context);
          final width =
              math.min(
                AppRhythmStyle.maxWidth,
                constraints.maxWidth - padding.horizontal,
              ) -
              2 * AppRhythmStyle.pagePadding;
          return Obx(() {
            final header = _header(context, session, width);
            return AnimatedBuilder(
              animation: _scroll,
              builder: (context, _) => header.buildOverlay(
                context,
                _scroll.hasClients ? _scroll.offset : 0,
              ),
            );
          });
        },
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: controller.refreshList,
            child: CustomScrollView(
              key: const PageStorageKey('rhythm-home-list'),
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                Obx(
                  () => SliverPersistentHeader(
                    pinned: true,
                    delegate: _header(context, session, constraints.maxWidth),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Obx(
                    () => RhythmError(
                      controller.error.value ?? session.error.value,
                    ),
                  ),
                ),
                Obx(() {
                  final items = controller.items.toList(growable: false);
                  if (controller.loading.value && items.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(56),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  if (items.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 56),
                        child: Column(
                          children: [
                            const Text(
                              'Create your first rhythm',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Combine your favorite settings, one segment at a time.',
                              textAlign: TextAlign.center,
                            ),
                            if (controller.error.value != null)
                              TextButton(
                                onPressed: controller.refreshList,
                                child: const Text('Retry'),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.only(bottom: 16),
                    sliver: SliverList.builder(
                      itemCount: items.length,
                      findChildIndexCallback: (key) {
                        if (key is! ValueKey<Object>) return null;
                        final index = items.indexWhere(
                          (item) => (item.id ?? item) == key.value,
                        );
                        return index < 0 ? null : index;
                      },
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final id = item.id ?? item;
                        return RhythmListEntrance(
                          key: ValueKey<Object>(id),
                          animate: _seen.add(id),
                          index: index,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RhythmListTile(
                              rhythm: item,
                              onTap: () => _run(item, session),
                              onLongPress: () => _menu(item, session),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
      footer: SizedBox(
        height: 76,
        child: Align(
          alignment: Alignment.centerLeft,
          child: AppLiquidGlassButton(
            label: 'Create rhythm',
            icon: Icons.add,
            iconSize: 38,
            width: 58,
            height: 58,
            contentPadding: EdgeInsets.zero,
            variant: AppLiquidGlassButtonVariant.translucent,
            onPressed: () async {
              if (await openRhythmEditor()) await controller.refreshList();
            },
          ),
        ),
      ),
    );
  }

  /// 占位和前景共享同一文字测量契约，安全区只由框架和覆盖层各消费一次。
  RhythmHomeHeader _header(
    BuildContext context,
    RhythmSessionController session,
    double width,
  ) => RhythmHomeHeader(
    width: width,
    subtitle:
        '${session.target.value?.name ?? 'No device'} · ${session.target.value == null ? 'Disconnected' : 'Connected'}',
    textScaler: MediaQuery.textScalerOf(context),
    direction: Directionality.of(context),
    disableAnimations: MediaQuery.disableAnimationsOf(context),
    onBack: () => Get.back<void>(),
  );

  Future<void> _run(Rhythm item, RhythmSessionController session) async {
    final rhythm = await controller.detail(item);
    if (rhythm == null) return;
    // 选择详情不触发设备，旧活动会话继续由独立执行器持有。
    session.select(rhythm);
    await Get.toNamed<void>(AppRoutes.rhythmInfo);
    if (!controller.isClosed) await controller.refreshList();
  }

  Future<void> _menu(Rhythm item, RhythmSessionController session) async {
    final action = await Get.bottomSheet<String>(
      SafeArea(
        child: Material(
          color: AppRhythmStyle.panel,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit rhythm'),
                onTap: () => Get.back(result: 'edit'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Delete rhythm'),
                onTap: () => Get.back(result: 'delete'),
              ),
            ],
          ),
        ),
      ),
    );
    if (action == 'edit') {
      final rhythm = await controller.detail(item);
      if (rhythm != null && await openRhythmEditor(rhythm: rhythm)) {
        await controller.refreshList();
      }
    } else if (action == 'delete' &&
        await rhythmConfirm(
          'Delete this rhythm? This cannot be undone.',
          confirm: 'Delete',
        )) {
      if (session.playback.active &&
          session.rhythm.value?.id == item.id &&
          !await session.playback.stop()) {
        controller.error.value = session.error.value;
        return;
      }
      await controller.delete(item);
    }
  }
}
