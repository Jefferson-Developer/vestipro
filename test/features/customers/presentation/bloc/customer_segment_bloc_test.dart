import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

void main() {
  group('CustomerSegmentBloc', () {
    final now = DateTime.utc(2026, 8, 24);

    CustomerSegmentBloc buildBloc(
      _InMemoryCustomerSegmentRepository repository,
    ) {
      final listCustomerPortfolio = ListCustomerPortfolioUseCase(
        _NoOpCustomerRepository(),
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
              createdAt: now,
              createdBy: 'owner-1',
              updatedAt: now,
              updatedBy: 'owner-1',
            ),
          ),
          const _FakeTeamRepository(<Team>[]),
        ),
        _NoOpPortfolioAssignmentRepository(),
      );
      return CustomerSegmentBloc(
        listCustomerSegments: ListCustomerSegmentsUseCase(repository),
        createCustomerSegment: CreateCustomerSegmentUseCase(repository),
        deleteCustomerSegment: DeleteCustomerSegmentUseCase(repository),
        previewCustomerSegmentCount: PreviewCustomerSegmentCountUseCase(
          listCustomerPortfolio,
        ),
      );
    }

    blocTest<CustomerSegmentBloc, CustomerSegmentState>(
      'loads only segments visible to the requesting user',
      build: () {
        final repository = _InMemoryCustomerSegmentRepository()
          ..seed(
            CustomerSegment(
              id: 'mine',
              organizationId: 'org-1',
              name: 'Meu segmento',
              criteria: CustomerSegmentCriteria.empty,
              visibility: CustomerSegmentVisibility.private,
              createdBy: 'admin-1',
              createdAt: now,
              updatedAt: now,
              updatedBy: 'admin-1',
            ),
          )
          ..seed(
            CustomerSegment(
              id: 'other-private',
              organizationId: 'org-1',
              name: 'Privado de outro',
              criteria: CustomerSegmentCriteria.empty,
              visibility: CustomerSegmentVisibility.private,
              createdBy: 'rep-2',
              createdAt: now,
              updatedAt: now,
              updatedBy: 'rep-2',
            ),
          );
        return buildBloc(repository);
      },
      act: (bloc) => bloc.add(
        const CustomerSegmentsStarted(
          organizationId: 'org-1',
          companyId: 'company-1',
          userId: 'admin-1',
        ),
      ),
      expect: () => <Object>[
        isA<CustomerSegmentState>().having(
          (state) => state.listStatus,
          'listStatus',
          CustomerSegmentListStatus.loading,
        ),
        isA<CustomerSegmentState>()
            .having(
              (state) => state.listStatus,
              'listStatus',
              CustomerSegmentListStatus.ready,
            )
            .having(
              (state) => state.segments.map((segment) => segment.id),
              'segment ids',
              <String>['mine'],
            ),
      ],
    );

    blocTest<CustomerSegmentBloc, CustomerSegmentState>(
      'saves a new segment and refreshes the visible list',
      build: () => buildBloc(_InMemoryCustomerSegmentRepository()),
      seed: () => const CustomerSegmentState(
        listStatus: CustomerSegmentListStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'admin-1',
      ),
      act: (bloc) => bloc.add(
        const CustomerSegmentSaveRequested(
          name: 'Alto potencial SC',
          visibility: CustomerSegmentVisibility.shared,
          criteria: CustomerSegmentCriteria(
            portfolioFilters: CustomerPortfolioFilters(
              stateCodes: <String>{'SC'},
            ),
          ),
        ),
      ),
      expect: () => <Object>[
        isA<CustomerSegmentState>().having(
          (state) => state.saveStatus,
          'saveStatus',
          CustomerSegmentSaveStatus.saving,
        ),
        isA<CustomerSegmentState>()
            .having(
              (state) => state.saveStatus,
              'saveStatus',
              CustomerSegmentSaveStatus.success,
            )
            .having(
              (state) => state.segments.single.name,
              'saved segment name',
              'Alto potencial SC',
            ),
      ],
    );

    blocTest<CustomerSegmentBloc, CustomerSegmentState>(
      'removes a deleted segment from state',
      build: () => buildBloc(_InMemoryCustomerSegmentRepository()),
      seed: () => CustomerSegmentState(
        listStatus: CustomerSegmentListStatus.ready,
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'admin-1',
        segments: <CustomerSegment>[
          CustomerSegment(
            id: 'segment-1',
            organizationId: 'org-1',
            name: 'Segmento',
            criteria: CustomerSegmentCriteria.empty,
            visibility: CustomerSegmentVisibility.private,
            createdBy: 'admin-1',
            createdAt: now,
            updatedAt: now,
            updatedBy: 'admin-1',
          ),
        ],
      ),
      act: (bloc) => bloc.add(
        CustomerSegmentDeleteRequested(
          CustomerSegment(
            id: 'segment-1',
            organizationId: 'org-1',
            name: 'Segmento',
            criteria: CustomerSegmentCriteria.empty,
            visibility: CustomerSegmentVisibility.private,
            createdBy: 'admin-1',
            createdAt: now,
            updatedAt: now,
            updatedBy: 'admin-1',
          ),
        ),
      ),
      expect: () => <Object>[
        isA<CustomerSegmentState>().having(
          (state) => state.segments,
          'segments',
          isEmpty,
        ),
      ],
    );
  });
}

final class _InMemoryCustomerSegmentRepository
    implements CustomerSegmentRepository {
  final List<CustomerSegment> _segments = <CustomerSegment>[];

  void seed(CustomerSegment segment) => _segments.add(segment);

  @override
  Future<AppResult<CustomerSegment>> create(CustomerSegment segment) async {
    _segments.add(segment);
    return AppSuccess<CustomerSegment>(segment);
  }

  @override
  Future<AppResult<void>> delete({
    required String organizationId,
    required String id,
  }) async {
    _segments.removeWhere(
      (segment) => segment.organizationId == organizationId && segment.id == id,
    );
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<List<CustomerSegment>>> listByOrganization(
    String organizationId,
  ) async {
    return AppSuccess<List<CustomerSegment>>(
      _segments
          .where((segment) => segment.organizationId == organizationId)
          .toList(growable: false),
    );
  }
}

final class _NoOpCustomerRepository implements CustomerRepository {
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

final class _NoOpPortfolioAssignmentRepository
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
