import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/functions/functions.dart';
import 'package:vestipro/features/organizations/data/datasources/firestore_organization_data_source.dart';
import 'package:vestipro/features/organizations/data/dtos/organization_dto.dart';
import 'package:vestipro/features/organizations/data/dtos/organization_settings_dto.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class _MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class _MockHttpsCallable extends Mock implements HttpsCallable {}

class _MockHttpsCallableResult<T> extends Mock
    implements HttpsCallableResult<T> {}

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockAppClientMetadataProvider extends Mock
    implements AppClientMetadataProvider {}

/// [FirebaseFunctionsException]'s constructor is `@protected` — only a
/// subclass may call it, same trick already used by
/// `test/core/functions/cloud_functions_service_test.dart`.
class _FakeFirebaseFunctionsException extends FirebaseFunctionsException {
  _FakeFirebaseFunctionsException(String code)
    : super(message: 'Simulated "$code" for tests.', code: code);
}

void main() {
  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(HttpsCallableOptions());
  });

  group('FirestoreOrganizationDataSource', () {
    late _MockFirebaseFirestore firestore;
    late _MockCollectionReference collection;
    late _MockDocumentReference docRef;
    late _MockFirebaseFunctions functions;
    late _MockHttpsCallable callable;
    late _MockFirebaseAuth auth;
    late _MockAppClientMetadataProvider metadataProvider;
    late CloudFunctionsService cloudFunctionsService;
    late FirestoreOrganizationDataSource dataSource;

    final settingsJson = const OrganizationSettingsDto(
      currency: 'BRL',
      country: 'BR',
      defaultLanguage: 'pt-BR',
    ).toJson();

    final existingDocumentData = <String, dynamic>{
      'name': 'Grupo Fashion XPTO',
      'slug': 'grupo-fashion-xpto',
      'settings': settingsJson,
      'status': 'active',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'createdBy': 'user-1',
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'updatedBy': 'user-1',
    };

    setUp(() {
      firestore = _MockFirebaseFirestore();
      collection = _MockCollectionReference();
      docRef = _MockDocumentReference();
      functions = _MockFirebaseFunctions();
      callable = _MockHttpsCallable();
      auth = _MockFirebaseAuth();
      metadataProvider = _MockAppClientMetadataProvider();

      when(() => firestore.collection('organizations')).thenReturn(collection);
      when(() => collection.doc(any())).thenReturn(docRef);
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

      dataSource = FirestoreOrganizationDataSource(
        firestore,
        cloudFunctionsService,
      );
    });

    group('create', () {
      final newDto = OrganizationDto(
        id: 'org-1',
        name: 'Grupo Fashion XPTO',
        slug: 'grupo-fashion-xpto',
        settings: const OrganizationSettingsDto(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
        ),
        status: 'active',
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'user-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'user-1',
      );

      Map<String, dynamic> callableResponse({bool alreadyExisted = false}) {
        return <String, dynamic>{
          'organization': <String, dynamic>{
            'id': 'org-1',
            'name': 'Grupo Fashion XPTO',
            'slug': 'grupo-fashion-xpto',
            'settings': <String, dynamic>{
              'currency': 'BRL',
              'country': 'BR',
              'defaultLanguage': 'pt-BR',
            },
            'status': 'active',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'createdBy': 'user-1',
            'updatedAt': '2026-01-01T00:00:00.000Z',
            'updatedBy': 'user-1',
          },
          'alreadyExisted': alreadyExisted,
          'correlationId': 'correlation-1',
        };
      }

      test('calls the createOrganization callable with the DTO fields and '
          'parses its response into an OrganizationDto', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn(callableResponse());
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        final createdDto = await dataSource.create(newDto);

        expect(createdDto.id, 'org-1');
        expect(createdDto.name, 'Grupo Fashion XPTO');
        expect(createdDto.settings.currency, 'BRL');
        expect(
          createdDto.createdAt,
          DateTime.parse('2026-01-01T00:00:00.000Z'),
        );

        final captured =
            verify(
                  () => callable.call<Map<String, dynamic>>(
                    captureAny<dynamic>(),
                  ),
                ).captured.single
                as Map<String, dynamic>;
        expect(captured['organizationId'], 'org-1');
        expect(captured['name'], 'Grupo Fashion XPTO');
        expect(captured['slug'], 'grupo-fashion-xpto');
        expect(captured['currency'], 'BRL');
        expect(captured['country'], 'BR');
        expect(captured['defaultLanguage'], 'pt-BR');
      });

      test('is idempotent: returns whatever createOrganization reports even '
          'when alreadyExisted is true', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(
          () => result.data,
        ).thenReturn(callableResponse(alreadyExisted: true));
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        final createdDto = await dataSource.create(newDto);

        expect(createdDto.id, 'org-1');
      });

      test('throws UnauthorizedException without calling the function when '
          'there is no signed-in user', () async {
        when(() => auth.currentUser).thenReturn(null);

        await expectLater(
          dataSource.create(newDto),
          throwsA(isA<UnauthorizedException>()),
        );
        verifyNever(
          () => functions.httpsCallable(any(), options: any(named: 'options')),
        );
      });

      test(
        'propagates the AppException already mapped from a '
        'FirebaseFunctionsException by the underlying CloudFunctionsService',
        () async {
          when(
            () => callable.call<Map<String, dynamic>>(any<dynamic>()),
          ).thenThrow(_FakeFirebaseFunctionsException('already-exists'));

          await expectLater(
            dataSource.create(newDto),
            throwsA(isA<ConflictException>()),
          );
        },
      );

      test('throws ServerException when the callable response is missing the '
          'organization field', () async {
        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(
          () => result.data,
        ).thenReturn(<String, dynamic>{'alreadyExisted': false});
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        await expectLater(
          dataSource.create(newDto),
          throwsA(isA<ServerException>()),
        );
      });

      test('throws ServerException when a required organization field has an '
          'unexpected type', () async {
        final malformedResponse = callableResponse();
        (malformedResponse['organization']
                as Map<String, dynamic>)['createdAt'] =
            1234;

        final result = _MockHttpsCallableResult<Map<String, dynamic>>();
        when(() => result.data).thenReturn(malformedResponse);
        when(
          () => callable.call<Map<String, dynamic>>(any<dynamic>()),
        ).thenAnswer((_) async => result);

        await expectLater(
          dataSource.create(newDto),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getById', () {
      test('returns null when the document does not exist', () async {
        final snapshot = _MockDocumentSnapshot();
        when(() => snapshot.exists).thenReturn(false);
        when(() => snapshot.data()).thenReturn(null);
        when(() => docRef.get()).thenAnswer((_) async => snapshot);

        final result = await dataSource.getById('missing');

        expect(result, isNull);
      });

      test('maps an existing document to an OrganizationDto', () async {
        final snapshot = _MockDocumentSnapshot();
        when(() => snapshot.exists).thenReturn(true);
        when(() => snapshot.data()).thenReturn(existingDocumentData);
        when(() => snapshot.id).thenReturn('org-1');
        when(() => docRef.get()).thenAnswer((_) async => snapshot);

        final result = await dataSource.getById('org-1');

        expect(result, isNotNull);
        expect(result!.id, 'org-1');
        expect(result.name, 'Grupo Fashion XPTO');
      });

      test('maps a FirebaseException to an AppException', () async {
        when(() => docRef.get()).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        );

        await expectLater(
          dataSource.getById('org-1'),
          throwsA(isA<ForbiddenException>()),
        );
      });
    });

    group('updateSettings', () {
      test(
        'updates only settings/updatedAt/updatedBy and re-reads the document',
        () async {
          final snapshot = _MockDocumentSnapshot();
          final updatedData = <String, dynamic>{
            ...existingDocumentData,
            'settings': const OrganizationSettingsDto(
              currency: 'USD',
              country: 'US',
              defaultLanguage: 'en-US',
            ).toJson(),
            'updatedBy': 'user-2',
          };

          when(() => docRef.update(any())).thenAnswer((_) async {});
          when(() => snapshot.exists).thenReturn(true);
          when(() => snapshot.data()).thenReturn(updatedData);
          when(() => snapshot.id).thenReturn('org-1');
          when(() => docRef.get()).thenAnswer((_) async => snapshot);

          final result = await dataSource.updateSettings(
            id: 'org-1',
            settings: const OrganizationSettingsDto(
              currency: 'USD',
              country: 'US',
              defaultLanguage: 'en-US',
            ),
            updatedAt: DateTime.utc(2026, 1, 2),
            updatedBy: 'user-2',
          );

          expect(result.settings.currency, 'USD');
          expect(result.updatedBy, 'user-2');

          final captured = verify(() => docRef.update(captureAny())).captured;
          final updatePayload = captured.single as Map<String, Object?>;
          expect(
            updatePayload.keys,
            containsAll(<String>['settings', 'updatedAt', 'updatedBy']),
          );
          expect(updatePayload.containsKey('id'), isFalse);
          expect(updatePayload.containsKey('name'), isFalse);
        },
      );

      test(
        'maps a not-found FirebaseException to a NotFoundException',
        () async {
          when(() => docRef.update(any())).thenThrow(
            FirebaseException(plugin: 'cloud_firestore', code: 'not-found'),
          );

          await expectLater(
            dataSource.updateSettings(
              id: 'missing',
              settings: const OrganizationSettingsDto(
                currency: 'USD',
                country: 'US',
                defaultLanguage: 'en-US',
              ),
              updatedAt: DateTime.utc(2026, 1, 2),
              updatedBy: 'user-2',
            ),
            throwsA(isA<NotFoundException>()),
          );
        },
      );
    });
  });
}
