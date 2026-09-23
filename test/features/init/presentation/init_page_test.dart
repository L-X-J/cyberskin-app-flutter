import 'dart:async';

import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/content/domain/entities/app_content.dart';
import 'package:cyberskin_app/features/content/domain/repositories/content_repository.dart';
import 'package:cyberskin_app/features/init/presentation/init_controller.dart';
import 'package:cyberskin_app/features/init/presentation/init_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// 初始化页面测试使用的可控 Repository。
final class _FakeContentRepository implements ContentRepository {
  _FakeContentRepository({required this.refreshFuture});

  final Future<Result<AppConfiguration>> refreshFuture;

  @override
  Future<AppConfiguration?> readCachedConfiguration() async => null;

  @override
  Future<DateTime?> readLastRefreshAt() async => null;

  @override
  Future<DateTime?> readLastLaunchAt() async => null;

  @override
  Future<void> writeLastLaunchAt(DateTime value) async {}

  @override
  Future<Result<AppConfiguration>> refreshConfiguration() => refreshFuture;

  @override
  Future<Result<CmsPage>> getCmsPage(String code) => throw UnimplementedError();

  @override
  Future<Result<List<AppAdvertisement>>> listAdvertisements() =>
      throw UnimplementedError();
}

void main() {
  tearDown(Get.reset);

  testWidgets('keeps shimmer running and delays the progress indicator', (
    tester,
  ) async {
    final refreshCompleter = Completer<Result<AppConfiguration>>();
    final repository = _FakeContentRepository(
      refreshFuture: refreshCompleter.future,
    );
    Get.put(InitController(repository, navigateToNextPage: () async {}));

    await tester.pumpWidget(const GetMaterialApp(home: InitPage()));
    await tester.pump();

    final shimmer = find.byKey(const ValueKey('init_loading_shimmer'));
    final progressIndicator = find.byType(CircularProgressIndicator);

    expect(shimmer, findsOneWidget);
    expect(progressIndicator, findsNothing);

    await tester.pump(const Duration(seconds: 2));

    expect(progressIndicator, findsOneWidget);
    expect(find.text('Loading···'), findsOneWidget);
    final loadingText = tester.renderObject<RenderParagraph>(
      find.text('Loading···'),
    );
    expect(loadingText.text.style?.decoration, TextDecoration.none);

    refreshCompleter.complete(
      const Result.failure(
        AppFailure(code: FailureCode.network, message: 'offline'),
      ),
    );
    await tester.pump();
  });
}
