import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockInviteRepository extends Mock implements InviteRepository {}

void main() {
  group('CreateInviteUseCase', () {
    late _MockInviteRepository repository;
    late CreateInviteUseCase useCase;

    final issuedInvite = IssuedInvite(
      invite: Invite(
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
      ),
      token: 'raw-token',
    );

    setUpAll(() {
      registerFallbackValue(SystemRoleName.owner);
    });

    setUp(() {
      repository = _MockInviteRepository();
      useCase = CreateInviteUseCase(repository);
    });

    test('delegates to the repository with trimmed fields on a valid '
        'payload', () async {
      when(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          email: any(named: 'email'),
          roleName: any(named: 'roleName'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => AppSuccess<IssuedInvite>(issuedInvite));

      final result = await useCase.call(
        organizationId: ' org-1 ',
        email: ' novo@vestipro.com.br ',
        roleName: SystemRoleName.salesRep,
        message: '  Bem-vindo!  ',
      );

      expect(result, isA<AppSuccess<IssuedInvite>>());
      verify(
        () => repository.create(
          organizationId: 'org-1',
          email: 'novo@vestipro.com.br',
          roleName: SystemRoleName.salesRep,
          message: 'Bem-vindo!',
        ),
      ).called(1);
    });

    test('passes null message when blank/omitted', () async {
      when(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          email: any(named: 'email'),
          roleName: any(named: 'roleName'),
          message: any(named: 'message'),
        ),
      ).thenAnswer((_) async => AppSuccess<IssuedInvite>(issuedInvite));

      await useCase.call(
        organizationId: 'org-1',
        email: 'novo@vestipro.com.br',
        roleName: SystemRoleName.salesRep,
        message: '   ',
      );

      verify(
        () => repository.create(
          organizationId: 'org-1',
          email: 'novo@vestipro.com.br',
          roleName: SystemRoleName.salesRep,
          message: null,
        ),
      ).called(1);
    });

    test('returns a ValidationFailure without calling the repository when '
        'organizationId is blank', () async {
      final result = await useCase.call(
        organizationId: '  ',
        email: 'novo@vestipro.com.br',
        roleName: SystemRoleName.salesRep,
      );

      expect(result, isA<AppFailure<IssuedInvite>>());
      final failure = (result as AppFailure<IssuedInvite>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        contains('organizationId'),
      );
      verifyNever(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          email: any(named: 'email'),
          roleName: any(named: 'roleName'),
          message: any(named: 'message'),
        ),
      );
    });

    test('returns a ValidationFailure without calling the repository when '
        'the e-mail is malformed', () async {
      final result = await useCase.call(
        organizationId: 'org-1',
        email: 'not-an-email',
        roleName: SystemRoleName.salesRep,
      );

      expect(result, isA<AppFailure<IssuedInvite>>());
      final failure = (result as AppFailure<IssuedInvite>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        contains('email'),
      );
      verifyNever(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          email: any(named: 'email'),
          roleName: any(named: 'roleName'),
          message: any(named: 'message'),
        ),
      );
    });

    test('propagates a permission failure from the repository (e.g. ADMIN '
        'trying to invite an OWNER, rejected server-side)', () async {
      when(
        () => repository.create(
          organizationId: any(named: 'organizationId'),
          email: any(named: 'email'),
          roleName: any(named: 'roleName'),
          message: any(named: 'message'),
        ),
      ).thenAnswer(
        (_) async =>
            AppFailure<IssuedInvite>(const PermissionFailure('Not allowed.')),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        email: 'novo@vestipro.com.br',
        roleName: SystemRoleName.owner,
      );

      expect(result, isA<AppFailure<IssuedInvite>>());
      expect(
        (result as AppFailure<IssuedInvite>).failure,
        isA<PermissionFailure>(),
      );
    });
  });
}
