import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/offline/offline.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

void main() {
  group('LoadInitialCustomerOfflineDataUseCase', () {
    test('rejects an invalid payload before touching any repository', () async {
      final customerRepository = _FakePaginatedCustomerRepository(<Customer>[]);
      final localStore = _FakeCustomerLocalStoreRepository();
      final useCase = _buildUseCase(
        customerRepository: customerRepository,
        localStore: localStore,
        membershipRepository: _FakeMembershipRepository(
          _membership(roleName: 'ADMIN', userId: 'admin-1'),
        ),
      );

      final result = await useCase(
        organizationId: '',
        companyId: 'company-1',
        userId: 'admin-1',
      );

      expect(result, isA<AppFailure<CustomerOfflineLoadSummary>>());
      expect(customerRepository.calls, isEmpty);
      expect(localStore.replaceCalls, isEmpty);
    });

    test('downloads the whole organization for ADMIN across multiple pages '
        'without requiring portfolio assignments', () async {
      final customers = List<Customer>.generate(5, _customer);
      final customerRepository = _FakePaginatedCustomerRepository(customers);
      final localStore = _FakeCustomerLocalStoreRepository();
      final assignmentRepository = _FakePortfolioAssignmentRepository(
        organizationFailure: const ConnectivityFailure('assignments offline'),
      );
      final useCase = _buildUseCase(
        customerRepository: customerRepository,
        localStore: localStore,
        membershipRepository: _FakeMembershipRepository(
          _membership(roleName: 'ADMIN', userId: 'admin-1'),
        ),
        assignmentRepository: assignmentRepository,
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'admin-1',
        pageSize: 2,
      );

      expect(result, isA<AppSuccess<CustomerOfflineLoadSummary>>());
      final summary = (result as AppSuccess<CustomerOfflineLoadSummary>).value;
      expect(summary.downloadedCount, 5);
      expect(summary.truncated, isFalse);
      expect(assignmentRepository.organizationListCalls, 0);
      expect(
        customerRepository.calls.every(
          (call) =>
              call.visibility.mode == CustomerVisibilityMode.allOrganization,
        ),
        isTrue,
      );
      // Paginated in 3 round trips of page size 2 (2 + 2 + 1).
      expect(customerRepository.calls, hasLength(3));
      expect(localStore.replaceCalls, hasLength(1));
      expect(
        localStore.replaceCalls.single.customers.map((c) => c.id).toSet(),
        customers.map((c) => c.id).toSet(),
      );
    });

    test(
      'forwards only the assignments of teams a SALES_MANAGER can see',
      () async {
        final customers = List<Customer>.generate(2, _customer);
        final customerRepository = _FakePaginatedCustomerRepository(customers);
        final localStore = _FakeCustomerLocalStoreRepository();
        final assignmentRepository = _FakePortfolioAssignmentRepository(
          organizationAssignments: <PortfolioAssignment>[
            _assignment(id: 'assignment-visible', teamId: 'team-managed'),
            _assignment(id: 'assignment-hidden', teamId: 'team-hidden'),
          ],
        );
        final useCase = _buildUseCase(
          customerRepository: customerRepository,
          localStore: localStore,
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

        expect(result, isA<AppSuccess<CustomerOfflineLoadSummary>>());
        final call = customerRepository.calls.first;
        expect(call.visibility.mode, CustomerVisibilityMode.teams);
        expect(call.visibility.teamIds, <String>{'team-managed'});
        expect(
          call.activeAssignments.map((assignment) => assignment.id),
          <String>['assignment-visible'],
        );
      },
    );

    test('clears the local store instead of downloading when a SALES_REP has '
        'no active portfolio assignment', () async {
      final customerRepository = _FakePaginatedCustomerRepository(
        List<Customer>.generate(3, _customer),
      );
      final localStore = _FakeCustomerLocalStoreRepository();
      final useCase = _buildUseCase(
        customerRepository: customerRepository,
        localStore: localStore,
        membershipRepository: _FakeMembershipRepository(
          _membership(roleName: 'SALES_REP', userId: 'rep-1'),
        ),
        assignmentRepository: _FakePortfolioAssignmentRepository(),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
      );

      expect(result, isA<AppSuccess<CustomerOfflineLoadSummary>>());
      final summary = (result as AppSuccess<CustomerOfflineLoadSummary>).value;
      expect(summary.downloadedCount, 0);
      expect(customerRepository.calls, isEmpty);
      expect(localStore.replaceCalls, hasLength(1));
      expect(localStore.replaceCalls.single.customers, isEmpty);
    });

    test(
      'clears the local store when the membership has no visible portfolio',
      () async {
        final customerRepository = _FakePaginatedCustomerRepository(
          List<Customer>.generate(2, _customer),
        );
        final localStore = _FakeCustomerLocalStoreRepository();
        final useCase = _buildUseCase(
          customerRepository: customerRepository,
          localStore: localStore,
          membershipRepository: _FakeMembershipRepository(
            _membership(roleName: 'FINANCE', userId: 'finance-1'),
          ),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'finance-1',
        );

        expect(result, isA<AppSuccess<CustomerOfflineLoadSummary>>());
        expect(customerRepository.calls, isEmpty);
        expect(localStore.replaceCalls.single.customers, isEmpty);
      },
    );

    test('caps the number of customers downloaded at maxCustomers and reports '
        'truncation', () async {
      final customers = List<Customer>.generate(10, _customer);
      final customerRepository = _FakePaginatedCustomerRepository(customers);
      final localStore = _FakeCustomerLocalStoreRepository();
      final useCase = _buildUseCase(
        customerRepository: customerRepository,
        localStore: localStore,
        membershipRepository: _FakeMembershipRepository(
          _membership(roleName: 'OWNER', userId: 'owner-1'),
        ),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        pageSize: 3,
        maxCustomers: 4,
      );

      expect(result, isA<AppSuccess<CustomerOfflineLoadSummary>>());
      final summary = (result as AppSuccess<CustomerOfflineLoadSummary>).value;
      expect(summary.downloadedCount, 4);
      expect(summary.truncated, isTrue);
      expect(localStore.replaceCalls.single.customers, hasLength(4));
    });

    test('a cancellation observed between pages (TASK-107) never replaces the '
        'local store and reports downloadedCount 0', () async {
      final customers = List<Customer>.generate(6, _customer);
      final customerRepository = _FakePaginatedCustomerRepository(customers);
      final localStore = _FakeCustomerLocalStoreRepository();
      final useCase = _buildUseCase(
        customerRepository: customerRepository,
        localStore: localStore,
        membershipRepository: _FakeMembershipRepository(
          _membership(roleName: 'OWNER', userId: 'owner-1'),
        ),
      );
      final token = OfflinePackageCancellationToken();
      final pagesFetched = <int>[];

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        pageSize: 2,
        cancellationToken: token,
        onPageFetched: (count) {
          pagesFetched.add(count);
          // Cancel right after the first page finishes fetching.
          if (count >= 2) {
            token.cancel();
          }
        },
      );

      expect(result, isA<AppSuccess<CustomerOfflineLoadSummary>>());
      final summary = (result as AppSuccess<CustomerOfflineLoadSummary>).value;
      expect(summary.cancelled, isTrue);
      expect(summary.downloadedCount, 0);
      expect(pagesFetched, <int>[2]);
      // Only the first page was fetched; the second/third never ran.
      expect(customerRepository.calls, hasLength(1));
      expect(localStore.replaceCalls, isEmpty);
    });
  });
}

LoadInitialCustomerOfflineDataUseCase _buildUseCase({
  required CustomerRepository customerRepository,
  required CustomerLocalStoreRepository localStore,
  required MembershipRepository membershipRepository,
  TeamRepository? teamRepository,
  PortfolioAssignmentRepository? assignmentRepository,
}) {
  return LoadInitialCustomerOfflineDataUseCase(
    customerRepository,
    PortfolioVisibilityService(
      membershipRepository,
      teamRepository ?? const _FakeTeamRepository(<Team>[]),
    ),
    assignmentRepository ?? _FakePortfolioAssignmentRepository(),
    localStore,
  );
}

Customer _customer(int index) {
  final now = DateTime.utc(2026, 1, 1);
  return Customer(
    id: 'customer-$index',
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: 'Customer $index',
    status: CustomerStatus.active,
    responsibleSellerId: 'rep-1',
    registeredAt: now,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
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

/// Fake `CustomerRepository` that paginates a fixed in-memory list the same
/// way a real backend would: cursor is the last returned id, `hasMore` is
/// true while there is a next page. This lets pagination/cap behavior be
/// tested without depending on `SharedPreferencesCustomerRepository`.
final class _FakePaginatedCustomerRepository implements CustomerRepository {
  _FakePaginatedCustomerRepository(this.backing);

  final List<Customer> backing;
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
        cursor: cursor,
        limit: limit,
      ),
    );

    final startIndex = cursor == null
        ? 0
        : backing.indexWhere((customer) => customer.id == cursor) + 1;
    final page = backing.skip(startIndex).take(limit).toList(growable: false);
    final hasMore = startIndex + page.length < backing.length;

    return AppSuccess<CustomerPortfolioPageResult>(
      CustomerPortfolioPageResult(
        customers: page,
        hasMore: hasMore,
        nextCursor: page.isEmpty ? null : page.last.id,
      ),
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
    required this.cursor,
    required this.limit,
  });

  final CustomerVisibilityFilter visibility;
  final List<PortfolioAssignment> activeAssignments;
  final String? cursor;
  final int limit;
}

final class _FakeCustomerLocalStoreRepository
    implements CustomerLocalStoreRepository {
  final List<_ReplaceCall> replaceCalls = <_ReplaceCall>[];

  @override
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required List<Customer> customers,
  }) async {
    replaceCalls.add(
      _ReplaceCall(
        organizationId: organizationId,
        companyId: companyId,
        customers: customers,
      ),
    );
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<List<Customer>>> getAll({
    required String organizationId,
    required String companyId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<int>> count({
    required String organizationId,
    required String companyId,
  }) {
    throw UnimplementedError();
  }
}

final class _ReplaceCall {
  const _ReplaceCall({
    required this.organizationId,
    required this.companyId,
    required this.customers,
  });

  final String organizationId;
  final String companyId;
  final List<Customer> customers;
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
