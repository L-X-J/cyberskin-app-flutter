import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_manual_controller.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeDeviceCatalogRepository implements DeviceCatalogRepository {
  _FakeDeviceCatalogRepository(this.result);

  Result<DeviceManual> result;
  int requestedModelId = 0;
  int requestCount = 0;

  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() async =>
      const Result.ok(<DeviceModelSummary>[]);

  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) async =>
      const Result.failure(
        const AppFailure(
          code: FailureCode.unsupported,
          message: 'Not used by this test.',
        ),
      );

  @override
  Future<Result<DeviceManual>> getManual(int id) async {
    requestedModelId = id;
    requestCount++;
    return result;
  }
}

DeviceManual _manual() => DeviceManual(
  deviceModelId: 389,
  items: <DeviceManualItem>[
    DeviceManualItem(tab: 'Overview', contentHtml: '<p>First section</p>'),
    DeviceManualItem(tab: 'Care', contentHtml: '<p>Second section</p>'),
  ],
);

void main() {
  test(
    'loads the manual through the repository and preserves item order',
    () async {
      final repository = _FakeDeviceCatalogRepository(Result.ok(_manual()));
      final controller = DeviceManualController(repository, modelId: 389);

      await controller.load();

      expect(repository.requestedModelId, 389);
      expect(repository.requestCount, 1);
      expect(controller.manual.value?.items.map((item) => item.tab), [
        'Overview',
        'Care',
      ]);
      expect(controller.selectedTab.value, 0);
      expect(controller.failure.value, isNull);
      expect(controller.isLoading.value, isFalse);
    },
  );

  test('changes the selected tab and exposes repository failures', () async {
    const failure = AppFailure(
      code: FailureCode.network,
      message: 'Network unavailable',
    );
    final repository = _FakeDeviceCatalogRepository(
      const Result.failure(failure),
    );
    final controller = DeviceManualController(repository, modelId: 389);

    await controller.load();
    expect(controller.failure.value, failure);
    expect(controller.manual.value, isNull);
    expect(controller.isLoading.value, isFalse);

    repository.result = Result.ok(_manual());
    await controller.reload();
    controller.selectTab(1);
    controller.selectTab(99);

    expect(controller.selectedTab.value, 1);
    expect(controller.manual.value?.items[1].tab, 'Care');
  });
}
