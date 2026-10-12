import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/device/domain/repositories/device_catalog_repository.dart';
import 'package:cyberskin_app/features/device/presentation/device_manual_controller.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeCatalogRepository implements DeviceCatalogRepository {
  _FakeCatalogRepository(this.result, {this.models = const []});

  final Result<DeviceModelDetail> result;
  final List<DeviceModelSummary> models;
  int calls = 0;
  int manualCalls = 0;

  @override
  Future<Result<DeviceModelDetail>> getDeviceModelDetail(int id) async {
    calls++;
    return result;
  }

  @override
  Future<Result<DeviceManual>> getManual(int id) async {
    manualCalls++;
    return Result.ok(
      DeviceManual(
        deviceModelId: id,
        items: [
          DeviceManualItem(tab: 'intro', contentHtml: '<p>Intro</p>'),
          DeviceManualItem(tab: 'connection', contentHtml: '<p>Connect</p>'),
          DeviceManualItem(tab: 'cleaning', contentHtml: '<p>Wash</p>'),
        ],
      ),
    );
  }

  @override
  Future<Result<List<DeviceModelSummary>>> listDeviceModels() async =>
      Result.ok(models);
}

DeviceModelDetail _detail() => DeviceModelDetail(
  summary: const DeviceModelSummary(id: 7, name: 'Cyberskin Air'),
  heatSupported: true,
  heatLevels: const [1, 2, 3],
);

void main() {
  test('loads model detail and exposes it as observable state', () async {
    final repository = _FakeCatalogRepository(Result.ok(_detail()));
    final controller = DeviceManualController(repository, modelId: 7);

    await controller.load();

    expect(repository.calls, 1);
    expect(controller.detail.value?.summary.name, 'Cyberskin Air');
    expect(controller.failure.value, isNull);
    expect(controller.isLoading.value, isFalse);
  });

  test('selecting another model refreshes detail and manual content', () async {
    final repository = _FakeCatalogRepository(
      Result.ok(_detail()),
      models: const [
        DeviceModelSummary(id: 7, name: 'Air'),
        DeviceModelSummary(id: 8, name: 'Pro'),
      ],
    );
    final controller = DeviceManualController(repository, modelId: 7);

    await controller.load();
    await controller.selectModel(1);

    expect(controller.selectedModel.value?.id, 8);
    expect(repository.calls, 2);
    expect(repository.manualCalls, 2);
    expect(controller.manual.value?.items, hasLength(3));
    controller.selectManual(1);
    expect(controller.selectedManualIndex.value, 1);
    controller.selectManual(2);
    expect(controller.selectedManualIndex.value, 2);
  });
}
