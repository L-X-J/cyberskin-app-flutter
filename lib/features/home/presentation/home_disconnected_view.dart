// 主页未连接状态及扫描、型号入口的展示组件。
part of 'home_page.dart';

/// 设备未连接状态；底部一级导航按产品规则隐藏。
final class _DisconnectedHome extends StatelessWidget {
  const _DisconnectedHome({
    required this.dashboard,
    required this.isLoading,
    required this.isAuthenticated,
    required this.onPrimaryAction,
    required this.onDeviceModelDetails,
    required this.onLogin,
    required this.onProfile,
  });

  final HomeDashboard dashboard;
  final bool isLoading;
  final bool isAuthenticated;
  final VoidCallback onPrimaryAction;
  final ValueChanged<DeviceModelSummary> onDeviceModelDetails;
  final VoidCallback onLogin;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final bottomInset = AppScaffold.contentBottomPaddingOf(
      context,
      showBottomNavigation: false,
    );
    return _HomeBackground(
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          Get.mediaQuery.viewPadding.top + 28,
          24,
          bottomInset,
        ),
        children: [
          _HomeHeader(
            title: 'Add Device',
            subtitle: 'Please turn on Bluetooth',
            onProfile: onProfile,
          ),
          const SizedBox(height: 28),
          _ScanCard(isLoading: isLoading, onStop: onPrimaryAction),
          const SizedBox(height: 16),
          _DeviceModelGrid(
            models: dashboard.deviceModels,
            onTap: onDeviceModelDetails,
          ),
          if (dashboard.deviceModels.isEmpty) ...[
            const SizedBox(height: 10),
            const AppInlineHint(
              icon: Icons.bluetooth_disabled_outlined,
              text: 'Turn on Bluetooth and keep the device nearby.',
              onTap: null,
            ),
          ],
        ],
      ),
    );
  }
}
