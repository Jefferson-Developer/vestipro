import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('GetUserMembershipUseCase', () {
    late _MockMembershipRepository repository;
    late GetUserMembershipUseCase useCase;

    final membership = Membership(
      id: 'user-1',
      organizationId: 'org-1',
      userId: 'user-1',
      roleId: 'SALES_REP',
      roleName: 'SALES_REP',
      status: MembershipStatus.active,
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
    );

    setUp(() {
      repository = _MockMembershipRepository();
      useCase = GetUserMembershipUseCase(repository);
    });

    test(
      'delegates to the repository with the trimmed organizationId/userId',
      () async {
        when(
          () => repository.getByUser(organizationId: 'org-1', userId: 'user-1'),
        ).thenAnswer((_) async => AppSuccess<Membership>(membership));

        final result = await useCase.call(
          organizationId: ' org-1 ',
          userId: ' user-1 ',
        );

        expect(result, isA<AppSuccess<Membership>>());
        verify(
          () => repository.getByUser(organizationId: 'org-1', userId: 'user-1'),
        ).called(1);
      },
    );

    test('returns a ValidationFailure without calling the repository when '
        'required fields are blank', () async {
      final result = await useCase.call(organizationId: '', userId: '');

      expect(result, isA<AppFailure<Membership>>());
      expect(
        (result as AppFailure<Membership>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(
        () => repository.getByUser(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
        ),
      );
    });

    test(
      'propagates a NotFoundFailure when the user has no membership',
      () async {
        when(
          () => repository.getByUser(organizationId: 'org-1', userId: 'user-2'),
        ).thenAnswer(
          (_) async => AppFailure<Membership>(
            const NotFoundFailure(
              'Membership not found.',
              code: 'membership_not_found',
            ),
          ),
        );

        final result = await useCase.call(
          organizationId: 'org-1',
          userId: 'user-2',
        );

        expect(result, isA<AppFailure<Membership>>());
        expect(
          (result as AppFailure<Membership>).failure,
          isA<NotFoundFailure>(),
        );
      },
    );
  });
}
