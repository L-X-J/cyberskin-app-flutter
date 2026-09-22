import 'package:cyberskin_app/core/error/app_failure.dart';
import 'package:cyberskin_app/core/network/api_transport.dart';
import 'package:cyberskin_app/core/network/app_api_operation.dart';
import 'package:cyberskin_app/core/network/base_remote_repository.dart';
import 'package:cyberskin_app/core/result/result.dart';
import 'package:cyberskin_app/core/storage/session_credential_store.dart';
import 'package:flutter_test/flutter_test.dart';

final class _MemorySessionStore implements SessionCredentialStore {
  _MemorySessionStore([this.value]);

  SessionCredentials? value;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount++;
    value = null;
  }

  @override
  Future<SessionCredentials?> read() async => value;

  @override
  Future<void> save(SessionCredentials credentials) async {
    value = credentials;
  }
}

final class _FakeTransport implements ApiTransport {
  _FakeTransport(this.response);

  ApiRawResponse response;
  int calls = 0;

  @override
  Future<ApiRawResponse> send(
    AppApiOperation operation, {
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, Object?> queryParameters = const <String, Object?>{},
    Object? body,
  }) async {
    calls++;
    return response;
  }
}

final class _TestRepository extends BaseRemoteRepository {
  _TestRepository({required super.transport, required super.sessionStore});

  Future<Result<String>> publicValue() => request<String>(
    AppApiOperation.appConfig,
    decode: (data) => data as String,
  );

  Future<Result<String>> protectedValue() => request<String>(
    AppApiOperation.currentUser,
    decode: (data) => data as String,
  );
}

SessionCredentials _session() => SessionCredentials(
  accessToken: 'token',
  clientId: 'client',
  expiresAt: DateTime.now().add(const Duration(hours: 1)),
);

void main() {
  test('maps business failures even when HTTP response is 200', () async {
    final store = _MemorySessionStore(_session());
    final repository = _TestRepository(
      transport: _FakeTransport(
        const ApiRawResponse(
          statusCode: 200,
          body: <String, dynamic>{'code': 500, 'msg': 'Rejected', 'data': null},
        ),
      ),
      sessionStore: store,
    );

    final result = await repository.publicValue();

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull?.code, FailureCode.business);
    expect(result.failureOrNull?.businessCode, 500);
  });

  test('clears session for business 401', () async {
    final store = _MemorySessionStore(_session());
    final transport = _FakeTransport(
      const ApiRawResponse(
        statusCode: 200,
        body: <String, dynamic>{'code': 401, 'msg': 'Expired', 'data': null},
      ),
    );
    final repository = _TestRepository(
      transport: transport,
      sessionStore: store,
    );

    final result = await repository.protectedValue();

    expect(result.failureOrNull?.code, FailureCode.unauthorized);
    expect(store.clearCount, 1);
    expect(store.value, isNull);
  });

  test('clears session for HTTP 401', () async {
    final store = _MemorySessionStore(_session());
    final repository = _TestRepository(
      transport: _FakeTransport(
        const ApiRawResponse(statusCode: 401, body: <String, dynamic>{}),
      ),
      sessionStore: store,
    );

    final result = await repository.protectedValue();

    expect(result.failureOrNull?.code, FailureCode.unauthorized);
    expect(store.clearCount, 1);
    expect(store.value, isNull);
  });

  test(
    'rejects protected request locally when no valid session exists',
    () async {
      final store = _MemorySessionStore();
      final transport = _FakeTransport(
        const ApiRawResponse(
          statusCode: 200,
          body: <String, dynamic>{'code': 200, 'msg': '', 'data': 'ok'},
        ),
      );
      final repository = _TestRepository(
        transport: transport,
        sessionStore: store,
      );

      final result = await repository.protectedValue();

      expect(result.failureOrNull?.code, FailureCode.unauthorized);
      expect(transport.calls, 0);
    },
  );
}
