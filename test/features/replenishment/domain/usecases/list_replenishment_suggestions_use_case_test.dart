import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/replenishment/replenishment.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeReplenishmentRepository implements ReplenishmentRepository {
  _FakeReplenishmentRepository(this._listResult);

  final AppResult<ReplenishmentSuggestionPage> _listResult;
  int listCallCount = 0;

  @override
  Future<AppResult<ReplenishmentSuggestionPage>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    ReplenishmentSuggestionStatus? status,
    String? warehouseId,
  }) async {
    listCallCount += 1;
    return _listResult;
  }

  @override
  Future<AppResult<ReplenishmentDecisionResult>> decide({
    required String organizationId,
    required String suggestionId,
    required ReplenishmentDecisionAction action,
    int? adjustedQuantity,
    String? note,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  group('ListReplenishmentSuggestionsUseCase', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
    });

    Membership buildMembership(String roleName, {String userId = 'manager-1'}) {
      return Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: userId,
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: userId,
      );
    }

    test(
      'lists through the repository when the caller has report.viewSensitive',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'manager-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
        );
        final repository = _FakeReplenishmentRepository(
          const AppSuccess<ReplenishmentSuggestionPage>(
            ReplenishmentSuggestionPage(
              suggestions: <ReplenishmentSuggestion>[],
              hasMore: false,
            ),
          ),
        );
        final useCase = ListReplenishmentSuggestionsUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          requestedByUserId: 'manager-1',
        );

        expect(result, isA<AppSuccess<ReplenishmentSuggestionPage>>());
        expect(repository.listCallCount, 1);
      },
    );

    test(
      'fails without calling the repository when the caller lacks report.viewSensitive',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'rep-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(
            buildMembership('SALES_REP', userId: 'rep-1'),
          ),
        );
        final repository = _FakeReplenishmentRepository(
          const AppSuccess<ReplenishmentSuggestionPage>(
            ReplenishmentSuggestionPage(
              suggestions: <ReplenishmentSuggestion>[],
              hasMore: false,
            ),
          ),
        );
        final useCase = ListReplenishmentSuggestionsUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          requestedByUserId: 'rep-1',
        );

        expect(result, isA<AppFailure<ReplenishmentSuggestionPage>>());
        expect(
          (result as AppFailure<ReplenishmentSuggestionPage>).failure.code,
          'replenishment_suggestion_view_denied',
        );
        expect(repository.listCallCount, 0);
      },
    );

    test(
      'fails validation without calling the repository for an out-of-range limit',
      () async {
        final repository = _FakeReplenishmentRepository(
          const AppSuccess<ReplenishmentSuggestionPage>(
            ReplenishmentSuggestionPage(
              suggestions: <ReplenishmentSuggestion>[],
              hasMore: false,
            ),
          ),
        );
        final useCase = ListReplenishmentSuggestionsUseCase(
          repository,
          permissionService,
        );

        final result = await useCase(
          organizationId: 'org-1',
          requestedByUserId: 'manager-1',
          limit: 0,
        );

        expect(result, isA<AppFailure<ReplenishmentSuggestionPage>>());
        expect(
          (result as AppFailure<ReplenishmentSuggestionPage>).failure.code,
          'invalid_replenishment_suggestion_list_request',
        );
        expect(repository.listCallCount, 0);
        verifyNever(
          () => membershipRepository.getByUser(
            organizationId: any(named: 'organizationId'),
            userId: any(named: 'userId'),
          ),
        );
      },
    );
  });
}
