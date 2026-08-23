import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockUserRoleRepository extends Mock implements UserRoleRepository {}

void main() {
  group('UpdateUserRoleUseCase', () {
    late _MockUserRoleRepository repository;
    late UpdateUserRoleUseCase useCase;

    final update = UserRoleUpdateResult(
      organizationId: 'org-1',
      targetUserId: 'rep-1',
      previousRoleName: SystemRoleName.salesRep,
      roleName: SystemRoleName.admin,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    setUpAll(() {
      registerFallbackValue(SystemRoleName.owner);
    });

    setUp(() {
      repository = _MockUserRoleRepository();
      useCase = UpdateUserRoleUseCase(repository);
    });

    test('delegates to the repository with trimmed ids', () async {
      when(
        () => repository.updateUserRole(
          organizationId: any(named: 'organizationId'),
          targetUserId: any(named: 'targetUserId'),
          roleName: any(named: 'roleName'),
        ),
      ).thenAnswer((_) async => AppSuccess<UserRoleUpdateResult>(update));

      final result = await useCase(
        organizationId: ' org-1 ',
        targetUserId: ' rep-1 ',
        roleName: SystemRoleName.admin,
      );

      expect(result, isA<AppSuccess<UserRoleUpdateResult>>());
      verify(
        () => repository.updateUserRole(
          organizationId: 'org-1',
          targetUserId: 'rep-1',
          roleName: SystemRoleName.admin,
        ),
      ).called(1);
    });

    test('returns ValidationFailure when ids are blank', () async {
      final result = await useCase(
        organizationId: ' ',
        targetUserId: '',
        roleName: SystemRoleName.admin,
      );

      expect(result, isA<AppFailure<UserRoleUpdateResult>>());
      final failure = (result as AppFailure<UserRoleUpdateResult>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['organizationId', 'targetUserId']),
      );
      verifyNever(
        () => repository.updateUserRole(
          organizationId: any(named: 'organizationId'),
          targetUserId: any(named: 'targetUserId'),
          roleName: any(named: 'roleName'),
        ),
      );
    });

    test('propagates the repository failure', () async {
      when(
        () => repository.updateUserRole(
          organizationId: any(named: 'organizationId'),
          targetUserId: any(named: 'targetUserId'),
          roleName: any(named: 'roleName'),
        ),
      ).thenAnswer(
        (_) async => AppFailure<UserRoleUpdateResult>(
          const ConflictFailure('Último OWNER ativo.'),
        ),
      );

      final result = await useCase(
        organizationId: 'org-1',
        targetUserId: 'owner-1',
        roleName: SystemRoleName.admin,
      );

      expect(
        (result as AppFailure<UserRoleUpdateResult>).failure.message,
        contains('OWNER'),
      );
    });
  });
}
