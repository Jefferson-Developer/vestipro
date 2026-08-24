import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

void main() {
  group('ListCustomerPortfolioUseCase', () {
    test(
      'rejects a SALES_REP without active portfolio assignments explicitly',
      () async {
        final customerRepository = _FakeCustomerRepository();
        final useCase = _buildUseCase(
          customerRepository: customerRepository,
          membershipRepository: _FakeMembershipRepository(
            _membership(roleName: 'SALES_REP'),
          ),
          assignmentRepository: _FakePortfolioAssignmentRepository(),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'rep-1',
        );

        expect(result, isA<AppFailure<CustomerPortfolioPageResult>>());
        expect(
          (result as AppFailure<CustomerPortfolioPageResult>).failure.code,
          'customer_portfolio_assignment_required',
        );
        expect(customerRepository.calls, isEmpty);
      },
    );

    test(
      'does not require portfolio assignment reads for ADMIN scope',
      () async {
        final customerRepository = _FakeCustomerRepository();
        final assignmentRepository = _FakePortfolioAssignmentRepository(
          organizationFailure: const ConnectivityFailure('assignments offline'),
        );
        final useCase = _buildUseCase(
          customerRepository: customerRepository,
          membershipRepository: _FakeMembershipRepository(
            _membership(roleName: 'ADMIN', userId: 'admin-1'),
          ),
          assignmentRepository: assignmentRepository,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'admin-1',
        );

        expect(result, isA<AppSuccess<CustomerPortfolioPageResult>>());
        expect(assignmentRepository.organizationListCalls, 0);
        expect(
          customerRepository.calls.single.visibility.mode,
          CustomerVisibilityMode.allOrganization,
        );
        expect(customerRepository.calls.single.activeAssignments, isEmpty);
      },
    );

    test(
      'passes only visible team assignments for SALES_MANAGER scope',
      () async {
        final customerRepository = _FakeCustomerRepository();
        final assignmentRepository = _FakePortfolioAssignmentRepository(
          organizationAssignments: <PortfolioAssignment>[
            _assignment(id: 'assignment-visible', teamId: 'team-managed'),
            _assignment(id: 'assignment-hidden', teamId: 'team-hidden'),
          ],
        );
        final useCase = _buildUseCase(
          customerRepository: customerRepository,
          membershipRepository: _FakeMembershipRepository(
            _membership(roleName: 'SALES_MANAGER', userId: 'manager-1'),
          ),
          teamRepository: _FakeTeamRepository(<Team>[
            _team(id: 'team-managed', managerUserId: 'manager-1'),
            _team(id: 'team-hidden', managerUserId: 'other-manager'),
          ]),
          assignmentRepository: assignmentRepository,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'manager-1',
        );

        expect(result, isA<AppSuccess<CustomerPortfolioPageResult>>());
        final call = customerRepository.calls.single;
        expect(call.visibility.mode, CustomerVisibilityMode.teams);
        expect(call.visibility.teamIds, <String>{'team-managed'});
        expect(
          call.activeAssignments.map((assignment) => assignment.id),
          <String>['assignment-visible'],
        );
      },
    );
  });
}

ListCustomerPortfolioUseCase _buildUseCase({
  required CustomerRepository customerRepository,
  required MembershipRepository membershipRepository,
  TeamRepository? teamRepository,
  PortfolioAssignmentRepository? assignmentRepository,
}) {
  return ListCustomerPortfolioUseCase(
    customerRepository,
    PortfolioVisibilityService(
      membershipRepository,
      teamRepository ?? const _FakeTeamRepository(<Team>[]),
    ),
    assignmentRepository ?? _FakePortfolioAssignmentRepository(),
  );
}

Membership _membership({
  String userId = 'rep-1',
  required String roleName,
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

PortfolioAssignment _assignment({required String id, required String teamId}) {
  final now = DateTime.utc(2026, 1, 1);
  return PortfolioAssignment(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    userId: 'rep-1',
    teamId: teamId,
    scope: PortfolioAssignmentScope.customer('customer-1'),
    status: PortfolioAssignmentStatus.active,
    version: 1,
    createdAt: now,
    createdBy: 'manager-1',
    updatedAt: now,
    updatedBy: 'manager-1',
  );
}

final class _FakeCustomerRepository implements CustomerRepository {
  final List<_CustomerPortfolioCall> calls = <_CustomerPortfolioCall>[];

  @override
  Future<AppResult<CustomerPortfolioPageResult>> listPortfolioPage({
    required CustomerVisibilityFilter visibility,
    required List<PortfolioAssignment> activeAssignments,
    required CustomerPortfolioFilters filters,
    required String searchQuery,
    required int limit,
    String? cursor,
    required DateTime now,
  }) async {
    calls.add(
      _CustomerPortfolioCall(
        visibility: visibility,
        activeAssignments: activeAssignments,
      ),
    );
    return const AppSuccess<CustomerPortfolioPageResult>(
      CustomerPortfolioPageResult(customers: <Customer>[], hasMore: false),
    );
  }

  @override
  Future<AppResult<Customer>> create({required Customer customer}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Customer>> deactivate({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<bool>> existsByDocument({
    required String organizationId,
    required CnpjCpf document,
    String? excludingCustomerId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Customer>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<Customer>> update({
    required Customer customer,
    required Set<CustomerSensitiveField> sensitiveFieldsToAudit,
  }) {
    throw UnimplementedError();
  }
}

final class _CustomerPortfolioCall {
  const _CustomerPortfolioCall({
    required this.visibility,
    required this.activeAssignments,
  });

  final CustomerVisibilityFilter visibility;
  final List<PortfolioAssignment> activeAssignments;
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
  _FakePortfolioAssignmentRepository({
    this.organizationAssignments = const <PortfolioAssignment>[],
    this.organizationFailure,
  });

  final List<PortfolioAssignment> organizationAssignments;
  final Failure? organizationFailure;
  int organizationListCalls = 0;

  @override
  Future<AppResult<List<PortfolioAssignment>>> listActiveByOrganization({
    required String organizationId,
    required String companyId,
  }) async {
    organizationListCalls += 1;
    final failure = organizationFailure;
    if (failure != null) {
      return AppFailure<List<PortfolioAssignment>>(failure);
    }
    return AppSuccess<List<PortfolioAssignment>>(organizationAssignments);
  }

  @override
  Future<AppResult<List<PortfolioAssignment>>> listActiveByUser({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    return const AppSuccess<List<PortfolioAssignment>>(<PortfolioAssignment>[]);
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

  @override
  Future<AppResult<PortfolioAssignment?>> findActiveCustomerAssignment({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) {
    throw UnimplementedError();
  }
}
