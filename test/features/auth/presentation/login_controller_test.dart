import 'dart:async';

import 'package:cyberskin_app/app/session_controller.dart';
import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/features/auth/domain/app_user.dart';
import 'package:cyberskin_app/features/auth/domain/auth_repository.dart';
import 'package:cyberskin_app/features/auth/presentation/login_controller.dart';
import 'package:cyberskin_app/features/content/domain/entities/app_content.dart';
import 'package:cyberskin_app/features/content/domain/repositories/content_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

final class _FakeAuthRepository implements AuthRepository {
  Result<void> sendCodeResult = const Result.ok(null);
  Result<AppUser> loginResult = const Result.ok(AppUser(email: 'a@b.test'));
  final sentEmails = <String>[];
  EmailLoginRequest? lastLogin;
  Completer<Result<void>>? pendingSend;

  @override
  Future<Result<void>> sendEmailCode(String email) async {
    sentEmails.add(email);
    return pendingSend == null ? sendCodeResult : await pendingSend!.future;
  }

  @override
  Future<Result<AppUser>> loginWithEmail(EmailLoginRequest request) async {
    lastLogin = request;
    return loginResult;
  }

  @override
  Future<Result<AppUser>> loginWithGoogle(String idToken) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> loginWithApple(AppleLoginRequest request) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> currentUser() => throw UnimplementedError();

  @override
  Future<Result<void>> logout() => throw UnimplementedError();
}

final class _FakeContentRepository implements ContentRepository {
  AppConfiguration? cached;
  Result<AppConfiguration> refreshed = Result.ok(AppConfiguration());
  int refreshCalls = 0;

  @override
  Future<Result<AppConfiguration>> refreshConfiguration() async {
    refreshCalls++;
    return refreshed;
  }

  @override
  Future<AppConfiguration?> readCachedConfiguration() async => cached;

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

  test('validates email before sending a code', () async {
    final controller = LoginController(
      _FakeAuthRepository(),
      _FakeContentRepository(),
      SessionController(),
    );

    await controller.sendCode();

    expect(controller.failure.value?.code, FailureCode.business);
    expect(controller.codeSent.value, isFalse);
  });

  test('marks session authenticated after email login', () async {
    final session = SessionController();
    final auth = _FakeAuthRepository();
    final controller = LoginController(auth, _FakeContentRepository(), session);
    controller.email.value = 'a@b.test';
    controller.verificationEmail.value = 'a@b.test';
    controller.code.value = '123456';

    await controller.signInWithEmail();

    expect(session.state.value, SessionState.authenticated);
    expect(controller.failure.value, isNull);
  });

  test('confirms verification email only after sending successfully', () async {
    final controller = LoginController(
      _FakeAuthRepository(),
      _FakeContentRepository(),
      SessionController(),
    );
    addTearDown(controller.onClose);
    controller.email.value = 'a@b.test';

    expect(await controller.sendCode(), isTrue);

    expect(controller.codeSent.value, isTrue);
    expect(controller.verificationEmail.value, 'a@b.test');
    expect(controller.resendSecondsRemaining.value, 60);
  });

  test(
    'keeps failed sends in the email step without starting cooldown',
    () async {
      final auth = _FakeAuthRepository()
        ..sendCodeResult = const Result.failure(
          AppFailure(code: FailureCode.business, message: 'Try later.'),
        );
      final controller = LoginController(
        auth,
        _FakeContentRepository(),
        SessionController(),
      );
      addTearDown(controller.onClose);
      controller.email.value = 'a@b.test';
      expect(await controller.sendCode(), isFalse);
      expect(controller.verificationEmail.value, isEmpty);
      expect(controller.resendSecondsRemaining.value, 0);
    },
  );

  test(
    'resends after deadline using confirmed email and clears old code',
    () async {
      var now = DateTime(2026, 10, 8);
      final auth = _FakeAuthRepository();
      final controller = LoginController(
        auth,
        _FakeContentRepository(),
        SessionController(),
        clock: () => now,
      );
      addTearDown(controller.onClose);
      controller.email.value = 'a@b.test';
      await controller.sendCode();
      controller.email.value = 'changed@b.test';
      controller.code.value = '123456';
      expect(await controller.resendCode(), isFalse);
      now = now.add(const Duration(seconds: 61));
      expect(await controller.resendCode(), isTrue);
      expect(auth.sentEmails, ['a@b.test', 'a@b.test']);
      expect(controller.code.value, isEmpty);
      expect(controller.resendSecondsRemaining.value, 60);
    },
  );

  test(
    'ignores pending send after returning and prevents duplicate requests',
    () async {
      final auth = _FakeAuthRepository()
        ..pendingSend = Completer<Result<void>>();
      final controller = LoginController(
        auth,
        _FakeContentRepository(),
        SessionController(),
      );
      addTearDown(controller.onClose);
      controller.email.value = 'a@b.test';
      final sending = controller.sendCode();
      expect(await controller.sendCode(), isFalse);
      controller.resetEmailVerification();
      auth.pendingSend!.complete(const Result.ok(null));
      expect(await sending, isFalse);
      expect(controller.verificationEmail.value, isEmpty);
      expect(auth.sentEmails, ['a@b.test']);
    },
  );

  test(
    'returning to email preserves address and same-address resend cooldown',
    () async {
      final auth = _FakeAuthRepository();
      final controller = LoginController(
        auth,
        _FakeContentRepository(),
        SessionController(),
      );
      addTearDown(controller.onClose);
      controller.email.value = 'a@b.test';
      await controller.sendCode();
      controller.code.value = '123456';
      controller.resetEmailVerification();
      expect(controller.email.value, 'a@b.test');
      expect(controller.code.value, isEmpty);
      expect(await controller.sendCode(), isTrue);
      expect(auth.sentEmails, ['a@b.test']);
    },
  );

  test('requires six digits and submits the confirmed email', () async {
    final auth = _FakeAuthRepository()
      ..loginResult = const Result.failure(
        AppFailure(code: FailureCode.business, message: 'Incorrect code.'),
      );
    final controller = LoginController(
      auth,
      _FakeContentRepository(),
      SessionController(),
    );
    controller.verificationEmail.value = 'sent@b.test';
    controller.email.value = 'changed@b.test';
    controller.code.value = '123';
    await controller.signInWithEmail();
    expect(auth.lastLogin, isNull);
    controller.code.value = '123456';
    await controller.signInWithEmail();
    expect(auth.lastLogin?.email, 'sent@b.test');
    expect(auth.lastLogin?.code, '123456');
  });

  test(
    'exposes unsupported state until social provider is configured',
    () async {
      final controller = LoginController(
        _FakeAuthRepository(),
        _FakeContentRepository(),
        SessionController(),
      );

      await controller.signInWithGoogle();

      expect(controller.failure.value?.code, FailureCode.unsupported);
    },
  );

  test('opens agreements by code from cached configuration', () async {
    final content = _FakeContentRepository()
      ..cached = AppConfiguration(
        agreements: const [
          AppAgreement(
            code: 'privacy_policy',
            contentUrl: 'https://example.test/privacy',
          ),
          AppAgreement(code: 'tos', contentUrl: 'https://example.test/terms'),
        ],
      );
    final opened = <Uri>[];
    final controller = LoginController(
      _FakeAuthRepository(),
      content,
      SessionController(),
      openAgreementUrl: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    await controller.loadAgreements();
    await controller.openAgreement('tos');
    await controller.openAgreement('privacy_policy');

    expect(opened.map((uri) => uri.path), ['/terms', '/privacy']);
    expect(content.refreshCalls, 0);
    expect(controller.failure.value, isNull);
  });

  test('refreshes absent cache and rejects unsafe or missing URLs', () async {
    final content = _FakeContentRepository()
      ..refreshed = Result.ok(
        AppConfiguration(
          agreements: const [
            AppAgreement(code: 'tos', contentUrl: 'javascript:alert(1)'),
            AppAgreement(
              code: 'privacy_policy',
              contentUrl: 'http://example.test/privacy',
            ),
          ],
        ),
      );
    final opened = <Uri>[];
    final controller = LoginController(
      _FakeAuthRepository(),
      content,
      SessionController(),
      openAgreementUrl: (uri) async {
        opened.add(uri);
        return true;
      },
    );

    await controller.loadAgreements();
    await controller.openAgreement('tos');

    expect(content.refreshCalls, 1);
    expect(controller.agreementUrls, isEmpty);
    expect(opened, isEmpty);
    expect(controller.failure.value?.code, FailureCode.business);
  });

  test('reports a failed platform H5 launch', () async {
    final content = _FakeContentRepository()
      ..cached = AppConfiguration(
        agreements: const [
          AppAgreement(code: 'tos', contentUrl: 'https://example.test/terms'),
        ],
      );
    final controller = LoginController(
      _FakeAuthRepository(),
      content,
      SessionController(),
      openAgreementUrl: (_) async => false,
    );

    await controller.loadAgreements();
    await controller.openAgreement('tos');

    expect(controller.failure.value?.message, contains('Unable to open'));
  });
}
