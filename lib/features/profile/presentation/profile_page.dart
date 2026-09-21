// 用户资料功能的导航入口占位页面。
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// 为初始导航契约提供的用户资料入口页面。
final class ProfilePage extends StatelessWidget {
  /// 创建用户资料页面。
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: Get.back<void>),
        title: const Text('Profile'),
      ),
      body: const Center(
        child: Text(
          'Profile features will be connected to the account domain.',
        ),
      ),
    );
  }
}
