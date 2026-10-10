import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/core/theme/app_theme.dart';
import 'package:cyberskin_app/core/widgets/app_lottie_background.dart';
import 'package:cyberskin_app/features/auth/domain/app_user.dart';
import 'package:cyberskin_app/features/auth/domain/auth_repository.dart';
import 'package:cyberskin_app/features/auth/presentation/auth_submit_button.dart';
import 'package:cyberskin_app/features/auth/presentation/email_address_step.dart';
import 'package:cyberskin_app/features/auth/presentation/email_verification_step.dart';
import 'package:cyberskin_app/features/auth/presentation/login_controller.dart';
import 'package:cyberskin_app/features/auth/presentation/login_page.dart';
import 'package:cyberskin_app/features/content/domain/entities/app_content.dart';
import 'package:cyberskin_app/features/content/domain/repositories/content_repository.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_liquid_glass_plus/flutter_liquid_glass.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final class _AuthRepository implements AuthRepository {
  Result<void> sendResult = const Result.ok(null);
  Completer<Result<void>>? pendingSend;
  EmailLoginRequest? submitted;
  int sends = 0;

  @override
  Future<Result<void>> sendEmailCode(String email) async {
    sends++;
    return pendingSend == null ? sendResult : await pendingSend!.future;
  }

  @override
  Future<Result<AppUser>> loginWithEmail(EmailLoginRequest request) async {
    submitted = request;
    return const Result.failure(
      AppFailure(
        code: FailureCode.business,
        message: 'Incorrect code. Please try again.',
      ),
    );
  }

  @override
  Future<Result<AppUser>> loginWithApple(AppleLoginRequest request) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> loginWithGoogle(String idToken) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> currentUser() => throw UnimplementedError();

  @override
  Future<Result<void>> logout() => throw UnimplementedError();
}

final class _ContentRepository implements ContentRepository {
  @override
  Future<AppConfiguration?> readCachedConfiguration() async => AppConfiguration(
    agreements: const [
      AppAgreement(code: 'tos', contentUrl: 'https://example.test/terms'),
      AppAgreement(
        code: 'privacy_policy',
        contentUrl: 'https://example.test/privacy',
      ),
    ],
  );

  @override
  Future<Result<AppConfiguration>> refreshConfiguration() =>
      throw UnimplementedError();

  @override
  Future<DateTime?> readLastRefreshAt() async => null;

  @override
  Future<DateTime?> readLastLaunchAt() async => null;

  @override
  Future<void> writeLastLaunchAt(DateTime value) async {}

  @override
  Future<Result<CmsPage>> getCmsPage(String code) => throw UnimplementedError();

  @override
  Future<Result<List<AppAdvertisement>>> listAdvertisements() =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  testWidgets('switches foreground in place and retains the background', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final opened = <Uri>[];
    final controller = Get.put(
      LoginController(
        _AuthRepository(),
        _ContentRepository(),
        SessionController(),
        openAgreementUrl: (uri) async {
          opened.add(uri);
          return true;
        },
      ),
    );
    await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));
    await controller.loadAgreements();
    await tester.pump();

    final background = tester.element(find.byType(AppLottieBackground));
    expect(find.textContaining('Terms of Service'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Continue with email'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    expect(tester.element(find.byType(AppLottieBackground)), same(background));
    expect(find.text('Your Email'), findsOneWidget);
    expect(tester.getSize(find.byType(AuthSubmitButton)), const Size(348, 58));
    final submit = find.descendant(
      of: find.byType(AuthSubmitButton),
      matching: find.byType(LGButton),
    );
    expect(tester.widget<LGButton>(submit).enabled, isTrue);
    expect(find.text('Next'), findsOneWidget);
    controller.sendingCode.value = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<LGButton>(submit).enabled, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.getSize(submit), const Size(58, 58));
    controller.sendingCode.value = false;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getSize(submit), const Size(348, 58));
    final pill = tester
        .widgetList<Container>(
          find.ancestor(
            of: find.byType(TextField).first,
            matching: find.byType(Container),
          ),
        )
        .where((widget) => widget.decoration is BoxDecoration)
        .first;
    expect(
      (pill.decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(100),
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(tester.element(find.byType(AppLottieBackground)), same(background));
    expect(find.text('Your Email'), findsNothing);

    final terms = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere(
          (widget) => widget.text.toPlainText().contains('Terms of Service'),
        );
    TextSpan? linkedSpan(TextSpan span) {
      if (span.text == 'Terms of Service' && span.recognizer != null) {
        return span;
      }
      for (final child in span.children ?? const <InlineSpan>[]) {
        if (child is TextSpan) {
          final result = linkedSpan(child);
          if (result != null) return result;
        }
      }
      return null;
    }

    (linkedSpan(terms.text as TextSpan)!.recognizer! as TapGestureRecognizer)
        .onTap!();
    await tester.pump();
    expect(opened, [Uri.parse('https://example.test/terms')]);
  });

  testWidgets('keeps actions reachable on narrow screens with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = Get.put(
      LoginController(
        _AuthRepository(),
        _ContentRepository(),
        SessionController(),
        openAgreementUrl: (_) async => true,
      ),
    );
    await tester.pumpWidget(
      const GetMaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(1.5),
            viewInsets: EdgeInsets.only(bottom: 220),
          ),
          child: LoginPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.bySemanticsLabel('Continue with email'));
    await tester.tap(find.bySemanticsLabel('Continue with email'));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Your Email'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'a@b.test');
    await tester.scrollUntilVisible(
      find.text('Next'),
      180,
      scrollable: find
          .descendant(
            of: find.byType(EmailAddressStep),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(find.text('6-digit code'), findsOneWidget);
    expect(find.text('Your Email'), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('verification-code-field')),
      100,
      scrollable: find
          .descendant(
            of: find.byType(EmailVerificationStep),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('verification-code-field')),
      '12a34567',
    );
    await tester.pump();
    expect(controller.code.value, '123456');
    await tester.scrollUntilVisible(
      find.text('Sign in'),
      180,
      scrollable: find
          .descendant(
            of: find.byType(EmailVerificationStep),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      tester.getSize(find.byType(AppLottieBackground)),
      const Size(320, 568),
    );
    expect(tester.takeException(), isNull);
    controller.onClose();
  });

  testWidgets(
    'email and verification switch in one page only after send succeeds',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = _AuthRepository()..pendingSend = Completer<Result<void>>();
      var now = DateTime(2026, 10, 8);
      final controller = Get.put(
        LoginController(
          auth,
          _ContentRepository(),
          SessionController(),
          clock: () => now,
        ),
      );
      await tester.pumpWidget(
        GetMaterialApp(theme: AppTheme.dark(), home: const LoginPage()),
      );
      await tester.pump();
      final background = tester.element(find.byType(AppLottieBackground));
      await tester.tap(find.bySemanticsLabel('Continue with email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.testTextInput.isVisible, isTrue);
      final emailClientArgs =
          tester.testTextInput.setClientArgs! as Map<Object?, Object?>;
      expect(
        (emailClientArgs['inputType'] as Map<Object?, Object?>)['name'],
        'TextInputType.emailAddress',
      );
      await tester.enterText(find.byType(TextField), 'sent@example.test');
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.byType(EmailAddressStep), findsOneWidget);
      expect(find.byType(EmailVerificationStep), findsNothing);
      auth.pendingSend!.complete(const Result.ok(null));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(find.byType(EmailVerificationStep), findsOneWidget);
      expect(
        tester.element(find.byType(AppLottieBackground)),
        same(background),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(find.byType(EmailAddressStep), findsNothing);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.testTextInput.isVisible, isTrue);
      final verificationClientArgs =
          tester.testTextInput.setClientArgs! as Map<Object?, Object?>;
      expect(
        (verificationClientArgs['inputType'] as Map<Object?, Object?>)['name'],
        'TextInputType.number',
      );
      expect(
        find.text('Enter the code sent to sent@example.test'),
        findsOneWidget,
      );
      expect(find.textContaining('Resend code in'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('verification-code-field')),
        '123456',
      );
      await tester.pump();
      now = now.add(const Duration(seconds: 61));
      controller.updateResendCountdown();
      await tester.pump();
      await tester.tap(find.text('Resend code'));
      await tester.pump();
      expect(controller.code.value, isEmpty);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('verification-code-field')),
            )
            .controller!
            .text,
        isEmpty,
      );
      expect(auth.sends, 2);
      await tester.enterText(
        find.byKey(const ValueKey('verification-code-field')),
        '123456',
      );
      await tester.pump();
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      expect(auth.submitted?.email, 'sent@example.test');
      expect(auth.submitted?.code, '123456');
      expect(find.text('Incorrect code. Please try again.'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.text('Your Email'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      expect(tester.testTextInput.isVisible, isTrue);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'sent@example.test',
      );
      expect(controller.code.value, isEmpty);
      expect(
        tester.element(find.byType(AppLottieBackground)),
        same(background),
      );
      await tester.tap(find.byTooltip('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.text('Your Email'), findsNothing);
      expect(
        tester.element(find.byType(AppLottieBackground)),
        same(background),
      );
      controller.onClose();
    },
  );

  testWidgets('failed send remains on email step', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = _AuthRepository()..pendingSend = Completer<Result<void>>();
    final controller = Get.put(
      LoginController(auth, _ContentRepository(), SessionController()),
    );
    await tester.pumpWidget(const GetMaterialApp(home: LoginPage()));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Continue with email'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'a@b.test');
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(controller.sendingCode.value, isTrue);
    expect(
      tester.getSize(
        find.descendant(
          of: find.byType(AuthSubmitButton),
          matching: find.byType(LGButton),
        ),
      ),
      const Size(58, 58),
    );

    auth.pendingSend!.complete(
      const Result.failure(
        AppFailure(
          code: FailureCode.business,
          businessCode: 500,
          message: 'Email service is unavailable.',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(EmailAddressStep), findsOneWidget);
    expect(find.byType(EmailVerificationStep), findsNothing);
    expect(controller.sendingCode.value, isFalse);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Email service is unavailable.'), findsOneWidget);
    expect(
      tester.getSize(
        find.descendant(
          of: find.byType(AuthSubmitButton),
          matching: find.byType(LGButton),
        ),
      ),
      const Size(348, 58),
    );
  });

  testWidgets('captures verification baseline with fixture state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 50, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.runAsync(() async {
      final font = File(
        '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      );
      if (font.existsSync()) {
        final loader = FontLoader('LoginPreview')
          ..addFont(
            Future.value(ByteData.sublistView(await font.readAsBytes())),
          );
        await loader.load();
      }
      final icons = File(
        '.fvm/flutter_sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (icons.existsSync()) {
        final loader = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(ByteData.sublistView(await icons.readAsBytes())),
          );
        await loader.load();
      }
    });
    final controller = Get.put(
      LoginController(
        _AuthRepository(),
        _ContentRepository(),
        SessionController(),
      ),
    );
    controller.verificationEmail.value = 'zhang@apple.com';
    controller.resendSecondsRemaining.value = 54;
    const capture = ValueKey('verification-capture');
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.dark().copyWith(
          textTheme: AppTheme.dark().textTheme.apply(
            fontFamily: 'LoginPreview',
          ),
        ),
        home: RepaintBoundary(
          key: capture,
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const AppLottieBackground(playbackSpeed: 1.5),
                SafeArea(
                  child: EmailVerificationStep(
                    controller: controller,
                    onBack: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(capture),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/ui').createSync(recursive: true);
        File('build/ui/login_verification_402x874_text1.0.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
    });
    expect(find.text('6-digit code'), findsOneWidget);
  });
}
