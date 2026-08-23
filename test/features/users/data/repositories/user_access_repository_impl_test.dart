import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/data/datasources/user_access_data_source.dart';
import 'package:vestipro/features/users/data/dtos/user_access_update_result_dto.dart';
import 'package:vestipro/features/users/data/mappers/user_access_update_result_mapper.dart';
import 'package:vestipro/features/users/data/repositories/user_access_repository_impl.dart';
import 'package:vestipro/features/users/users.dart';

class _MockUserAccessDataSource extends Mock implements UserAccessDataSource {}

void main() {
  group('UserAccessRepositoryImpl', () {
    late _MockUserAccessDataSource dataSource;
    late UserAccessRepositoryImpl repository;

    final dto = UserAccessUpdateResultDto(
      organizationId: 'org-1',
      targetUserId: 'rep-1',
      previousStatus: 'active',
      status: 'inactive',
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      dataSource = _MockUserAccessDataSource();
      repository = UserAccessRepositoryImpl(
        dataSource: dataSource,
        mapper: const UserAccessUpdateResultMapper(),
      );
    });

    test('maps a successful datasource call into a domain result', () async {
      when(
        () => dataSource.deactivateUser(
          organizationId: any(named: 'organizationId'),
          targetUserId: any(named: 'targetUserId'),
        ),
      ).thenAnswer((_) async => dto);

      final result = await repository.deactivateUser(
        organizationId: 'org-1',
        targetUserId: 'rep-1',
      );

      final update = (result as AppSuccess<UserAccessUpdateResult>).value;
      expect(update.previousStatus, MembershipStatus.active);
      expect(update.status, MembershipStatus.inactive);
      verify(
        () => dataSource.deactivateUser(
          organizationId: 'org-1',
          targetUserId: 'rep-1',
        ),
      ).called(1);
    });

    test(
      'maps an AppException thrown by the datasource into a Failure',
      () async {
        when(
          () => dataSource.reactivateUser(
            organizationId: any(named: 'organizationId'),
            targetUserId: any(named: 'targetUserId'),
          ),
        ).thenThrow(const ConflictException('Este usuário já está ativo.'));

        final result = await repository.reactivateUser(
          organizationId: 'org-1',
          targetUserId: 'rep-1',
        );

        final failure = (result as AppFailure<UserAccessUpdateResult>).failure;
        expect(failure, isA<ConflictFailure>());
        expect(failure.message, contains('ativo'));
      },
    );

    test('wraps an unexpected error as UnexpectedFailure', () async {
      when(
        () => dataSource.deactivateUser(
          organizationId: any(named: 'organizationId'),
          targetUserId: any(named: 'targetUserId'),
        ),
      ).thenThrow(Exception('boom'));

      final result = await repository.deactivateUser(
        organizationId: 'org-1',
        targetUserId: 'rep-1',
      );

      expect(
        (result as AppFailure<UserAccessUpdateResult>).failure,
        isA<UnexpectedFailure>(),
      );
    });
  });
}
