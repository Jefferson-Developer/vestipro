import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/data/datasources/invite_data_source.dart';
import 'package:vestipro/features/invites/data/dtos/invite_dto.dart';
import 'package:vestipro/features/invites/data/mappers/invite_mapper.dart';
import 'package:vestipro/features/invites/data/repositories/invite_repository_impl.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockInviteDataSource extends Mock implements InviteDataSource {}

void main() {
  group('InviteRepositoryImpl', () {
    late _MockInviteDataSource dataSource;
    late InviteRepositoryImpl repository;

    final dto = InviteDto(
      id: 'invite-1',
      organizationId: 'org-1',
      email: 'novo@vestipro.com.br',
      roleName: 'SALES_REP',
      status: 'pending',
      invitedByUserId: 'owner-1',
      invitedByName: 'Owner',
      expiresAt: DateTime.utc(2026, 1, 8),
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'owner-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'owner-1',
    );

    setUpAll(() {
      registerFallbackValue(SystemRoleName.owner);
    });

    setUp(() {
      dataSource = _MockInviteDataSource();
      repository = InviteRepositoryImpl(
        dataSource: dataSource,
        mapper: const InviteMapper(),
      );
    });

    group('create', () {
      test('maps a successful datasource call into an IssuedInvite', () async {
        when(
          () => dataSource.create(
            organizationId: any(named: 'organizationId'),
            email: any(named: 'email'),
            roleName: any(named: 'roleName'),
            message: any(named: 'message'),
          ),
        ).thenAnswer((_) async => (invite: dto, token: 'raw-token'));

        final result = await repository.create(
          organizationId: 'org-1',
          email: 'novo@vestipro.com.br',
          roleName: SystemRoleName.salesRep,
        );

        expect(result, isA<AppSuccess<IssuedInvite>>());
        final issued = (result as AppSuccess<IssuedInvite>).value;
        expect(issued.token, 'raw-token');
        expect(issued.invite.id, 'invite-1');
      });

      test(
        'maps an AppException thrown by the datasource into a Failure',
        () async {
          when(
            () => dataSource.create(
              organizationId: any(named: 'organizationId'),
              email: any(named: 'email'),
              roleName: any(named: 'roleName'),
              message: any(named: 'message'),
            ),
          ).thenThrow(
            const ForbiddenException('Not allowed.', code: 'permission-denied'),
          );

          final result = await repository.create(
            organizationId: 'org-1',
            email: 'novo@vestipro.com.br',
            roleName: SystemRoleName.owner,
          );

          expect(
            (result as AppFailure<IssuedInvite>).failure,
            isA<PermissionFailure>(),
          );
        },
      );
    });

    group('listPending', () {
      test('maps every DTO returned by the datasource', () async {
        when(
          () => dataSource.listPending('org-1'),
        ).thenAnswer((_) async => [dto]);

        final result = await repository.listPending('org-1');

        final invites = (result as AppSuccess<List<Invite>>).value;
        expect(invites, hasLength(1));
        expect(invites.single.id, 'invite-1');
      });
    });

    group('resend', () {
      test('maps a successful datasource call into an IssuedInvite', () async {
        when(
          () => dataSource.resend(
            organizationId: any(named: 'organizationId'),
            inviteId: any(named: 'inviteId'),
          ),
        ).thenAnswer((_) async => (invite: dto, token: 'new-token'));

        final result = await repository.resend(
          organizationId: 'org-1',
          inviteId: 'invite-1',
        );

        expect((result as AppSuccess<IssuedInvite>).value.token, 'new-token');
      });
    });

    group('revoke', () {
      test('maps a successful datasource call into an Invite', () async {
        when(
          () => dataSource.revoke(
            organizationId: any(named: 'organizationId'),
            inviteId: any(named: 'inviteId'),
          ),
        ).thenAnswer((_) async => dto);

        final result = await repository.revoke(
          organizationId: 'org-1',
          inviteId: 'invite-1',
        );

        expect((result as AppSuccess<Invite>).value.id, 'invite-1');
      });

      test('wraps an unexpected error as UnexpectedFailure', () async {
        when(
          () => dataSource.revoke(
            organizationId: any(named: 'organizationId'),
            inviteId: any(named: 'inviteId'),
          ),
        ).thenThrow(Exception('boom'));

        final result = await repository.revoke(
          organizationId: 'org-1',
          inviteId: 'invite-1',
        );

        expect(
          (result as AppFailure<Invite>).failure,
          isA<UnexpectedFailure>(),
        );
      });
    });
  });
}
