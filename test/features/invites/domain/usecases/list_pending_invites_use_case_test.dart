import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockInviteRepository extends Mock implements InviteRepository {}

void main() {
  group('ListPendingInvitesUseCase', () {
    late _MockInviteRepository repository;
    late ListPendingInvitesUseCase useCase;

    final invite = Invite(
      id: 'invite-1',
      organizationId: 'org-1',
      email: 'novo@vestipro.com.br',
      roleName: SystemRoleName.salesRep,
      status: InviteStatus.pending,
      invitedByUserId: 'owner-1',
      invitedByName: 'Owner',
      expiresAt: DateTime.utc(2026, 1, 8),
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'owner-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'owner-1',
    );

    setUp(() {
      repository = _MockInviteRepository();
      useCase = ListPendingInvitesUseCase(repository);
    });

    test('delegates to the repository with a trimmed organizationId', () async {
      when(
        () => repository.listPending('org-1'),
      ).thenAnswer((_) async => AppSuccess<List<Invite>>([invite]));

      final result = await useCase.call(' org-1 ');

      expect(result, isA<AppSuccess<List<Invite>>>());
      verify(() => repository.listPending('org-1')).called(1);
    });

    test('returns a ValidationFailure without calling the repository when '
        'organizationId is blank', () async {
      final result = await useCase.call('   ');

      expect(result, isA<AppFailure<List<Invite>>>());
      expect(
        (result as AppFailure<List<Invite>>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(() => repository.listPending(any()));
    });

    test('propagates a repository failure', () async {
      when(() => repository.listPending('org-1')).thenAnswer(
        (_) async =>
            AppFailure<List<Invite>>(const ConnectivityFailure('Offline.')),
      );

      final result = await useCase.call('org-1');

      expect(
        (result as AppFailure<List<Invite>>).failure,
        isA<ConnectivityFailure>(),
      );
    });
  });
}
