import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/functions/functions.dart';
import 'package:vestipro/features/users/data/datasources/cloud_functions_user_role_data_source.dart';

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockAppClientMetadataProvider extends Mock
    implements AppClientMetadataProvider {}

class _FakeFirebaseFunctionsException extends FirebaseFunctionsException {
  _FakeFirebaseFunctionsException(String code, {String? message})
    : super(message: message ?? 'Simulated "$code" for tests.', code: code);
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(HttpsCallableOptions());
  });

  group('CloudFunctionsUserRoleDataSource', () {
    late _MockFirebaseFunctions functions;
    late _MockHttpsCallable callable;
    late _MockFirebaseAuth auth;
    late _MockAppClientMetadataProvider metadataProvider;
    late CloudFunctionsUserRoleDataSource dataSource;

    setUp(() {
      functions = _MockFirebaseFunctions();
      callable = _MockHttpsCallable();
      auth = _MockFirebaseAuth();
      metadataProvider = _MockAppClientMetadataProvider();

      when(
        () => functions.httpsCallable(any(), options: any(named: 'options')),
      ).thenReturn(callable);
      when(() => auth.currentUser).thenReturn(_MockUser());
      when(() => metadataProvider.resolve()).thenAnswer(
        (_) async => const AppClientMetadata(
          appVersion: '1.0.0',
          buildNumber: '1',
          platform: 'test',
        ),
      );

      dataSource = CloudFunctionsUserRoleDataSource(
        CloudFunctionsService.withDependencies(
          functions,
          auth,
          metadataProvider,
        ),
      );
    });

    test(
      'calls updateUserRole with the right fields and parses the response',
      () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn(<String, dynamic>{
          'organizationId': 'org-1',
          'targetUserId': 'rep-1',
          'previousRoleName': 'SALES_REP',
          'roleName': 'ADMIN',
          'updatedAt': '2026-01-01T00:00:00.000Z',
          'correlationId': 'correlation-1',
        });
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        final update = await dataSource.updateUserRole(
          organizationId: 'org-1',
          targetUserId: 'rep-1',
          roleName: 'ADMIN',
        );

        expect(update.previousRoleName, 'SALES_REP');
        expect(update.roleName, 'ADMIN');
        expect(update.updatedAt, DateTime.utc(2026, 1, 1));

        final captured =
            verify(
                  () => callable.call<Map<String, dynamic>>(
                    captureAny<dynamic>(),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured['organizationId'], 'org-1');
        expect(captured['targetUserId'], 'rep-1');
        expect(captured['roleName'], 'ADMIN');
      },
    );

    test('propagates the last OWNER message as a ConflictException', () async {
      when(() => callable.call<Map<String, dynamic>>(any<dynamic>())).thenThrow(
        _FakeFirebaseFunctionsException(
          'failed-precondition',
          message:
              'Não é possível alterar este perfil porque ele é o último OWNER ativo da organização.',
        ),
      );

      await expectLater(
        dataSource.updateUserRole(
          organizationId: 'org-1',
          targetUserId: 'owner-1',
          roleName: 'ADMIN',
        ),
        throwsA(
          isA<ConflictException>().having(
            (exception) => exception.message,
            'message',
            contains('último OWNER'),
          ),
        ),
      );
    });

    test(
      'throws ServerException for an invalid callable response shape',
      () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn(<String, dynamic>{});
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        await expectLater(
          dataSource.updateUserRole(
            organizationId: 'org-1',
            targetUserId: 'rep-1',
            roleName: 'ADMIN',
          ),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });
}
