// 用户资料功能页面。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/widgets/app_scaffold.dart';
import '../../auth/domain/app_user.dart';
import 'profile_controller.dart';

/// 当前用户资料与会话管理页面。
final class ProfilePage extends GetView<ProfileController> {
  /// 创建用户资料页面。
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      currentTab: AppTab.home,
      showBottomNavigation: false,
      appBar: AppBar(title: const Text('Profile')),
      body: Obx(() {
        if (controller.isLoading.value && controller.user.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final failure = controller.failure.value;
        if (failure != null && controller.user.value == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(failure.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => controller.load(),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }
        return _ProfileBody(
          user: controller.user.value,
          isLoggingOut: controller.isLoggingOut.value,
          onLogout: controller.logout,
        );
      }),
    );
  }
}

/// 资料页的用户摘要和退出操作。
final class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.user,
    required this.isLoggingOut,
    required this.onLogout,
  });

  final AppUser? user;
  final bool isLoggingOut;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CircleAvatar(radius: 36, child: Icon(Icons.person_outline)),
        const SizedBox(height: 16),
        Text(
          user?.nickname?.trim().isNotEmpty == true
              ? user!.nickname!
              : 'Cyberskin user',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (user?.email != null) ...[
          const SizedBox(height: 8),
          Text(user!.email!, textAlign: TextAlign.center),
        ],
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: isLoggingOut ? null : () => onLogout(),
          icon: const Icon(Icons.logout),
          label: Text(isLoggingOut ? 'Signing out' : 'Sign out'),
        ),
      ],
    );
  }
}
