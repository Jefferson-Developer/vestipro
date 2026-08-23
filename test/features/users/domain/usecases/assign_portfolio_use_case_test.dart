import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockPortfolioAssignmentRepository extends Mock
    implements PortfolioAssignmentRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('AssignPortfolioUseCase', () {
    late _MockPortfolioAssignmentRepository portfolioRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late AssignPortfolioUseCase useCase;

    Membership membership({
      String userId = 'rep-1',
      String roleName = 'SALES_REP',
      MembershipStatus status = MembershipStatus.active,
    }) {
      return Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
        roleId: roleName,
        roleName: roleName,
        status: status,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    Team team({List<String> memberIds = const <String>['rep-1']}) {
      return Team(
        id: 'team-1',
        organizationId: 'org-1',
        name: 'Equipe Sul',
        managerUserId: 'manager-1',
        memberIds: memberIds,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      );
    }

    PortfolioAssignment assignment({
      String id = 'assignment-1',
      String userId = 'rep-1',
      String teamId = 'team-1',
      String customerId = 'customer-1',
      PortfolioAssignmentStatus status = PortfolioAssignmentStatus.active,
    }) {
      return PortfolioAssignment(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: userId,
        teamId: teamId,
        scope: PortfolioAssignmentScope.customer(customerId),
        status: status,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'manager-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'manager-1',
      );
    }

    setUpAll(() {
      registerFallbackValue(assignment());
      registerFallbackValue(PortfolioAssignmentStatus.reassigned);
    });

    setUp(() {
      portfolioRepository = _MockPortfolioAssignmentRepository();
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      useCase = AssignPortfolioUseCase(
        portfolioRepository,
        membershipRepository,
        teamRepository,
      );

      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer((_) async => AppSuccess<Membership>(membership()));
      when(
        () => teamRepository.getById(organizationId: 'org-1', id: 'team-1'),
      ).thenAnswer((_) async => AppSuccess<Team>(team()));
      when(
        () => portfolioRepository.findActiveCustomerAssignment(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          customerId: any(named: 'customerId'),
        ),
      ).thenAnswer((_) async => const AppSuccess<PortfolioAssignment?>(null));
      when(() => portfolioRepository.create(any())).thenAnswer((
        invocation,
      ) async {
        final created =
            invocation.positionalArguments.first as PortfolioAssignment;
        return AppSuccess<PortfolioAssignment>(created);
      });
    });

    test(
      'creates an active customer assignment for an active SALES_REP',
      () async {
        final result = await useCase(
          id: 'assignment-new',
          organizationId: ' org-1 ',
          companyId: ' company-1 ',
          userId: ' rep-1 ',
          teamId: ' team-1 ',
          scope: const PortfolioAssignmentScope.customer(' customer-1 '),
          assignedBy: ' manager-1 ',
        );

        expect(result, isA<AppSuccess<PortfolioAssignment>>());
        final created = (result as AppSuccess<PortfolioAssignment>).value;
        expect(created.id, 'assignment-new');
        expect(created.companyId, 'company-1');
        expect(created.scope.customerId, 'customer-1');
        expect(created.status, PortfolioAssignmentStatus.active);
      },
    );

    test(
      'reassignment closes previous assignment and creates a new one',
      () async {
        final previous = assignment(id: 'assignment-old', userId: 'rep-old');
        when(
          () => portfolioRepository.findActiveCustomerAssignment(
            organizationId: 'org-1',
            companyId: 'company-1',
            customerId: 'customer-1',
          ),
        ).thenAnswer((_) async => AppSuccess<PortfolioAssignment?>(previous));
        when(
          () => portfolioRepository.endAssignment(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
            status: any(named: 'status'),
            endedAt: any(named: 'endedAt'),
            endedBy: any(named: 'endedBy'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<PortfolioAssignment>(
            assignment(
              id: 'assignment-old',
              userId: 'rep-old',
              status: PortfolioAssignmentStatus.reassigned,
            ),
          ),
        );

        final result = await useCase(
          id: 'assignment-new',
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          teamId: 'team-1',
          scope: const PortfolioAssignmentScope.customer('customer-1'),
          assignedBy: 'manager-1',
        );

        expect(result, isA<AppSuccess<PortfolioAssignment>>());
        verify(
          () => portfolioRepository.endAssignment(
            organizationId: 'org-1',
            id: 'assignment-old',
            status: PortfolioAssignmentStatus.reassigned,
            endedAt: any(named: 'endedAt'),
            endedBy: 'manager-1',
          ),
        ).called(1);
        verify(() => portfolioRepository.create(any())).called(1);
      },
    );

    test(
      'returns existing assignment when seller and team are unchanged',
      () async {
        final existing = assignment(id: 'assignment-existing');
        when(
          () => portfolioRepository.findActiveCustomerAssignment(
            organizationId: 'org-1',
            companyId: 'company-1',
            customerId: 'customer-1',
          ),
        ).thenAnswer((_) async => AppSuccess<PortfolioAssignment?>(existing));

        final result = await useCase(
          id: 'assignment-new',
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          teamId: 'team-1',
          scope: const PortfolioAssignmentScope.customer('customer-1'),
          assignedBy: 'manager-1',
        );

        expect(result, isA<AppSuccess<PortfolioAssignment>>());
        expect(
          (result as AppSuccess<PortfolioAssignment>).value.id,
          existing.id,
        );
        verifyNever(
          () => portfolioRepository.endAssignment(
            organizationId: any(named: 'organizationId'),
            id: any(named: 'id'),
            status: any(named: 'status'),
            endedAt: any(named: 'endedAt'),
            endedBy: any(named: 'endedBy'),
          ),
        );
        verifyNever(() => portfolioRepository.create(any()));
      },
    );

    test('rejects non seller portfolio owner', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(membership(roleName: 'SALES_MANAGER')),
      );

      final result = await useCase(
        id: 'assignment-new',
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        teamId: 'team-1',
        scope: const PortfolioAssignmentScope.customer('customer-1'),
        assignedBy: 'manager-1',
      );

      expect(result, isA<AppFailure<PortfolioAssignment>>());
      expect(
        (result as AppFailure<PortfolioAssignment>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(() => portfolioRepository.create(any()));
    });

    test('validates criteria assignment needs region or segment', () async {
      final result = await useCase(
        id: 'assignment-new',
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        teamId: 'team-1',
        scope: const PortfolioAssignmentScope.criteria(),
        assignedBy: 'manager-1',
      );

      expect(result, isA<AppFailure<PortfolioAssignment>>());
      final failure = (result as AppFailure<PortfolioAssignment>).failure;
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).fieldErrors, contains('criteria'));
      verifyNever(
        () => membershipRepository.getByUser(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
        ),
      );
    });
  });
}
