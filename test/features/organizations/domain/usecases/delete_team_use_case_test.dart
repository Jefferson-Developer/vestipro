import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('DeleteTeamUseCase', () {
    late _MockTeamRepository repository;
    late DeleteTeamUseCase useCase;

    Team team() {
      return Team(
        id: 'team-1',
        organizationId: 'org-1',
        name: 'Equipe Sul',
        managerUserId: 'manager-1',
        version: 2,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 2),
        updatedBy: 'manager-1',
        deletedAt: DateTime.utc(2026, 1, 2),
      );
    }

    setUp(() {
      repository = _MockTeamRepository();
      useCase = DeleteTeamUseCase(repository);
    });

    test('blocks deletion when the team has customer/order links', () async {
      when(
        () => repository.hasCommercialLinks(
          organizationId: 'org-1',
          id: 'team-1',
        ),
      ).thenAnswer((_) async => const AppSuccess<bool>(true));

      final result = await useCase(
        organizationId: 'org-1',
        id: 'team-1',
        deletedBy: 'manager-1',
      );

      expect(result, isA<AppFailure<Team>>());
      expect((result as AppFailure<Team>).failure, isA<ConflictFailure>());
      verifyNever(
        () => repository.delete(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
          deletedBy: any(named: 'deletedBy'),
        ),
      );
    });

    test('soft deletes the team when no commercial link exists', () async {
      when(
        () => repository.hasCommercialLinks(
          organizationId: 'org-1',
          id: 'team-1',
        ),
      ).thenAnswer((_) async => const AppSuccess<bool>(false));
      when(
        () => repository.delete(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
          deletedBy: any(named: 'deletedBy'),
        ),
      ).thenAnswer((_) async => AppSuccess<Team>(team()));

      final result = await useCase(
        organizationId: 'org-1',
        id: 'team-1',
        deletedBy: 'manager-1',
      );

      expect(result, isA<AppSuccess<Team>>());
      verify(
        () => repository.delete(
          organizationId: 'org-1',
          id: 'team-1',
          deletedBy: 'manager-1',
        ),
      ).called(1);
    });
  });
}
