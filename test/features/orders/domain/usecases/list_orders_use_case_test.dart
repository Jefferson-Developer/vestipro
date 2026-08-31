import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/orders/orders.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/users/users.dart';

class _MockOrderListRepository extends Mock implements OrderListRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _MockTeamRepository extends Mock implements TeamRepository {}

void main() {
  group('ListOrdersUseCase', () {
    late _MockOrderListRepository orderListRepository;
    late _MockMembershipRepository membershipRepository;
    late _MockTeamRepository teamRepository;
    late PermissionService permissionService;
    late OrderVisibilityService visibilityService;
    late ListOrdersUseCase useCase;

    setUpAll(() {
      registerFallbackValue(OrderListFilters.empty);
    });

    setUp(() {
      orderListRepository = _MockOrderListRepository();
      membershipRepository = _MockMembershipRepository();
      teamRepository = _MockTeamRepository();
      permissionService = PermissionService(membershipRepository);
      visibilityService = OrderVisibilityService(
        PortfolioVisibilityService(membershipRepository, teamRepository),
        teamRepository,
      );
      useCase = ListOrdersUseCase(
        orderListRepository,
        visibilityService,
        permissionService,
      );
      when(
        () => orderListRepository.listPageByCompany(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          limit: any(named: 'limit'),
          before: any(named: 'before'),
          filters: any(named: 'filters'),
        ),
      ).thenAnswer(
        (_) async => const AppSuccess<OrderListPageResult>(
          OrderListPageResult(orders: <Order>[], hasMore: false),
        ),
      );
    });

    Membership buildMembership(
      String userId,
      String roleName, {
      List<String> teamIds = const <String>[],
    }) {
      return Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
        roleId: roleName,
        roleName: roleName,
        teamIds: teamIds,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: userId,
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: userId,
      );
    }

    test('SALES_REP is always restricted to their own orders, even when '
        'asking for another seller', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'rep-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('rep-1', 'SALES_REP')),
      );

      await useCase.call(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'rep-1',
        filters: const OrderListFilters(sellerIds: <String>{'rep-2'}),
      );

      final captured = verify(
        () => orderListRepository.listPageByCompany(
          organizationId: 'org-1',
          companyId: 'company-1',
          limit: any(named: 'limit'),
          before: any(named: 'before'),
          filters: captureAny(named: 'filters'),
        ),
      ).captured;
      final filters = captured.single as OrderListFilters;
      expect(filters.sellerIds, <String>{'rep-1'});
    });

    test('SALES_MANAGER sees only the sellers under their own teams, '
        'narrowing an out-of-scope pick to an empty result without calling '
        'the repository', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(
          buildMembership('manager-1', 'SALES_MANAGER', teamIds: ['team-a']),
        ),
      );
      when(() => teamRepository.listByOrganization('org-1')).thenAnswer(
        (_) async => AppSuccess<List<Team>>(<Team>[
          Team(
            id: 'team-a',
            organizationId: 'org-1',
            name: 'Equipe A',
            managerUserId: 'manager-1',
            memberIds: const <String>['rep-1'],
            version: 1,
            createdAt: DateTime.utc(2026, 1, 1),
            createdBy: 'owner-1',
            updatedAt: DateTime.utc(2026, 1, 1),
            updatedBy: 'owner-1',
          ),
        ]),
      );

      // Picking a seller outside their own team narrows to "nobody" instead
      // of falling through to an unfiltered, organization-wide query.
      final deniedResult = await useCase.call(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'manager-1',
        filters: const OrderListFilters(sellerIds: <String>{'rep-2'}),
      );
      expect(
        (deniedResult as AppSuccess<OrderListPageResult>).value.orders,
        isEmpty,
      );
      verifyNever(
        () => orderListRepository.listPageByCompany(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          limit: any(named: 'limit'),
          before: any(named: 'before'),
          filters: any(named: 'filters'),
        ),
      );

      // No explicit pick resolves to every seller under the manager's teams.
      await useCase.call(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'manager-1',
      );
      final captured = verify(
        () => orderListRepository.listPageByCompany(
          organizationId: 'org-1',
          companyId: 'company-1',
          limit: any(named: 'limit'),
          before: any(named: 'before'),
          filters: captureAny(named: 'filters'),
        ),
      ).captured;
      final filters = captured.single as OrderListFilters;
      expect(filters.sellerIds, <String>{'rep-1'});
    });

    test('OWNER sees every seller of the company by default and an explicit '
        'pick is passed through unrestricted', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'owner-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('owner-1', 'OWNER')),
      );

      await useCase.call(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'owner-1',
        filters: const OrderListFilters(sellerIds: <String>{'rep-9'}),
      );

      final captured = verify(
        () => orderListRepository.listPageByCompany(
          organizationId: 'org-1',
          companyId: 'company-1',
          limit: any(named: 'limit'),
          before: any(named: 'before'),
          filters: captureAny(named: 'filters'),
        ),
      ).captured;
      final filters = captured.single as OrderListFilters;
      expect(filters.sellerIds, <String>{'rep-9'});
    });

    test('a role without order.view (e.g. FINANCE) is denied without ever '
        'reaching the repository', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'finance-1',
        ),
      ).thenAnswer(
        (_) async =>
            AppSuccess<Membership>(buildMembership('finance-1', 'FINANCE')),
      );

      final result = await useCase.call(
        organizationId: 'org-1',
        companyId: 'company-1',
        userId: 'finance-1',
      );

      expect(result, isA<AppFailure<OrderListPageResult>>());
      expect(
        (result as AppFailure<OrderListPageResult>).failure,
        isA<PermissionFailure>(),
      );
      verifyNever(
        () => orderListRepository.listPageByCompany(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          limit: any(named: 'limit'),
          before: any(named: 'before'),
          filters: any(named: 'filters'),
        ),
      );
    });

    test('returns a ValidationFailure without checking permissions when '
        'required fields are blank', () async {
      final result = await useCase.call(
        organizationId: '',
        companyId: '',
        userId: '',
      );

      expect(result, isA<AppFailure<OrderListPageResult>>());
      expect(
        (result as AppFailure<OrderListPageResult>).failure,
        isA<ValidationFailure>(),
      );
      verifyNever(
        () => membershipRepository.getByUser(
          organizationId: any(named: 'organizationId'),
          userId: any(named: 'userId'),
        ),
      );
    });
  });
}
