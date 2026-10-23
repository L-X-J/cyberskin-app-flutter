// 广告公共逻辑助手单元测试：校验缓存过滤、网络图片预下载及约定跳转分支。
import 'package:cyberskin_app/features/content/domain/entities/app_content.dart';
import 'package:cyberskin_app/features/home/domain/entities/home_content.dart';
import 'package:cyberskin_app/features/home/presentation/home_disconnected/home_disconnected_view.dart';
import 'package:cyberskin_app/features/home/presentation/states/home_ble_card_state.dart';
import 'package:cyberskin_app/features/home/presentation/widgets/home_advertisement_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppAdvertisementHelper', () {
    test('isImageCached correctly identifies asset and empty paths', () async {
      expect(await AppAdvertisementHelper.isImageCached(null), isFalse);
      expect(await AppAdvertisementHelper.isImageCached(''), isFalse);
      expect(
        await AppAdvertisementHelper.isImageCached(
          'assets/images/home/ad_1.png',
        ),
        isTrue,
      );
      expect(
        await AppAdvertisementHelper.isImageCached(
          'asset:assets/images/home/ad_1.png',
        ),
        isTrue,
      );
    });

    test(
      'filterCachedAdvertisements retains only valid cached items',
      () async {
        final ads = [
          const AppAdvertisement(
            id: 1,
            imageUrl: 'assets/images/home/ad_1.png',
          ),
          const AppAdvertisement(id: 2, imageUrl: ''),
          const AppAdvertisement(
            id: 3,
            imageUrl: 'assets/images/home/ad_2.png',
          ),
        ];

        final filtered =
            await AppAdvertisementHelper.filterCachedAdvertisements(ads);
        expect(filtered.map((a) => a.id), equals([1, 3]));
      },
    );

    test(
      'openAdvertisement correctly routes product_detail jumpType',
      () async {
        var openedModelId = -1;
        const ad = AppAdvertisement(
          id: 1,
          jumpType: 'product_detail',
          jumpTarget: '12',
        );

        await AppAdvertisementHelper.openAdvertisement(
          ad,
          onOpenProductDetail: (modelId) => openedModelId = modelId,
        );

        expect(openedModelId, 12);
      },
    );

    test('openAdvertisement handles external_url schema validation', () async {
      var errorTitle = '';
      const invalidAd = AppAdvertisement(
        id: 2,
        jumpType: 'external_url',
        jumpTarget: 'not_a_valid_url',
      );

      await AppAdvertisementHelper.openAdvertisement(
        invalidAd,
        onError: (title, message) => errorTitle = title,
      );

      expect(errorTitle, 'Unable to open link');
    });
  });

  testWidgets(
    'HomeDisconnectedView renders HomeAdvertisementCard when ads available',
    (tester) async {
      final dashboard = HomeDashboard(
        advertisements: [
          const AppAdvertisement(
            id: 1,
            titleEn: 'Ad 1',
            imageUrl: 'assets/images/home/ad_1.png',
          ),
          const AppAdvertisement(
            id: 2,
            titleEn: 'Ad 2',
            imageUrl: 'assets/images/home/ad_2.png',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeDisconnectedView(
              dashboard: dashboard,
              isLoading: false,
              isAuthenticated: true,
              bleCardState: const HomeBleCardState.checking(),
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

      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    },
  );
}
