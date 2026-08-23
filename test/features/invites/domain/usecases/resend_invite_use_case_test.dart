import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockInviteRepository extends Mock implements InviteRepository {}

void main() {
  group('ResendInviteUseCase', () {
    late _MockInviteRepository repository;
    late ResendInviteUseCase useCase;

    final issuedInvite = IssuedInvite(
      invite: Invite(
        id: 'invite-1',
        organizationId: 'org-1',
        email: 'novo@vestipro.com.br',
        roleName: SystemRoleName.salesRep,
        status: InviteStatus.pending,
        invitedByUserId: 'owner-1',
        invitedByName: 'Owner',
        expiresAt: DateTime.utc(2026, 1, 15),
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 8),
        updatedBy: 'owner-1',
      ),
      token: 'new-raw-token',
    );

    setUp(() {
      repository = _MockInviteRepository();
      useCase = ResendInviteUseCase(repository);
    });

    test('delegates to the repository with trimmed ids', () async {
      when(
        () => repository.resend(
          organizationId: any(named: 'organizationId'),
          inviteId: any(named: 'inviteId'),
        ),
      ).thenAnswer((_) async => AppSuccess<IssuedInvite>(issuedInvite));

      final result = await useCase.call(
        organizationId: ' org-1 ',
        inviteId: ' invite-1 ',
      );

      expect(result, isA<AppSuccess<IssuedInvite>>());
      verify(
        () => repository.resend(organizationId: 'org-1', inviteId: 'invite-1'),
      ).called(1);
    });

    test('returns a ValidationFailure without calling the repository when '
        'a required field is blank', () async {
      final result = await useCase.call(organizationId: '', inviteId: '');

      expect(result, isA<AppFailure<IssuedInvite>>());
      final failure = (result as AppFailure<IssuedInvite>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['organizationId', 'inviteId']),
      );
      verifyNever(
        () => repository.resend(
          organizationId: any(named: 'organizationId'),
          inviteId: any(named: 'inviteId'),
        ),
      );
    });

    test('propagates a failed-precondition-style failure from the '
        'repository (e.g. resending an already-accepted invite)', () async {
      when(
        () => repository.resend(
          organizationId: any(named: 'organizationId'),
          inviteId: any(named: 'inviteId'),
        ),
      ).thenAnswer(
        (_) async => AppFailure<IssuedInvite>(
          const ConflictFailure('Already accepted.'),
        ),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        inviteId: 'invite-1',
      );

      expect(
        (result as AppFailure<IssuedInvite>).failure,
        isA<ConflictFailure>(),
      );
    });
  });
}
