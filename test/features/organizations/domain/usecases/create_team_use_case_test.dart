import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockTeamRepository extends Mock implements TeamRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockOrganizationRepository extends Mock
    implements OrganizationRepository {}

void main() {
  group('CreateTeamUseCase', () {
    late _MockTeamRepository teamRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockOrganizationRepository organizationRepository;
    late CreateTeamUseCase useCase;

    final team = Team(
      id: 'team-1',
      organizationId: 'org-1',
      name: 'Equipe Blumenau',
      managerUserId: 'manager-1',
      memberIds: const <String>['rep-1'],
      version: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      createdBy: 'user-1',
      updatedAt: DateTime.utc(2026, 1, 1),
      updatedBy: 'user-1',
    );

    Membership membership({
      required String userId,
      required String roleName,
      List<String> teamIds = const <String>[],
      MembershipStatus status = MembershipStatus.active,
    }) {
      return Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
        roleId: roleName,
        roleName: roleName,
        teamIds: teamIds,
        status: status,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    Organization organization({int? maxTeamsPerUser}) {
      return Organization(
        id: 'org-1',
        name: 'VestiPro',
        slug: 'vestipro',
        settings: OrganizationSettings(
          currency: 'BRL',
          country: 'BR',
          defaultLanguage: 'pt-BR',
          maxTeamsPerUser: maxTeamsPerUser,
        ),
        status: OrganizationStatus.active,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    setUpAll(() {
      registerFallbackValue(MembershipStatus.active);
    });

    setUp(() {
      teamRepository = _MockTeamRepository();
      membershipRepository = _MockMembershipRepository();
      organizationRepository = _MockOrganizationRepository();
      useCase = CreateTeamUseCase(
        teamRepository,
        membershipRepository,
        organizationRepository,
      );
      when(
        () => organizationRepository.getById('org-1'),
      ).thenAnswer((_) async => AppSuccess<Organization>(organization()));
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(userId: 'manager-1', roleName: 'SALES_MANAGER'),
        ),
      );
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(
            userId: 'rep-1',
            roleName: 'SALES_REP',
            teamIds: const <String>['team-legacy'],
          ),
        ),
      );
      when(
        () => membershipRepository.update(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
          roleId: any(named: 'roleId'),
          roleName: any(named: 'roleName'),
          teamIds: any(named: 'teamIds'),
          status: any(named: 'status'),
          updatedBy: any(named: 'updatedBy'),
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(userId: 'rep-1', roleName: 'SALES_REP'),
        ),
      );
    });

    test(
      'delegates to the repository with trimmed fields and links members',
      () async {
        when(
          () => teamRepository.create(
            id: any(named: 'id'),
            organizationId: any(named: 'organizationId'),
            name: any(named: 'name'),
            managerUserId: any(named: 'managerUserId'),
            memberIds: any(named: 'memberIds'),
            companyId: any(named: 'companyId'),
            branchId: any(named: 'branchId'),
            createdBy: any(named: 'createdBy'),
          ),
        ).thenAnswer((_) async => AppSuccess<Team>(team));

        final result = await useCase.call(
          id: ' team-1 ',
          organizationId: ' org-1 ',
          name: ' Equipe Blumenau ',
          managerUserId: ' manager-1 ',
          memberIds: const <String>[' rep-1 ', 'rep-1'],
          createdBy: ' user-1 ',
        );

        expect(result, isA<AppSuccess<Team>>());
        verify(
          () => teamRepository.create(
            id: 'team-1',
            organizationId: 'org-1',
            name: 'Equipe Blumenau',
            managerUserId: 'manager-1',
            memberIds: const <String>['rep-1'],
            companyId: null,
            branchId: null,
            createdBy: 'user-1',
          ),
        ).called(1);
        verify(
          () => membershipRepository.update(
            organizationId: 'org-1',
            userId: 'rep-1',
            roleId: 'SALES_REP',
            roleName: 'SALES_REP',
            teamIds: const <String>['team-legacy', 'team-1'],
            status: MembershipStatus.active,
            updatedBy: 'user-1',
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
        managerUserId: '',
        createdBy: '',
      );

      expect(result, isA<AppFailure<Team>>());
      final failure = (result as AppFailure<Team>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>[
          'id',
          'organizationId',
          'name',
          'managerUserId',
          'createdBy',
        ]),
      );
      verifyNever(
        () => teamRepository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          managerUserId: any(named: 'managerUserId'),
          memberIds: any(named: 'memberIds'),
          companyId: any(named: 'companyId'),
          branchId: any(named: 'branchId'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });

    test('rejects a manager that is not SALES_MANAGER', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          membership(userId: 'manager-1', roleName: 'SALES_REP'),
        ),
      );

      final result = await useCase.call(
        id: 'team-1',
        organizationId: 'org-1',
        name: 'Equipe Blumenau',
        managerUserId: 'manager-1',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Team>>());
      expect((result as AppFailure<Team>).failure, isA<ValidationFailure>());
      verifyNever(
        () => teamRepository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          managerUserId: any(named: 'managerUserId'),
          memberIds: any(named: 'memberIds'),
          companyId: any(named: 'companyId'),
          branchId: any(named: 'branchId'),
          createdBy: any(named: 'createdBy'),
        ),
      );
    });

    test('propagates a network failure from the repository', () async {
      when(
        () => teamRepository.create(
          id: any(named: 'id'),
          organizationId: any(named: 'organizationId'),
          name: any(named: 'name'),
          managerUserId: any(named: 'managerUserId'),
          memberIds: any(named: 'memberIds'),
          companyId: any(named: 'companyId'),
          branchId: any(named: 'branchId'),
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
        managerUserId: 'manager-1',
        createdBy: 'user-1',
      );

      expect(result, isA<AppFailure<Team>>());
      expect((result as AppFailure<Team>).failure, isA<ConnectivityFailure>());
    });
  });
}
