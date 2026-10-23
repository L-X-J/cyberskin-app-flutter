// 首页聚合迟到响应和 Banner 可见性回归。
import 'dart:async';

import 'package:cyberskin_app/app/app_route_visibility.dart';
import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/content/domain/entities/app_content.dart';
import 'package:cyberskin_app/features/device/domain/repositories/user_device_repository.dart';
import 'package:cyberskin_app/features/home/domain/entities/home_content.dart';
import 'package:cyberskin_app/features/home/domain/repositories/home_repository.dart';
import 'package:cyberskin_app/features/home/presentation/home_connected/home_advertisement_card.dart';
import 'package:cyberskin_app/features/home/presentation/home_connected/home_training_card.dart';
import 'package:cyberskin_app/features/home/presentation/home_controller.dart';
import 'package:cyberskin_app/features/training/domain/entities/training.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Devices extends Fake implements UserDeviceRepository {
  int model = 2;
  @override
  Future<Result<List<UserDevice>>> listUserDevices() async =>
      Result.ok([UserDevice(deviceModelId: model)]);
}

class _Home extends Fake implements HomeRepository {
  final requests = <({int? model, Completer<Result<HomeContent>> result})>[];
  @override
  Future<Result<HomeContent>> getHome({int? deviceModelId}) {
    final result = Completer<Result<HomeContent>>();
    requests.add((model: deviceModelId, result: result));
    return result.future;
  }
}

void main() {
  test(
    'late responses for an old model cannot replace new home content',
    () async {
      final devices = _Devices();
      final home = _Home();
      final controller = HomeController(
        SessionController()..markAuthenticated(),
        userDeviceRepository: devices,
        homeRepository: home,
      );
      final first = controller.load();
      await Future<void>.delayed(Duration.zero);
      devices.model = 3;
      final second = controller.load();
      await Future<void>.delayed(Duration.zero);
      expect(home.requests.map((r) => r.model), containsAll([2, 3]));
      final newest = home.requests.last;
      newest.result.complete(
        Result.ok(
          HomeContent(
            trainings: [const TrainingSummary(id: 3)],
            advertisements: [],
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      for (final request in home.requests.where((r) => !r.result.isCompleted)) {
        request.result.complete(
          Result.ok(
            HomeContent(
              trainings: [const TrainingSummary(id: 2)],
              advertisements: [],
            ),
          ),
        );
      }
      await Future.wait([first, second]);
      expect(controller.dashboard.value.trainings.single.id, 3);
      expect(controller.contentLoading.value, isFalse);
      controller.onClose();
    },
  );
  test(
    'failed home refresh preserves successful content and retry replaces it',
    () async {
      final home = _Home();
      final controller = HomeController(
        SessionController(),
        homeRepository: home,
      );
      final initial = controller.refreshContent(force: true);
      home.requests.last.result.complete(
        Result.ok(
          HomeContent(
            trainings: [const TrainingSummary(id: 1)],
            advertisements: [],
          ),
        ),
      );
      await initial;
      final failed = controller.refreshContent(force: true);
      home.requests.last.result.complete(
        const Result.failure(
          AppFailure(code: FailureCode.network, message: 'Offline'),
        ),
      );
      await failed;
      expect(controller.dashboard.value.trainings.single.id, 1);
      expect(controller.contentFailure.value?.message, 'Offline');
      final retry = controller.refreshContent(force: true);
      home.requests.last.result.complete(
        Result.ok(
          HomeContent(
            trainings: [const TrainingSummary(id: 2)],
            advertisements: [],
          ),
        ),
      );
      await retry;
      expect(controller.dashboard.value.trainings.single.id, 2);
      expect(controller.contentFailure.value, isNull);
      controller.onClose();
    },
  );
  testWidgets(
    'home recommends one real course and no example content when empty',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTrainingCard(fadeAnimation: AlwaysStoppedAnimation(1)),
          ),
        ),
      );
      expect(find.text('No training courses available.'), findsOneWidget);
      expect(find.textContaining('Beginner'), findsNothing);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HomeTrainingCard(
              fadeAnimation: AlwaysStoppedAnimation(1),
              training: TrainingSummary(
                id: 1,
                nameEn: 'Real training',
                totalSeconds: 90,
                stageCount: 2,
                intensity: '7',
              ),
            ),
          ),
        ),
      );
      expect(find.text('Real training'), findsOneWidget);
      expect(
        find.textContaining('1.5 minutes · 2 stages · Intensity 7'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'banner rotates after 5s and stops for hidden route, tab, lifecycle and reduced motion',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      final observer = RouteObserver<PageRoute<dynamic>>();
      Widget app({bool active = true, bool reduced = false, int count = 2}) =>
          MaterialApp(
            navigatorKey: navigator,
            navigatorObservers: [observer],
            builder: (context, child) =>
                AppRouteVisibility(observer: observer, child: child!),
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Scaffold(
                body: HomeAdvertisementCard(
                  fadeAnimation: const AlwaysStoppedAnimation(1),
                  active: active,
                  advertisements: List.generate(
                    count,
                    (i) => AppAdvertisement(
                      id: i,
                      titleEn: 'Ad $i',
                      imageUrl: i == 0
                          ? 'assets/images/home/device_air_banner.png'
                          : 'assets/images/home/device_pro_banner.png',
                    ),
                  ),
                ),
              ),
            ),
          );
      double page() => tester
          .widget<PageView>(find.byType(PageView, skipOffstage: false))
          .controller!
          .page!;
      await tester.pumpWidget(app());
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));
      expect(page(), 1);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      final dragPage = page();
      await tester.pump(const Duration(seconds: 6));
      expect(page(), dragPage);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Covered')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 6));
      expect(page(), 1);
      navigator.currentState!.pop();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpWidget(app(active: false));
      await tester.pump(const Duration(seconds: 6));
      expect(page(), 1);
      await tester.pumpWidget(app(reduced: true));
      await tester.pump(const Duration(seconds: 6));
      expect(page(), 1);
      await tester.pumpWidget(app());
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 6));
      expect(page(), 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));
      expect(page(), 0);
      await tester.pumpWidget(app(count: 1));
      await tester.pump(const Duration(seconds: 6));
      expect(page(), 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
