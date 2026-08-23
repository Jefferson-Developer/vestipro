import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/invites/data/dtos/invite_dto.dart';

void main() {
  group('InviteDto', () {
    final validJson = <String, dynamic>{
      'organizationId': 'org-1',
      'email': 'novo@vestipro.com.br',
      'roleName': 'SALES_REP',
      'status': 'pending',
      'invitedByUserId': 'owner-1',
      'invitedByName': 'Owner',
      'message': 'Bem-vindo!',
      'expiresAt': Timestamp.fromDate(DateTime.utc(2026, 1, 8)),
      'createdAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'createdBy': 'owner-1',
      'updatedAt': Timestamp.fromDate(DateTime.utc(2026, 1, 1)),
      'updatedBy': 'owner-1',
    };

    test('fromJson parses a well-formed Firestore document', () {
      final dto = InviteDto.fromJson(validJson, id: 'invite-1');

      expect(dto.id, 'invite-1');
      expect(dto.email, 'novo@vestipro.com.br');
      expect(dto.roleName, 'SALES_REP');
      expect(dto.status, 'pending');
      expect(dto.message, 'Bem-vindo!');
      expect(dto.expiresAt.toUtc(), DateTime.utc(2026, 1, 8));
    });

    test('fromJson accepts a null message', () {
      final json = Map<String, dynamic>.from(validJson)..['message'] = null;

      final dto = InviteDto.fromJson(json, id: 'invite-1');

      expect(dto.message, isNull);
    });

    test('fromJson throws ValidationException for each required field '
        'missing/wrong-typed', () {
      for (final field in <String>[
        'organizationId',
        'email',
        'roleName',
        'status',
        'invitedByUserId',
        'invitedByName',
        'expiresAt',
        'createdAt',
        'createdBy',
        'updatedAt',
        'updatedBy',
      ]) {
        final json = Map<String, dynamic>.from(validJson)..remove(field);

        expect(
          () => InviteDto.fromJson(json, id: 'invite-1'),
          throwsA(isA<ValidationException>()),
          reason: 'missing $field should be rejected',
        );
      }
    });

    test('toJson roundtrips through fromJson', () {
      final dto = InviteDto.fromJson(validJson, id: 'invite-1');

      final roundTripped = InviteDto.fromJson(dto.toJson(), id: dto.id);

      expect(roundTripped.email, dto.email);
      expect(roundTripped.roleName, dto.roleName);
      expect(roundTripped.status, dto.status);
      expect(roundTripped.message, dto.message);
      expect(roundTripped.expiresAt, dto.expiresAt);
    });
  });
}
