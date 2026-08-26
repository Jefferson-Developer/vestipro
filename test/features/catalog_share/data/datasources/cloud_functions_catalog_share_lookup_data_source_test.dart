import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/functions/functions.dart';
import 'package:vestipro/features/catalog_share/data/datasources/cloud_functions_catalog_share_lookup_data_source.dart';

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockAppClientMetadataProvider extends Mock
    implements AppClientMetadataProvider {}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(HttpsCallableOptions());
  });

  group('CloudFunctionsCatalogShareLookupDataSource', () {
    late _MockFirebaseFunctions functions;
    late _MockHttpsCallable callable;
    late _MockFirebaseAuth auth;
    late _MockAppClientMetadataProvider metadataProvider;
    late CloudFunctionsService cloudFunctionsService;
    late CloudFunctionsCatalogShareLookupDataSource dataSource;

    setUp(() {
      functions = _MockFirebaseFunctions();
      callable = _MockHttpsCallable();
      auth = _MockFirebaseAuth();
      metadataProvider = _MockAppClientMetadataProvider();

      when(
        () => functions.httpsCallable(any(), options: any(named: 'options')),
      ).thenReturn(callable);
      when(() => auth.currentUser).thenReturn(null);
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

      dataSource = CloudFunctionsCatalogShareLookupDataSource(
        cloudFunctionsService,
      );
    });

    test('preview calls getCatalogShareLink without requiring auth and '
        'parses the response', () async {
      final result = _MockHttpsCallableResult<Map<String, dynamic>>();
      when(() => result.data).thenReturn(<String, dynamic>{
        'outcome': 'valid',
        'organizationName': 'Grupo Fashion XPTO',
        'scope': 'product',
        'items': <Map<String, dynamic>>[
          {'productId': 'product-1', 'name': 'Camisa', 'imageUrl': null},
        ],
        'collectionName': null,
        'expiresAt': '2026-02-01T00:00:00.000Z',
        'correlationId': 'correlation-1',
      });
      when(
        () => callable.call<Map<String, dynamic>>(any<dynamic>()),
      ).thenAnswer((_) async => result);

      final dto = await dataSource.preview(token: 'token-123');

      expect(dto.outcome, 'valid');
      expect(dto.items, hasLength(1));
      verify(() => functions.httpsCallable('getCatalogShareLink')).called(1);
      final sentPayload =
          verify(
                () =>
                    callable.call<Map<String, dynamic>>(captureAny<dynamic>()),
              ).captured.single
              as Map<String, dynamic>;
      expect(sentPayload['token'], 'token-123');
    });

    test('registerOpen calls registerCatalogShareOpen without requiring '
        'auth', () async {
      final result = _MockHttpsCallableResult<Map<String, dynamic>>();
      when(() => result.data).thenReturn(<String, dynamic>{
        'recorded': true,
        'correlationId': 'correlation-1',
      });
      when(
        () => callable.call<Map<String, dynamic>>(any<dynamic>()),
      ).thenAnswer((_) async => result);

      await dataSource.registerOpen(token: 'token-123');

      verify(
        () => functions.httpsCallable('registerCatalogShareOpen'),
      ).called(1);
    });

    test(
      'registerOpen swallows any callable failure without throwing',
      () async {
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenThrow(Exception('network error'));

        await expectLater(
          dataSource.registerOpen(token: 'token-123'),
          completes,
        );
      },
    );
  });
}
