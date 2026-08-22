import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
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

class _MockTransaction extends Mock implements Transaction {}

Future<T> _runFakeTransaction<T>(
  Transaction transaction,
  Invocation invocation,
) {
  final handler =
      invocation.positionalArguments.first as Future<T> Function(Transaction);
  return handler(transaction);
}

void main() {
  group('FirestoreOrganizationDataSource', () {
    late _MockFirebaseFirestore firestore;
    late _MockCollectionReference collection;
    late _MockDocumentReference docRef;
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

      when(() => firestore.collection('organizations')).thenReturn(collection);
      when(() => collection.doc(any())).thenReturn(docRef);

      dataSource = FirestoreOrganizationDataSource(firestore);
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

      test('writes the document when none exists yet', () async {
        final transaction = _MockTransaction();
        final snapshot = _MockDocumentSnapshot();

        when(() => snapshot.exists).thenReturn(false);
        when(() => snapshot.data()).thenReturn(null);
        when(
          () => transaction.get<Map<String, dynamic>>(docRef),
        ).thenAnswer((_) async => snapshot);
        when(
          () => transaction.set<Map<String, dynamic>>(docRef, any()),
        ).thenReturn(transaction);
        when(() => firestore.runTransaction<OrganizationDto>(any())).thenAnswer(
          (invocation) => _runFakeTransaction(transaction, invocation),
        );

        final result = await dataSource.create(newDto);

        expect(result.id, 'org-1');
        verify(
          () => transaction.set<Map<String, dynamic>>(docRef, newDto.toJson()),
        ).called(1);
      });

      test('is idempotent: when a retry finds the document already created, '
          'it returns what is there instead of overwriting it', () async {
        final transaction = _MockTransaction();
        final snapshot = _MockDocumentSnapshot();

        when(() => snapshot.exists).thenReturn(true);
        when(() => snapshot.data()).thenReturn(existingDocumentData);
        when(() => snapshot.id).thenReturn('org-1');
        when(
          () => transaction.get<Map<String, dynamic>>(docRef),
        ).thenAnswer((_) async => snapshot);
        when(() => firestore.runTransaction<OrganizationDto>(any())).thenAnswer(
          (invocation) => _runFakeTransaction(transaction, invocation),
        );

        final result = await dataSource.create(newDto);

        expect(result.id, 'org-1');
        expect(result.name, 'Grupo Fashion XPTO');
        verifyNever(() => transaction.set<Map<String, dynamic>>(docRef, any()));
      });

      test('maps a FirebaseException to an AppException', () async {
        when(() => firestore.runTransaction<OrganizationDto>(any())).thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        );

        await expectLater(
          dataSource.create(newDto),
          throwsA(isA<NetworkException>()),
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
