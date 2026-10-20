import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_manual/device_manual_product_hero.dart';
import 'package:cyberskin_app/features/device/presentation/device_manual_controller.dart';
import 'package:cyberskin_app/features/home/presentation/home_dashboard.dart';
import 'package:cyberskin_app/features/home/presentation/home_disconnected/home_disconnected_view.dart';
import 'package:cyberskin_app/features/home/presentation/states/home_ble_card_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeCatalogRepository implements DeviceCatalogRepository {
  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) async =>
      Result.ok(
        DeviceModelDetail(
          summary: DeviceModelSummary(
            id: id,
            name: 'Device $id',
            iconUrl: 'https://example.com/image.png',
          ),
        ),
      );

  @override
  Future<Result<DeviceManual>> getManual(int id) async =>
      Result.ok(DeviceManual(deviceModelId: id, items: const []));

  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() async =>
      const Result.ok([]);
}

void main() {
  testWidgets(
    'DeviceManualReactiveProductHero updates image without creating duplicate Hero tags',
    (tester) async {
      final repository = _FakeCatalogRepository();
      final controller = DeviceManualController(
        repository,
        modelId: 2100573200126414849,
        summary: const DeviceModelSummary(
          id: 2100573200126414849,
          name: 'Cyberskin Device',
          iconUrl: null,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceManualReactiveProductHero(
              controller: controller,
              routeArgs: null,
            ),
          ),
        ),
      );

      expect(find.byType(Hero), findsOneWidget);

      // Simulate detail finish loading (updates selectedModel with new image)
      await controller.load();
      await tester.pump(); // Start AnimatedSwitcher cross-fade
      await tester.pump(const Duration(milliseconds: 180)); // Mid animation

      // Verify there is strictly ONE Hero widget during AnimatedSwitcher animation
      expect(find.byType(Hero), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(Hero), findsOneWidget);
    },
  );

  testWidgets(
    'HomeDisconnectedView handles duplicate model IDs in list without duplicate Hero tags',
    (tester) async {
      const duplicateId = 2100573200126414849;
      final dashboard = HomeDashboard(
        deviceModels: const [
          DeviceModelSummary(id: duplicateId, name: 'Model A'),
          DeviceModelSummary(id: duplicateId, name: 'Model B'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeDisconnectedView(
              dashboard: dashboard,
              isLoading: false,
              isAuthenticated: true,
              bleCardState: HomeBleCardState.ready(),
              onPrimaryAction: () {},
              onStopDiscovery: () {},
              pendingDiscovery: null,
              onConfirmDiscovery: () {},
              onDismissDiscovery: () {},
              isScanning: false,
              onDeviceModelDetails: (_) {},
              onLogin: () {},
              onProfile: () {},
            ),
          ),
        ),
      );

      // Should render only 1 Hero for duplicateId, avoiding Hero tag collision
      expect(find.byType(Hero), findsOneWidget);
    },
  );
}
