import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/authentication/data/dtos/user_profile_dto.dart';

void main() {
  group('UserProfileDto', () {
    final json = <String, dynamic>{
      'uid': 'user-1',
      'name': 'Ana Souza',
      'email': 'ana@vestipro.com.br',
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 8, 23)),
      'termsVersion': '2026-08-23',
      'termsAcceptedAt': Timestamp.fromDate(DateTime.utc(2026, 8, 23)),
    };

    test(
      'fromJson parses a full Firestore payload, uid supplied out-of-band',
      () {
        final dto = UserProfileDto.fromJson(json, uid: 'user-1');

        expect(dto.uid, 'user-1');
        expect(dto.name, 'Ana Souza');
        expect(dto.email, 'ana@vestipro.com.br');
        expect(dto.termsVersion, '2026-08-23');
        // `Timestamp.toDate()` returns local time, not UTC — compare by
        // instant (`isAtSameMomentAs`) instead of by timezone-sensitive
        // equality.
        expect(
          dto.createdAt.isAtSameMomentAs(DateTime.utc(2026, 8, 23)),
          isTrue,
        );
        expect(
          dto.termsAcceptedAt.isAtSameMomentAs(DateTime.utc(2026, 8, 23)),
          isTrue,
        );
      },
    );

    test('toJson includes uid as a field (validated by firestore.rules)', () {
      final dto = UserProfileDto.fromJson(json, uid: 'user-1');

      expect(dto.toJson()['uid'], 'user-1');
      expect(dto.toJson()['termsVersion'], '2026-08-23');
    });

    test('fromJson throws ValidationException for a missing name', () {
      final invalidJson = Map<String, dynamic>.of(json)..remove('name');

      expect(
        () => UserProfileDto.fromJson(invalidJson, uid: 'user-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('fromJson throws ValidationException for a missing termsVersion', () {
      final invalidJson = Map<String, dynamic>.of(json)..remove('termsVersion');

      expect(
        () => UserProfileDto.fromJson(invalidJson, uid: 'user-1'),
        throwsA(isA<ValidationException>()),
      );
    });

    test(
      'fromJson throws ValidationException for a non-Timestamp termsAcceptedAt',
      () {
        final invalidJson = Map<String, dynamic>.of(json)
          ..['termsAcceptedAt'] = '2026-08-23';

        expect(
          () => UserProfileDto.fromJson(invalidJson, uid: 'user-1'),
          throwsA(isA<ValidationException>()),
        );
      },
    );
  });
}
