import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockUserAccessRepository extends Mock implements UserAccessRepository {}

void main() {
  group('User access use cases', () {
    late _MockUserAccessRepository repository;
    late DeactivateUserUseCase deactivateUser;
    late ReactivateUserUseCase reactivateUser;

    final deactivation = UserAccessUpdateResult(
      organizationId: 'org-1',
      targetUserId: 'rep-1',
      previousStatus: MembershipStatus.active,
      status: MembershipStatus.inactive,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    setUp(() {
      repository = _MockUserAccessRepository();
      deactivateUser = DeactivateUserUseCase(repository);
      reactivateUser = ReactivateUserUseCase(repository);
    });

    test(
      'DeactivateUserUseCase delegates to the repository with trimmed ids',
      () async {
        when(
          () => repository.deactivateUser(
            organizationId: any(named: 'organizationId'),
            targetUserId: any(named: 'targetUserId'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<UserAccessUpdateResult>(deactivation),
        );

        final result = await deactivateUser(
          organizationId: ' org-1 ',
          targetUserId: ' rep-1 ',
        );

        expect(result, isA<AppSuccess<UserAccessUpdateResult>>());
        verify(
          () => repository.deactivateUser(
            organizationId: 'org-1',
            targetUserId: 'rep-1',
          ),
        ).called(1);
      },
    );

    test(
      'ReactivateUserUseCase validates blank ids without calling the repository',
      () async {
        final result = await reactivateUser(
          organizationId: ' ',
          targetUserId: '',
        );

        expect(result, isA<AppFailure<UserAccessUpdateResult>>());
        final failure = (result as AppFailure<UserAccessUpdateResult>).failure;
        expect(failure, isA<ValidationFailure>());
        expect(
          (failure as ValidationFailure).fieldErrors.keys,
          containsAll(<String>['organizationId', 'targetUserId']),
        );
        verifyNever(
          () => repository.reactivateUser(
            organizationId: any(named: 'organizationId'),
            targetUserId: any(named: 'targetUserId'),
          ),
        );
      },
    );

    test('propagates repository failures', () async {
      when(
        () => repository.deactivateUser(
          organizationId: any(named: 'organizationId'),
          targetUserId: any(named: 'targetUserId'),
        ),
      ).thenAnswer(
        (_) async => AppFailure<UserAccessUpdateResult>(
          const ConflictFailure('Último OWNER ativo.'),
        ),
      );

      final result = await deactivateUser(
        organizationId: 'org-1',
        targetUserId: 'owner-1',
      );

      expect(
        (result as AppFailure<UserAccessUpdateResult>).failure.message,
        contains('OWNER'),
      );
    });
  });
}
