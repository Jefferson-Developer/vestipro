import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockInviteRepository extends Mock implements InviteRepository {}

void main() {
  group('RevokeInviteUseCase', () {
    late _MockInviteRepository repository;
    late RevokeInviteUseCase useCase;

    final revokedInvite = Invite(
      id: 'invite-1',
      organizationId: 'org-1',
      email: 'novo@vestipro.com.br',
      roleName: SystemRoleName.salesRep,
      status: InviteStatus.revoked,
      invitedByUserId: 'owner-1',
      invitedByName: 'Owner',
      expiresAt: DateTime.utc(2026, 1, 8),
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'owner-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'owner-1',
    );

    setUp(() {
      repository = _MockInviteRepository();
      useCase = RevokeInviteUseCase(repository);
    });

    test('delegates to the repository with trimmed ids', () async {
      when(
        () => repository.revoke(
          organizationId: any(named: 'organizationId'),
          inviteId: any(named: 'inviteId'),
        ),
      ).thenAnswer((_) async => AppSuccess<Invite>(revokedInvite));

      final result = await useCase.call(
        organizationId: ' org-1 ',
        inviteId: ' invite-1 ',
      );

      expect(result, isA<AppSuccess<Invite>>());
      verify(
        () => repository.revoke(organizationId: 'org-1', inviteId: 'invite-1'),
      ).called(1);
    });

    test('returns a ValidationFailure without calling the repository when '
        'a required field is blank', () async {
      final result = await useCase.call(organizationId: '', inviteId: '');

      expect(result, isA<AppFailure<Invite>>());
      final failure = (result as AppFailure<Invite>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['organizationId', 'inviteId']),
      );
      verifyNever(
        () => repository.revoke(
          organizationId: any(named: 'organizationId'),
          inviteId: any(named: 'inviteId'),
        ),
      );
    });

    test('propagates a failure from the repository (e.g. revoking an '
        'already-revoked invite)', () async {
      when(
        () => repository.revoke(
          organizationId: any(named: 'organizationId'),
          inviteId: any(named: 'inviteId'),
        ),
      ).thenAnswer(
        (_) async =>
            AppFailure<Invite>(const ConflictFailure('Already revoked.')),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        inviteId: 'invite-1',
      );

      expect((result as AppFailure<Invite>).failure, isA<ConflictFailure>());
    });
  });
}
