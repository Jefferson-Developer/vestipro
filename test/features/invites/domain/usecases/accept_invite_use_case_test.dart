import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/invites/invites.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockInviteAcceptanceRepository extends Mock
    implements InviteAcceptanceRepository {}

void main() {
  group('AcceptInviteUseCase', () {
    late _MockInviteAcceptanceRepository repository;
    late AcceptInviteUseCase useCase;

    const accepted = AcceptedInvite(
      organizationId: 'org-1',
      organizationName: 'Grupo Fashion XPTO',
      roleName: SystemRoleName.salesRep,
    );

    setUp(() {
      repository = _MockInviteAcceptanceRepository();
      useCase = AcceptInviteUseCase(repository);
    });

    test('delegates to the repository with a trimmed token', () async {
      when(
        () => repository.accept(token: any(named: 'token')),
      ).thenAnswer((_) async => const AppSuccess<AcceptedInvite>(accepted));

      final result = await useCase.call(token: '  token-123  ');

      expect(result, isA<AppSuccess<AcceptedInvite>>());
      verify(() => repository.accept(token: 'token-123')).called(1);
    });

    test('returns a ValidationFailure without calling the repository when '
        'the token is blank', () async {
      final result = await useCase.call(token: '');

      expect(result, isA<AppFailure<AcceptedInvite>>());
      expect(
        (result as AppFailure<AcceptedInvite>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(() => repository.accept(token: any(named: 'token')));
    });

    test('propagates a permission failure from the repository (e.g. '
        'e-mail diverging from the invite, rejected server-side)', () async {
      when(() => repository.accept(token: any(named: 'token'))).thenAnswer(
        (_) async =>
            AppFailure<AcceptedInvite>(const PermissionFailure('Not allowed.')),
      );

      final result = await useCase.call(token: 'token-123');

      expect(result, isA<AppFailure<AcceptedInvite>>());
      expect(
        (result as AppFailure<AcceptedInvite>).failure,
        isA<PermissionFailure>(),
      );
    });
  });
}
