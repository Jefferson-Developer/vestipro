import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/invites/data/dtos/invite_dto.dart';
import 'package:vestipro/features/invites/data/mappers/invite_mapper.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('InviteMapper', () {
    const mapper = InviteMapper();

    final dto = InviteDto(
      id: 'invite-1',
      organizationId: 'org-1',
      email: 'novo@vestipro.com.br',
      roleName: 'SALES_REP',
      status: 'pending',
      invitedByUserId: 'owner-1',
      invitedByName: 'Owner',
      message: 'Bem-vindo!',
      expiresAt: DateTime.utc(2026, 1, 8),
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'owner-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'owner-1',
    );

    test('toEntity converts every field, including roleName and status', () {
      final entity = mapper.toEntity(dto);

      expect(entity.id, 'invite-1');
      expect(entity.roleName, SystemRoleName.salesRep);
      expect(entity.status, InviteStatus.pending);
      expect(entity.message, 'Bem-vindo!');
    });

    test('toDto is the exact inverse of toEntity for roleName/status', () {
      final entity = mapper.toEntity(dto);

      expect(mapper.roleNameToDto(entity.roleName), dto.roleName);
      expect(mapper.statusToDto(entity.status), dto.status);
    });

    test('roleNameToEntity throws ValidationException for an unknown role', () {
      expect(
        () => mapper.roleNameToEntity('CUSTOM_ROLE'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('statusToEntity throws ValidationException for an unknown status', () {
      expect(
        () => mapper.statusToEntity('cancelled'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('roundtrips every InviteStatus/SystemRoleName code', () {
      for (final status in InviteStatus.values) {
        expect(mapper.statusToEntity(mapper.statusToDto(status)), status);
      }
      for (final role in SystemRoleName.values) {
        expect(mapper.roleNameToEntity(mapper.roleNameToDto(role)), role);
      }
    });
  });
}
