import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/functions/functions.dart';

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockAppClientMetadataProvider extends Mock
    implements AppClientMetadataProvider {}

class _MockUuid extends Mock implements Uuid {}

/// [FirebaseFunctionsException]'s constructor is `@protected` — only a
/// subclass may call it (via `super(...)`), which is exactly what this test
/// double does, so tests can simulate a real error code without touching
/// the SDK's actual error-construction path.
class _FakeFirebaseFunctionsException extends FirebaseFunctionsException {
  _FakeFirebaseFunctionsException(String code)
    : super(message: 'Simulated "$code" for tests.', code: code);
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(HttpsCallableOptions());
  });

  group('CloudFunctionsService', () {
    late _MockFirebaseFunctions functions;
    late _MockHttpsCallable callable;
    late _MockFirebaseAuth auth;
    late _MockAppClientMetadataProvider metadataProvider;
    late _MockUuid uuid;

    setUp(() {
      functions = _MockFirebaseFunctions();
      callable = _MockHttpsCallable();
      auth = _MockFirebaseAuth();
      metadataProvider = _MockAppClientMetadataProvider();
      uuid = _MockUuid();

      when(
        () => functions.httpsCallable(any(), options: any(named: 'options')),
      ).thenReturn(callable);
      when(() => metadataProvider.resolve()).thenAnswer(
        (_) async => const AppClientMetadata(
          appVersion: '1.2.3',
          buildNumber: '45',
          platform: 'test',
        ),
      );
    });

    test('sends the correlation id and app metadata under the _meta key, and '
        'returns the function response', () async {
      when(() => uuid.v4()).thenReturn('fixed-correlation-id');
      final result = _MockHttpsCallableResult<Map<String, dynamic>>();
      when(() => result.data).thenReturn({'status': 'ok'});
      when(
        () => callable.call<Map<String, dynamic>>(any<dynamic>()),
      ).thenAnswer((_) async => result);

      final service = CloudFunctionsService.withDependencies(
        functions,
        auth,
        metadataProvider,
        uuid: uuid,
      );

      final response = await service.call<Map<String, dynamic>>(
        'healthCheck',
        data: {'foo': 'bar'},
      );

      expect(response, {'status': 'ok'});

      final captured =
          verify(
                () =>
                    callable.call<Map<String, dynamic>>(captureAny<dynamic>()),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['foo'], 'bar');
      expect(captured['_meta'], {
        'correlationId': 'fixed-correlation-id',
        'appVersion': '1.2.3',
        'buildNumber': '45',
        'platform': 'test',
      });
    });

    test(
      'requireAuth throws UnauthorizedException without calling the function '
      'when there is no signed-in user',
      () async {
        when(() => auth.currentUser).thenReturn(null);

        final service = CloudFunctionsService.withDependencies(
          functions,
          auth,
          metadataProvider,
        );

        await expectLater(
          service.call<Map<String, dynamic>>('healthCheck', requireAuth: true),
          throwsA(isA<UnauthorizedException>()),
        );
        verifyNever(
          () => functions.httpsCallable(any(), options: any(named: 'options')),
        );
      },
    );

    test(
      'requireAuth allows the call through when a user is signed in',
      () async {
        when(() => auth.currentUser).thenReturn(_MockUser());
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn({'status': 'ok'});
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        final service = CloudFunctionsService.withDependencies(
          functions,
          auth,
          metadataProvider,
        );

        final response = await service.call<Map<String, dynamic>>(
          'healthCheck',
          requireAuth: true,
        );

        expect(response, {'status': 'ok'});
      },
    );

    test('forwards timeout as HttpsCallableOptions', () async {
      final result = _MockHttpsCallableResult<Map<String, dynamic>>();
      when(() => result.data).thenReturn({'status': 'ok'});
      when(
        () => callable.call<Map<String, dynamic>>(any<dynamic>()),
      ).thenAnswer((_) async => result);

      final service = CloudFunctionsService.withDependencies(
        functions,
        auth,
        metadataProvider,
      );

      await service.call<Map<String, dynamic>>(
        'healthCheck',
        timeout: const Duration(seconds: 5),
      );

      final options =
          verify(
                () => functions.httpsCallable(
                  'healthCheck',
                  options: captureAny(named: 'options'),
                ),
              ).captured.single
              as HttpsCallableOptions?;
      expect(options?.timeout, const Duration(seconds: 5));
    });

    test('retries a transient error up to maxAttempts, then throws the mapped '
        'exception', () async {
      var callCount = 0;
      when(
        () => callable.call<Map<String, dynamic>>(any<dynamic>()),
      ).thenAnswer((_) async {
        callCount++;
        throw _FakeFirebaseFunctionsException('unavailable');
      });

      final service = CloudFunctionsService.withDependencies(
        functions,
        auth,
        metadataProvider,
      );

      await expectLater(
        service.call<Map<String, dynamic>>('healthCheck'),
        throwsA(isA<NetworkException>()),
      );
      expect(callCount, CloudFunctionsService.maxAttempts);
    });

    test(
      'never retries a validation error — fails on the first attempt',
      () async {
        var callCount = 0;
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async {
          callCount++;
          throw _FakeFirebaseFunctionsException('invalid-argument');
        });

        final service = CloudFunctionsService.withDependencies(
          functions,
          auth,
          metadataProvider,
        );

        await expectLater(
          service.call<Map<String, dynamic>>('healthCheck'),
          throwsA(isA<ValidationException>()),
        );
        expect(callCount, 1);
      },
    );

    test(
      'never retries a permission error — fails on the first attempt',
      () async {
        var callCount = 0;
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async {
          callCount++;
          throw _FakeFirebaseFunctionsException('permission-denied');
        });

        final service = CloudFunctionsService.withDependencies(
          functions,
          auth,
          metadataProvider,
        );

        await expectLater(
          service.call<Map<String, dynamic>>('healthCheck'),
          throwsA(isA<ForbiddenException>()),
        );
        expect(callCount, 1);
      },
    );
  });
}
