import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

void main() {
  group('EnsureCustomerInSellerPortfolioUseCase', () {
    test('allows any customer for an ADMIN/OWNER (allOrganization)', () async {
      final assignmentRepository = _FakePortfolioAssignmentRepository();
      final useCase = _buildUseCase(
        membershipRepository: _FakeMembershipRepository(
          _membership(roleName: 'ADMIN', userId: 'admin-1'),
        ),
        assignmentRepository: assignmentRepository,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'admin-1',
        customerId: 'customer-1',
      );

      expect(result, isA<AppSuccess<bool>>());
      expect((result as AppSuccess<bool>).value, isTrue);
      // allOrganization never needs to read a customer's assignment at all.
      expect(assignmentRepository.findCalls, isEmpty);
    });

    test(
      'denies every customer when the membership grants no visibility',
      () async {
        final useCase = _buildUseCase(
          membershipRepository: _FakeMembershipRepository(
            _membership(roleName: 'SALES_ASSISTANT', userId: 'assistant-1'),
          ),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'assistant-1',
          customerId: 'customer-1',
        );

        expect(result, isA<AppSuccess<bool>>());
        expect((result as AppSuccess<bool>).value, isFalse);
      },
    );

    test(
      'allows a customer whose active assignment belongs to a team the SALES_MANAGER manages',
      () async {
        final useCase = _buildUseCase(
          membershipRepository: _FakeMembershipRepository(
            _membership(roleName: 'SALES_MANAGER', userId: 'manager-1'),
          ),
          teamRepository: const _FakeTeamRepository(<Team>[]),
          managedTeams: <Team>[
            _team(id: 'team-managed', managerUserId: 'manager-1'),
          ],
          assignmentRepository: _FakePortfolioAssignmentRepository(
            assignment: _assignment(teamId: 'team-managed', userId: 'rep-1'),
          ),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'manager-1',
          customerId: 'customer-1',
        );

        expect(result, isA<AppSuccess<bool>>());
        expect((result as AppSuccess<bool>).value, isTrue);
      },
    );

    test(
      'denies a customer whose active assignment belongs to a team the SALES_MANAGER does not manage',
      () async {
        final useCase = _buildUseCase(
          membershipRepository: _FakeMembershipRepository(
            _membership(roleName: 'SALES_MANAGER', userId: 'manager-1'),
          ),
          managedTeams: <Team>[
            _team(id: 'team-managed', managerUserId: 'manager-1'),
          ],
          assignmentRepository: _FakePortfolioAssignmentRepository(
            assignment: _assignment(teamId: 'team-other', userId: 'rep-1'),
          ),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'manager-1',
          customerId: 'customer-1',
        );

        expect(result, isA<AppSuccess<bool>>());
        expect((result as AppSuccess<bool>).value, isFalse);
      },
    );

    test(
      'allows a customer whose active assignment belongs to the requesting SALES_REP',
      () async {
        final useCase = _buildUseCase(
          membershipRepository: _FakeMembershipRepository(
            _membership(roleName: 'SALES_REP', userId: 'rep-1'),
          ),
          assignmentRepository: _FakePortfolioAssignmentRepository(
            assignment: _assignment(teamId: 'team-1', userId: 'rep-1'),
          ),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          customerId: 'customer-1',
        );

        expect(result, isA<AppSuccess<bool>>());
        expect((result as AppSuccess<bool>).value, isTrue);
      },
    );

    test(
      'denies a customer whose active assignment belongs to a different SALES_REP',
      () async {
        final useCase = _buildUseCase(
          membershipRepository: _FakeMembershipRepository(
            _membership(roleName: 'SALES_REP', userId: 'rep-1'),
          ),
          assignmentRepository: _FakePortfolioAssignmentRepository(
            assignment: _assignment(teamId: 'team-1', userId: 'rep-2'),
          ),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          customerId: 'customer-1',
        );

        expect(result, isA<AppSuccess<bool>>());
        expect((result as AppSuccess<bool>).value, isFalse);
      },
    );

    test(
      'denies a customer with no active portfolio assignment at all (ownCustomers)',
      () async {
        final useCase = _buildUseCase(
          membershipRepository: _FakeMembershipRepository(
            _membership(roleName: 'SALES_REP', userId: 'rep-1'),
          ),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
          customerId: 'customer-outside-portfolio',
        );

        expect(result, isA<AppSuccess<bool>>());
        expect((result as AppSuccess<bool>).value, isFalse);
      },
    );

    test('propagates an assignment lookup failure', () async {
      final useCase = _buildUseCase(
        membershipRepository: _FakeMembershipRepository(
          _membership(roleName: 'SALES_REP', userId: 'rep-1'),
        ),
        assignmentRepository: _FakePortfolioAssignmentRepository(
          findFailure: const ConnectivityFailure('offline'),
        ),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        customerId: 'customer-1',
      );

      expect(result, isA<AppFailure<bool>>());
      expect((result as AppFailure<bool>).failure, isA<ConnectivityFailure>());
    });

    test('rejects blank required fields', () async {
      final useCase = _buildUseCase(
        membershipRepository: _FakeMembershipRepository(
          _membership(roleName: 'SALES_REP', userId: 'rep-1'),
        ),
      );

      final result = await useCase(
        organizationId: '',
        companyId: 'company-1',
        userId: 'rep-1',
        customerId: '',
      );

      expect(result, isA<AppFailure<bool>>());
      final failure = (result as AppFailure<bool>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.keys,
        containsAll(<String>['organizationId', 'customerId']),
      );
    });
  });
}

EnsureCustomerInSellerPortfolioUseCase _buildUseCase({
  required _FakeMembershipRepository membershipRepository,
  _FakeTeamRepository teamRepository = const _FakeTeamRepository(<Team>[]),
  List<Team> managedTeams = const <Team>[],
  _FakePortfolioAssignmentRepository? assignmentRepository,
}) {
  return EnsureCustomerInSellerPortfolioUseCase(
    PortfolioVisibilityService(
      membershipRepository,
      managedTeams.isEmpty ? teamRepository : _FakeTeamRepository(managedTeams),
    ),
    assignmentRepository ?? _FakePortfolioAssignmentRepository(),
  );
}

Membership _membership({
  required String roleName,
  required String userId,
  List<String> teamIds = const <String>[],
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Membership(
    id: userId,
    organizationId: 'org-1',
    userId: userId,
    roleId: roleName,
    roleName: roleName,
    status: MembershipStatus.active,
    teamIds: teamIds,
    version: 1,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
  );
}

Team _team({required String id, required String managerUserId}) {
  final now = DateTime.utc(2026, 1, 1);
  return Team(
    id: id,
    organizationId: 'org-1',
    name: id,
    managerUserId: managerUserId,
    version: 1,
    createdAt: now,
    createdBy: 'owner-1',
    updatedAt: now,
    updatedBy: 'owner-1',
  );
}

PortfolioAssignment _assignment({
  required String teamId,
  required String userId,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return PortfolioAssignment(
    id: 'assignment-1',
    organizationId: 'org-1',
    companyId: 'company-1',
    userId: userId,
    teamId: teamId,
    scope: const PortfolioAssignmentScope.customer('customer-1'),
    status: PortfolioAssignmentStatus.active,
    version: 1,
    createdAt: now,
    createdBy: 'manager-1',
    updatedAt: now,
    updatedBy: 'manager-1',
  );
}

final class _FakeMembershipRepository implements MembershipRepository {
  const _FakeMembershipRepository(this.membership);

  final Membership membership;

  @override
  Future<AppResult<Membership>> getByUser({
    required String organizationId,
    required String userId,
  }) async {
    return AppSuccess<Membership>(membership);
  }

  @override
  Future<AppResult<Membership>> create({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    List<String> teamIds = const <String>[],
    required String createdBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<Membership>>> listByOrganization(
    String organizationId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<Membership>>> listActiveByUser(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Membership>> update({
    required String organizationId,
    required String userId,
    required String roleId,
    required String roleName,
    required List<String> teamIds,
    required MembershipStatus status,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }
}

final class _FakeTeamRepository implements TeamRepository {
  const _FakeTeamRepository(this.teams);

  final List<Team> teams;

  @override
  Future<AppResult<List<Team>>> listByOrganization(
    String organizationId,
  ) async {
    return AppSuccess<List<Team>>(teams);
  }

  @override
  Future<AppResult<Team>> addMember({
    required String organizationId,
    required String id,
    required String userId,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<bool>> hasCommercialLinks({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Team>> create({
    required String id,
    required String organizationId,
    required String name,
    required String managerUserId,
    List<String> memberIds = const <String>[],
    String? companyId,
    String? branchId,
    required String createdBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Team>> delete({
    required String organizationId,
    required String id,
    required String deletedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Team>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Team>> removeMember({
    required String organizationId,
    required String id,
    required String userId,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Team>> update({
    required String organizationId,
    required String id,
    required String name,
    required String managerUserId,
    required List<String> memberIds,
    String? companyId,
    String? branchId,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }
}

final class _FakePortfolioAssignmentRepository
    implements PortfolioAssignmentRepository {
  _FakePortfolioAssignmentRepository({this.assignment, this.findFailure});

  final PortfolioAssignment? assignment;
  final Failure? findFailure;
  final List<String> findCalls = <String>[];

  @override
  Future<AppResult<PortfolioAssignment?>> findActiveCustomerAssignment({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) async {
    findCalls.add(customerId);
    final failure = findFailure;
    if (failure != null) {
      return AppFailure<PortfolioAssignment?>(failure);
    }
    return AppSuccess<PortfolioAssignment?>(assignment);
  }

  @override
  Future<AppResult<List<PortfolioAssignment>>> listActiveByOrganization({
    required String organizationId,
    required String companyId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PortfolioAssignment>>> listActiveByUser({
    required String organizationId,
    required String companyId,
    required String userId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PortfolioAssignment>> create(
    PortfolioAssignment assignment,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PortfolioAssignment>> endAssignment({
    required String organizationId,
    required String id,
    required PortfolioAssignmentStatus status,
    required DateTime endedAt,
    required String endedBy,
  }) {
    throw UnimplementedError();
  }
}
