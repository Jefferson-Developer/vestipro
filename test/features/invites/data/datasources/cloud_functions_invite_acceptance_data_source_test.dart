import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/functions/functions.dart';
import 'package:vestipro/features/invites/data/datasources/cloud_functions_invite_acceptance_data_source.dart';

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockAppClientMetadataProvider extends Mock
    implements AppClientMetadataProvider {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(HttpsCallableOptions());
  });

  group('CloudFunctionsInviteAcceptanceDataSource', () {
    late _MockFirebaseFunctions functions;
    late _MockHttpsCallable callable;
    late _MockFirebaseAuth auth;
    late _MockAppClientMetadataProvider metadataProvider;
    late CloudFunctionsService cloudFunctionsService;
    late CloudFunctionsInviteAcceptanceDataSource dataSource;

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

      cloudFunctionsService = CloudFunctionsService.withDependencies(
        functions,
        auth,
        metadataProvider,
      );

      dataSource = CloudFunctionsInviteAcceptanceDataSource(
        cloudFunctionsService,
      );
    });

    test('validate calls validateInvite and parses the response', () async {
      final result = _MockHttpsCallableResult<Map<String, dynamic>>();
      when(() => result.data).thenReturn(<String, dynamic>{
        'outcome': 'valid',
        'organizationId': 'org-1',
        'organizationName': 'Grupo Fashion XPTO',
        'email': 'convidado@vestipro.com.br',
        'roleName': 'SALES_REP',
        'correlationId': 'correlation-1',
      });
      when(
        () => callable.call<Map<String, dynamic>>(any<dynamic>()),
      ).thenAnswer((_) async => result);

      final dto = await dataSource.validate(token: 'token-123');

      expect(dto.outcome, 'valid');
      expect(dto.organizationId, 'org-1');
      verify(() => functions.httpsCallable('validateInvite')).called(1);
      final sentPayload =
          verify(
                () =>
                    callable.call<Map<String, dynamic>>(captureAny<dynamic>()),
              ).captured.single
              as Map<String, dynamic>;
      expect(sentPayload['token'], 'token-123');
    });

    test('accept calls acceptInvite and parses the response', () async {
      final result = _MockHttpsCallableResult<Map<String, dynamic>>();
      when(() => result.data).thenReturn(<String, dynamic>{
        'organizationId': 'org-1',
        'organizationName': 'Grupo Fashion XPTO',
        'roleName': 'SALES_REP',
        'correlationId': 'correlation-1',
      });
      when(
        () => callable.call<Map<String, dynamic>>(any<dynamic>()),
      ).thenAnswer((_) async => result);

      final dto = await dataSource.accept(token: 'token-123');

      expect(dto.organizationId, 'org-1');
      expect(dto.roleName, 'SALES_REP');
      verify(() => functions.httpsCallable('acceptInvite')).called(1);
    });

    test('accept throws UnauthorizedException without calling the callable '
        'when nobody is signed in', () async {
      when(() => auth.currentUser).thenReturn(null);

      await expectLater(
        () => dataSource.accept(token: 'token-123'),
        throwsA(isA<Exception>()),
      );
      verifyNever(() => functions.httpsCallable(any()));
    });
  });
}
