import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/features/invites/data/dtos/accepted_invite_dto.dart';
import 'package:vestipro/features/invites/data/dtos/invite_preview_dto.dart';
import 'package:vestipro/features/invites/data/mappers/invite_acceptance_mapper.dart';
import 'package:vestipro/features/invites/data/mappers/invite_mapper.dart';
import 'package:vestipro/features/invites/domain/value_objects/invite_acceptance_outcome.dart';
import 'package:vestipro/features/organizations/organizations.dart';

void main() {
  group('InviteAcceptanceMapper', () {
    final mapper = InviteAcceptanceMapper(const InviteMapper());

    group('toPreviewEntity', () {
      test('maps a valid outcome with full context', () {
        const dto = InvitePreviewDto(
          outcome: 'valid',
          organizationId: 'org-1',
          organizationName: 'Grupo Fashion XPTO',
          email: 'convidado@vestipro.com.br',
          roleName: 'SALES_REP',
        );

        final entity = mapper.toPreviewEntity(dto);

        expect(entity.outcome, InviteAcceptanceOutcome.valid);
        expect(entity.organizationId, 'org-1');
        expect(entity.organizationName, 'Grupo Fashion XPTO');
        expect(entity.email, 'convidado@vestipro.com.br');
        expect(entity.roleName, SystemRoleName.salesRep);
      });

      test('maps a notFound outcome with every context field null', () {
        const dto = InvitePreviewDto(outcome: 'notFound');

        final entity = mapper.toPreviewEntity(dto);

        expect(entity.outcome, InviteAcceptanceOutcome.notFound);
        expect(entity.organizationId, isNull);
        expect(entity.roleName, isNull);
      });

      test('throws ValidationException for an unknown outcome code', () {
        const dto = InvitePreviewDto(outcome: 'not-a-real-outcome');

        expect(
          () => mapper.toPreviewEntity(dto),
          throwsA(isA<ValidationException>()),
        );
      });

      test('throws ValidationException for an unknown roleName code', () {
        const dto = InvitePreviewDto(outcome: 'valid', roleName: 'NOT_A_ROLE');

        expect(
          () => mapper.toPreviewEntity(dto),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('toAcceptedEntity', () {
      test('maps a full response', () {
        const dto = AcceptedInviteDto(
          organizationId: 'org-1',
          organizationName: 'Grupo Fashion XPTO',
          roleName: 'SALES_MANAGER',
        );

        final entity = mapper.toAcceptedEntity(dto);

        expect(entity.organizationId, 'org-1');
        expect(entity.organizationName, 'Grupo Fashion XPTO');
        expect(entity.roleName, SystemRoleName.salesManager);
      });

      test('throws ValidationException for an unknown roleName code', () {
        const dto = AcceptedInviteDto(
          organizationId: 'org-1',
          organizationName: 'Grupo Fashion XPTO',
          roleName: 'NOT_A_ROLE',
        );

        expect(
          () => mapper.toAcceptedEntity(dto),
          throwsA(isA<ValidationException>()),
        );
      });
    });
  });
}
