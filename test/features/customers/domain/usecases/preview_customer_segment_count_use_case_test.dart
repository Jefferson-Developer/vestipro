import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

void main() {
  group('PreviewCustomerSegmentCountUseCase', () {
    test('counts the customers currently matching the criteria', () async {
      final useCase = _buildUseCase(
        AppSuccess<CustomerPortfolioPageResult>(
          CustomerPortfolioPageResult(
            customers: List<Customer>.generate(
              3,
              (index) => _customer('customer-$index'),
            ),
            hasMore: false,
          ),
        ),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'admin-1',
        criteria: const CustomerSegmentCriteria(
          portfolioFilters: CustomerPortfolioFilters(
            potentials: <String>{'Alto'},
          ),
        ),
      );

      expect(result, isA<AppSuccess<CustomerSegmentPreview>>());
      final preview = (result as AppSuccess<CustomerSegmentPreview>).value;
      expect(preview.matchedCount, 3);
      expect(preview.isAtLeastCount, isFalse);
    });

    test('marks the count as a floor when the carteira has more matches than '
        'the preview cap', () async {
      final customers = List<Customer>.generate(
        PreviewCustomerSegmentCountUseCase.previewLimit,
        (index) => _customer('customer-$index'),
      );
      final useCase = _buildUseCase(
        AppSuccess<CustomerPortfolioPageResult>(
          CustomerPortfolioPageResult(customers: customers, hasMore: true),
        ),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'admin-1',
        criteria: CustomerSegmentCriteria.empty,
      );

      final preview = (result as AppSuccess<CustomerSegmentPreview>).value;
      expect(
        preview.matchedCount,
        PreviewCustomerSegmentCountUseCase.previewLimit,
      );
      expect(preview.isAtLeastCount, isTrue);
    });

    test('propagates a carteira listing failure', () async {
      final useCase = _buildUseCase(
        const AppFailure<CustomerPortfolioPageResult>(
          ConnectivityFailure('Offline.'),
        ),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'admin-1',
        criteria: CustomerSegmentCriteria.empty,
      );

      expect(result, isA<AppFailure<CustomerSegmentPreview>>());
    });
  });
}

PreviewCustomerSegmentCountUseCase _buildUseCase(
  AppResult<CustomerPortfolioPageResult> customerRepositoryResult,
) {
  final listCustomerPortfolio = ListCustomerPortfolioUseCase(
    _FakeCustomerRepository(customerRepositoryResult),
    PortfolioVisibilityService(
      _FakeMembershipRepository(
        Membership(
          id: 'admin-1',
          organizationId: 'org-1',
          userId: 'admin-1',
          roleId: 'ADMIN',
          roleName: 'ADMIN',
          status: MembershipStatus.active,
          version: 1,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'owner-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'owner-1',
        ),
      ),
      const _FakeTeamRepository(<Team>[]),
    ),
    _FakePortfolioAssignmentRepository(),
  );
  return PreviewCustomerSegmentCountUseCase(listCustomerPortfolio);
}

Customer _customer(String id) {
  return Customer(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    type: CustomerType.legalEntity,
    document: CnpjCpf.parse('04.252.011/0001-10'),
    legalName: id,
    status: CustomerStatus.active,
    registeredAt: DateTime.utc(2026, 1, 1),
    createdAt: DateTime.utc(2026, 1, 1),
    createdBy: 'admin-1',
    updatedAt: DateTime.utc(2026, 1, 1),
    updatedBy: 'admin-1',
    version: 1,
    syncStatus: CustomerSyncStatus.pending,
  );
}

final class _FakeCustomerRepository implements CustomerRepository {
  _FakeCustomerRepository(this._result);

  final AppResult<CustomerPortfolioPageResult> _result;

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
    return _result;
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
  @override
  Future<AppResult<List<PortfolioAssignment>>> listActiveByOrganization({
    required String organizationId,
    required String companyId,
  }) async {
    return const AppSuccess<List<PortfolioAssignment>>(<PortfolioAssignment>[]);
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
