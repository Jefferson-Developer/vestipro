import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('AddUserToTeamUseCase', () {
    late _MockTeamRepository repository;
    late AddUserToTeamUseCase useCase;

    final team = Team(
      id: 'team-1',
      organizationId: 'org-1',
      name: 'Equipe Blumenau',
      memberIds: const <String>['user-1'],
      version: 2,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 2),
      updatedBy: 'user-1',
    );

    setUp(() {
      repository = _MockTeamRepository();
      useCase = AddUserToTeamUseCase(repository);
    });

    test(
      'delegates to the repository with trimmed fields on a valid payload',
      () async {
        when(
          () => repository.addMember(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
            userId: any(named: 'userId'),
            updatedBy: any(named: 'updatedBy'),
          ),
        ).thenAnswer((_) async => AppSuccess<Team>(team));

        final result = await useCase.call(
          organizationId: ' org-1 ',
          id: ' team-1 ',
          userId: ' user-1 ',
          updatedBy: ' user-2 ',
        );

        expect(result, isA<AppSuccess<Team>>());
        verify(
          () => repository.addMember(
            organizationId: 'org-1',
            id: 'team-1',
            userId: 'user-1',
            updatedBy: 'user-2',
          ),
        ).called(1);
      },
    );

    test('returns a ValidationFailure without calling the repository when '
        'required fields are blank', () async {
      final result = await useCase.call(
        organizationId: '',
        id: '',
        userId: '',
        updatedBy: '',
      );

      expect(result, isA<AppFailure<Team>>());
      final failure = (result as AppFailure<Team>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['organizationId', 'id', 'userId', 'updatedBy']),
      );
      verifyNever(
        () => repository.addMember(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
          userId: any(named: 'userId'),
          updatedBy: any(named: 'updatedBy'),
        ),
      );
    });

    test('propagates a NotFoundFailure when the team does not exist', () async {
      when(
        () => repository.addMember(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
          userId: any(named: 'userId'),
          updatedBy: any(named: 'updatedBy'),
        ),
      ).thenAnswer(
        (_) async => AppFailure<Team>(
          const NotFoundFailure('Team not found.', code: 'team_not_found'),
        ),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        id: 'missing-team',
        userId: 'user-1',
        updatedBy: 'user-2',
      );

      expect(result, isA<AppFailure<Team>>());
      expect((result as AppFailure<Team>).failure, isA<NotFoundFailure>());
    });
  });
}
