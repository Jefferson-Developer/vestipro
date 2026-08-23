import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/authentication/data/datasources/firestore_user_profile_data_source.dart';
import 'package:vestipro/features/authentication/data/dtos/user_profile_dto.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ignore: subtype_of_sealed_class
class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

// ignore: subtype_of_sealed_class
class _MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  group('FirestoreUserProfileDataSource', () {
    late _MockFirebaseFirestore firestore;
    late _MockCollectionReference collection;
    late _MockDocumentReference docRef;
    late FirestoreUserProfileDataSource dataSource;

    final dto = UserProfileDto(
      uid: 'user-1',
      name: 'Ana Souza',
      email: 'ana@vestipro.com.br',
      createdAt: DateTime.utc(2026, 8, 23),
      termsVersion: '2026-08-23',
      termsAcceptedAt: DateTime.utc(2026, 8, 23),
    );

    setUp(() {
      firestore = _MockFirebaseFirestore();
      collection = _MockCollectionReference();
      docRef = _MockDocumentReference();

      when(() => firestore.collection('users')).thenReturn(collection);
      when(() => collection.doc(any())).thenReturn(docRef);

      dataSource = FirestoreUserProfileDataSource(firestore);
    });

    test('writes the document at users/{uid} with the DTO payload', () async {
      when(() => docRef.set(any())).thenAnswer((_) async {});

      await dataSource.createInitialProfile(dto);

      verify(() => collection.doc('user-1')).called(1);
      verify(() => docRef.set(dto.toJson())).called(1);
    });

    test('is idempotent: a retry sets the exact same payload again', () async {
      when(() => docRef.set(any())).thenAnswer((_) async {});

      await dataSource.createInitialProfile(dto);
      await dataSource.createInitialProfile(dto);

      verify(() => docRef.set(dto.toJson())).called(2);
    });

    test('maps a FirebaseException to an AppException', () async {
      when(() => docRef.set(any())).thenThrow(
        FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );

      expect(
        () => dataSource.createInitialProfile(dto),
        throwsA(isA<AppException>()),
      );
    });
  });
}
