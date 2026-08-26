import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/functions/functions.dart';
import 'package:vestipro/features/catalog_share/data/datasources/firestore_catalog_share_data_source.dart';
import 'package:vestipro/features/catalog_share/data/dtos/catalog_share_item_dto.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockAppClientMetadataProvider extends Mock
    implements AppClientMetadataProvider {}

Map<String, dynamic> _shareJson({
  String id = 'share-1',
  String status = 'active',
}) {
  return <String, dynamic>{
    'id': id,
    'organizationId': 'org-1',
    'scope': 'product',
    'items': <Map<String, dynamic>>[
      {'productId': 'product-1', 'name': 'Camisa', 'imageUrl': null},
    ],
    'collectionId': null,
    'collectionName': null,
    'status': status,
    'openCount': 0,
    'firstOpenedAt': null,
    'lastOpenedAt': null,
    'expiresAt': '2026-02-01T00:00:00.000Z',
    'createdBy': 'rep-1',
    'createdByName': 'Rep Um',
    'createdAt': '2026-01-01T00:00:00.000Z',
    'updatedAt': '2026-01-01T00:00:00.000Z',
  };
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(HttpsCallableOptions());
  });

  group('FirestoreCatalogShareDataSource', () {
    late _MockFirebaseFirestore firestore;
    late _MockFirebaseFunctions functions;
    late _MockHttpsCallable callable;
    late _MockFirebaseAuth auth;
    late _MockAppClientMetadataProvider metadataProvider;
    late CloudFunctionsService cloudFunctionsService;
    late FirestoreCatalogShareDataSource dataSource;

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

      dataSource = FirestoreCatalogShareDataSource(
        cloudFunctionsService,
        firestore,
      );
    });

    group('create', () {
      test('calls createCatalogShareLink with the right fields and parses '
          'the response', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn(<String, dynamic>{
          'share': _shareJson(),
          'token': 'raw-token',
          'correlationId': 'correlation-1',
        });
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        final issued = await dataSource.create(
          organizationId: 'org-1',
          scope: 'product',
          items: const [
            CatalogShareItemDto(productId: 'product-1', name: 'Camisa'),
          ],
        );

        expect(issued.token, 'raw-token');
        expect(issued.share.id, 'share-1');
        verify(
          () => functions.httpsCallable('createCatalogShareLink'),
        ).called(1);
        final sentPayload =
            verify(
                  () => callable.call<Map<String, dynamic>>(
                    captureAny<dynamic>(),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(sentPayload['organizationId'], 'org-1');
        expect(sentPayload['scope'], 'product');
        expect(sentPayload.containsKey('collectionId'), isFalse);
      });

      test('throws ServerException when the response has no token', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn(<String, dynamic>{
          'share': _shareJson(),
          'correlationId': 'correlation-1',
        });
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        await expectLater(
          () => dataSource.create(
            organizationId: 'org-1',
            scope: 'product',
            items: const [
              CatalogShareItemDto(productId: 'product-1', name: 'Camisa'),
            ],
          ),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('revoke', () {
      test(
        'calls revokeCatalogShareLink and parses the revoked share',
        () async {
          final result = _MockHttpsCallableResult<Map<String, dynamic>>();
          when(() => result.data).thenReturn(<String, dynamic>{
            'share': _shareJson(status: 'revoked'),
            'correlationId': 'correlation-1',
          });
          when(
            () => callable.call<Map<String, dynamic>>(any<dynamic>()),
          ).thenAnswer((_) async => result);

          final dto = await dataSource.revoke(
            organizationId: 'org-1',
            shareId: 'share-1',
          );

          expect(dto.status, 'revoked');
          verify(
            () => functions.httpsCallable('revokeCatalogShareLink'),
          ).called(1);
        },
      );

      test('throws ServerException when the response is missing the share '
          'object', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(
          () => result.data,
        ).thenReturn(<String, dynamic>{'correlationId': 'correlation-1'});
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        await expectLater(
          () => dataSource.revoke(organizationId: 'org-1', shareId: 'share-1'),
          throwsA(isA<ServerException>()),
        );
      });
    });
  });
}
