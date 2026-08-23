import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/functions/functions.dart';
import 'package:vestipro/features/invites/data/datasources/firestore_invite_data_source.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockAppClientMetadataProvider extends Mock
    implements AppClientMetadataProvider {}

/// [FirebaseFunctionsException]'s constructor is `@protected` — same trick
/// already used by `test/core/functions/cloud_functions_service_test.dart`
/// and `firestore_organization_data_source_test.dart`.
class _FakeFirebaseFunctionsException extends FirebaseFunctionsException {
  _FakeFirebaseFunctionsException(String code)
    : super(message: 'Simulated "$code" for tests.', code: code);
}

Map<String, dynamic> _inviteJson({
  String id = 'invite-1',
  String status = 'pending',
}) {
  return <String, dynamic>{
    'id': id,
    'organizationId': 'org-1',
    'email': 'novo@vestipro.com.br',
    'roleName': 'SALES_REP',
    'status': status,
    'invitedByUserId': 'owner-1',
    'invitedByName': 'Owner',
    'message': null,
    'expiresAt': '2026-01-08T00:00:00.000Z',
    'createdAt': '2026-01-01T00:00:00.000Z',
    'createdBy': 'owner-1',
    'updatedAt': '2026-01-01T00:00:00.000Z',
    'updatedBy': 'owner-1',
  };
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(HttpsCallableOptions());
  });

  group('FirestoreInviteDataSource', () {
    late _MockFirebaseFirestore firestore;
    late _MockFirebaseFunctions functions;
    late _MockHttpsCallable callable;
    late _MockFirebaseAuth auth;
    late _MockAppClientMetadataProvider metadataProvider;
    late CloudFunctionsService cloudFunctionsService;
    late FirestoreInviteDataSource dataSource;

    setUp(() {
      firestore = _MockFirebaseFirestore();
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

      cloudFunctionsService = CloudFunctionsService.withDependencies(
        functions,
        auth,
        metadataProvider,
      );

      dataSource = FirestoreInviteDataSource(cloudFunctionsService, firestore);
    });

    group('create', () {
      test('calls the createInvite callable with the right fields and '
          'parses the invite + token from the response', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn(<String, dynamic>{
          'invite': _inviteJson(),
          'token': 'raw-token-123',
          'correlationId': 'correlation-1',
        });
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        final issued = await dataSource.create(
          organizationId: 'org-1',
          email: 'novo@vestipro.com.br',
          roleName: 'SALES_REP',
          message: 'Bem-vindo!',
        );

        expect(issued.token, 'raw-token-123');
        expect(issued.invite.email, 'novo@vestipro.com.br');
        expect(issued.invite.status, 'pending');

        final captured =
            verify(
                  () => callable.call<Map<String, dynamic>>(
                    captureAny<dynamic>(),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured['organizationId'], 'org-1');
        expect(captured['email'], 'novo@vestipro.com.br');
        expect(captured['roleName'], 'SALES_REP');
        expect(captured['message'], 'Bem-vindo!');
      });

      test('omits message from the payload when not provided', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn(<String, dynamic>{
          'invite': _inviteJson(),
          'token': 'raw-token-123',
        });
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        await dataSource.create(
          organizationId: 'org-1',
          email: 'novo@vestipro.com.br',
          roleName: 'SALES_REP',
        );

        final captured =
            verify(
                  () => callable.call<Map<String, dynamic>>(
                    captureAny<dynamic>(),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured.containsKey('message'), isFalse);
      });

      test('throws ServerException when the response has no token', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(
          () => result.data,
        ).thenReturn(<String, dynamic>{'invite': _inviteJson()});
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        await expectLater(
          dataSource.create(
            organizationId: 'org-1',
            email: 'novo@vestipro.com.br',
            roleName: 'SALES_REP',
          ),
          throwsA(isA<ServerException>()),
        );
      });

      test('propagates the AppException already mapped from a '
          'FirebaseFunctionsException', () async {
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenThrow(_FakeFirebaseFunctionsException('permission-denied'));

        await expectLater(
          dataSource.create(
            organizationId: 'org-1',
            email: 'novo@vestipro.com.br',
            roleName: 'SALES_REP',
          ),
          throwsA(isA<ForbiddenException>()),
        );
      });
    });

    group('resend', () {
      test('calls the resendInvite callable and parses the reissued '
          'invite + new token', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn(<String, dynamic>{
          'invite': _inviteJson(),
          'token': 'new-raw-token',
        });
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        final issued = await dataSource.resend(
          organizationId: 'org-1',
          inviteId: 'invite-1',
        );

        expect(issued.token, 'new-raw-token');

        final captured =
            verify(
                  () => callable.call<Map<String, dynamic>>(
                    captureAny<dynamic>(),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured['organizationId'], 'org-1');
        expect(captured['inviteId'], 'invite-1');
      });

      test(
        'propagates a failed-precondition FirebaseFunctionsException',
        () async {
          when(
            () => callable.call<Map<String, dynamic>>(any<dynamic>()),
          ).thenThrow(_FakeFirebaseFunctionsException('failed-precondition'));

          await expectLater(
            dataSource.resend(organizationId: 'org-1', inviteId: 'invite-1'),
            throwsA(isA<AppException>()),
          );
        },
      );
    });

    group('revoke', () {
      test(
        'calls the revokeInvite callable and parses the revoked invite',
        () async {
          final result = _MockHttpsCallableResult<Map<String, dynamic>>();
          when(() => result.data).thenReturn(<String, dynamic>{
            'invite': _inviteJson(status: 'revoked'),
          });
          when(
            () => callable.call<Map<String, dynamic>>(any<dynamic>()),
          ).thenAnswer((_) async => result);

          final dto = await dataSource.revoke(
            organizationId: 'org-1',
            inviteId: 'invite-1',
          );

          expect(dto.status, 'revoked');

          final captured =
              verify(
                    () => callable.call<Map<String, dynamic>>(
                      captureAny<dynamic>(),
                    ),
                  ).captured.single
                  as Map<String, dynamic>;
          expect(captured['organizationId'], 'org-1');
          expect(captured['inviteId'], 'invite-1');
        },
      );

      test('throws ServerException when the response is missing the invite '
          'field', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn(<String, dynamic>{});
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        await expectLater(
          dataSource.revoke(organizationId: 'org-1', inviteId: 'invite-1'),
          throwsA(isA<ServerException>()),
        );
      });
    });
  });
}
