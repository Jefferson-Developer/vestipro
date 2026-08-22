import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('CreateTeamUseCase', () {
    late _MockTeamRepository repository;
    late CreateTeamUseCase useCase;

    final team = Team(
      id: 'team-1',
      organizationId: 'org-1',
      name: 'Equipe Blumenau',
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
    );

    setUp(() {
      repository = _MockTeamRepository();
      useCase = CreateTeamUseCase(repository);
    });

    test(
      'delegates to the repository with trimmed fields on a valid payload',
      () async {
        when(
          () => repository.create(
            id: any(named: 'id'),
            organizationId: any(named: 'organizationId'),
            name: any(named: 'name'),
            createdBy: any(named: 'createdBy'),
          ),
        ).thenAnswer((_) async => AppSuccess<Team>(team));

        final result = await useCase.call(
          id: ' team-1 ',
          organizationId: ' org-1 ',
          name: ' Equipe Blumenau ',
          createdBy: ' user-1 ',
        );

        expect(result, isA<AppSuccess<Team>>());
        verify(
          () => repository.create(
            id: 'team-1',
            organizationId: 'org-1',
            name: 'Equipe Blumenau',
            createdBy: 'user-1',
          ),
        ).called(1);
      },
    );

    test('returns a ValidationFailure without calling the repository when '
        'required fields are blank', () async {
      final result = await useCase.call(
        id: '',
        organizationId: '',
        name: '',
        createdBy: '',
      );

      expect(result, isA<AppFailure<Team>>());
      final failure = (result as AppFailure<Team>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['id', 'organizationId', 'name', 'createdBy']),
      );
      verifyNever(
        () => repository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });

    test('propagates a network failure from the repository', () async {
      when(
        () => repository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          createdBy: any(named: 'createdBy'),
        ),
      ).thenAnswer(
        (_) async =>
            AppFailure<Team>(const ConnectivityFailure('No connection.')),
      );

      final result = await useCase.call(
        id: 'team-1',
        organizationId: 'org-1',
        name: 'Equipe Blumenau',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Team>>());
      expect((result as AppFailure<Team>).failure, isA<ConnectivityFailure>());
    });
  });
}
