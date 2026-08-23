import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/data/datasources/user_role_data_source.dart';
import 'package:vestipro/features/users/data/dtos/user_role_update_result_dto.dart';
import 'package:vestipro/features/users/data/mappers/user_role_update_result_mapper.dart';
import 'package:vestipro/features/users/data/repositories/user_role_repository_impl.dart';
import 'package:vestipro/features/users/users.dart';

class _MockUserRoleDataSource extends Mock implements UserRoleDataSource {}

void main() {
  group('UserRoleRepositoryImpl', () {
    late _MockUserRoleDataSource dataSource;
    late UserRoleRepositoryImpl repository;

    final dto = UserRoleUpdateResultDto(
      organizationId: 'org-1',
      targetUserId: 'rep-1',
      previousRoleName: 'SALES_REP',
      roleName: 'ADMIN',
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      dataSource = _MockUserRoleDataSource();
      repository = UserRoleRepositoryImpl(
        dataSource: dataSource,
        mapper: const UserRoleUpdateResultMapper(),
      );
    });

    test('maps a successful datasource call into a domain result', () async {
      when(
        () => dataSource.updateUserRole(
          organizationId: any(named: 'organizationId'),
          targetUserId: any(named: 'targetUserId'),
          roleName: any(named: 'roleName'),
        ),
      ).thenAnswer((_) async => dto);

      final result = await repository.updateUserRole(
        organizationId: 'org-1',
        targetUserId: 'rep-1',
        roleName: SystemRoleName.admin,
      );

      final update = (result as AppSuccess<UserRoleUpdateResult>).value;
      expect(update.previousRoleName, SystemRoleName.salesRep);
      expect(update.roleName, SystemRoleName.admin);
      verify(
        () => dataSource.updateUserRole(
          organizationId: 'org-1',
          targetUserId: 'rep-1',
          roleName: 'ADMIN',
        ),
      ).called(1);
    });

    test(
      'maps an AppException thrown by the datasource into a Failure',
      () async {
        when(
          () => dataSource.updateUserRole(
            organizationId: any(named: 'organizationId'),
            targetUserId: any(named: 'targetUserId'),
            roleName: any(named: 'roleName'),
          ),
        ).thenThrow(
          const ConflictException(
            'Não é possível alterar este perfil porque ele é o último OWNER ativo da organização.',
            code: 'failed-precondition',
          ),
        );

        final result = await repository.updateUserRole(
          organizationId: 'org-1',
          targetUserId: 'owner-1',
          roleName: SystemRoleName.admin,
        );

        final failure = (result as AppFailure<UserRoleUpdateResult>).failure;
        expect(failure, isA<ConflictFailure>());
        expect(failure.message, contains('último OWNER'));
      },
    );

    test('wraps an unexpected error as UnexpectedFailure', () async {
      when(
        () => dataSource.updateUserRole(
          organizationId: any(named: 'organizationId'),
          targetUserId: any(named: 'targetUserId'),
          roleName: any(named: 'roleName'),
        ),
      ).thenThrow(Exception('boom'));

      final result = await repository.updateUserRole(
        organizationId: 'org-1',
        targetUserId: 'rep-1',
        roleName: SystemRoleName.admin,
      );

      expect(
        (result as AppFailure<UserRoleUpdateResult>).failure,
        isA<UnexpectedFailure>(),
      );
    });
  });
}
