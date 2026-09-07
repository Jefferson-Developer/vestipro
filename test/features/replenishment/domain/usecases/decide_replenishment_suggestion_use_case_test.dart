import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/replenishment/replenishment.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeReplenishmentRepository implements ReplenishmentRepository {
  _FakeReplenishmentRepository(this._decideResult);

  final AppResult<ReplenishmentDecisionResult> _decideResult;
  int decideCallCount = 0;
  ReplenishmentDecisionAction? lastAction;
  int? lastAdjustedQuantity;

  @override
  Future<AppResult<ReplenishmentSuggestionPage>> listPageByOrganization({
    required String organizationId,
    int limit = 25,
    DateTime? before,
    ReplenishmentSuggestionStatus? status,
    String? warehouseId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<ReplenishmentDecisionResult>> decide({
    required String organizationId,
    required String suggestionId,
    required ReplenishmentDecisionAction action,
    int? adjustedQuantity,
    String? note,
  }) async {
    decideCallCount += 1;
    lastAction = action;
    lastAdjustedQuantity = adjustedQuantity;
    return _decideResult;
  }
}

void main() {
  group('DecideReplenishmentSuggestionUseCase', () {
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
      'accepts through the repository and logs replenishmentSuggestionDecided',
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
          const AppSuccess<ReplenishmentDecisionResult>(
            ReplenishmentDecisionResult(
              suggestionId: 'suggestion-1',
              status: ReplenishmentSuggestionStatus.accepted,
              finalQuantity: 30,
              draftOrderId: 'draft-1',
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = DecideReplenishmentSuggestionUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          suggestionId: 'suggestion-1',
          userId: 'manager-1',
          action: ReplenishmentDecisionAction.accept,
        );

        expect(result, isA<AppSuccess<ReplenishmentDecisionResult>>());
        expect(repository.lastAction, ReplenishmentDecisionAction.accept);
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name == AnalyticsEvents.replenishmentSuggestionDecided,
          ),
          isTrue,
        );
      },
    );

    test('adjusts with the manually chosen quantity', () async {
      when(
        () => membershipRepository.getByUser(
          organizationId: 'org-1',
          userId: 'manager-1',
        ),
      ).thenAnswer(
        (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
      );
      final repository = _FakeReplenishmentRepository(
        const AppSuccess<ReplenishmentDecisionResult>(
          ReplenishmentDecisionResult(
            suggestionId: 'suggestion-1',
            status: ReplenishmentSuggestionStatus.adjusted,
            finalQuantity: 50,
            draftOrderId: 'draft-1',
          ),
        ),
      );
      final analytics = FakeAnalyticsService();
      final useCase = DecideReplenishmentSuggestionUseCase(
        repository,
        permissionService,
        analytics,
      );

      final result = await useCase(
        organizationId: 'org-1',
        suggestionId: 'suggestion-1',
        userId: 'manager-1',
        action: ReplenishmentDecisionAction.adjust,
        adjustedQuantity: 50,
      );

      expect(result, isA<AppSuccess<ReplenishmentDecisionResult>>());
      expect(repository.lastAdjustedQuantity, 50);
    });

    test(
      'fails without calling the repository when adjusting without a quantity',
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
          const AppSuccess<ReplenishmentDecisionResult>(
            ReplenishmentDecisionResult(
              suggestionId: 'suggestion-1',
              status: ReplenishmentSuggestionStatus.adjusted,
              finalQuantity: 50,
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = DecideReplenishmentSuggestionUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          suggestionId: 'suggestion-1',
          userId: 'manager-1',
          action: ReplenishmentDecisionAction.adjust,
        );

        expect(result, isA<AppFailure<ReplenishmentDecisionResult>>());
        expect(
          (result as AppFailure<ReplenishmentDecisionResult>).failure.code,
          'invalid_replenishment_suggestion_decision_payload',
        );
        expect(repository.decideCallCount, 0);
        expect(analytics.loggedEvents, isEmpty);
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
          const AppSuccess<ReplenishmentDecisionResult>(
            ReplenishmentDecisionResult(
              suggestionId: 'suggestion-1',
              status: ReplenishmentSuggestionStatus.accepted,
              finalQuantity: 30,
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = DecideReplenishmentSuggestionUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          suggestionId: 'suggestion-1',
          userId: 'rep-1',
          action: ReplenishmentDecisionAction.accept,
        );

        expect(result, isA<AppFailure<ReplenishmentDecisionResult>>());
        expect(
          (result as AppFailure<ReplenishmentDecisionResult>).failure.code,
          'replenishment_suggestion_decide_denied',
        );
        expect(repository.decideCallCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'propagates a server-side decision failure without logging analytics',
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
          const AppFailure<ReplenishmentDecisionResult>(
            ValidationFailure(
              'Esta sugestão já foi decidida e não pode ser alterada.',
              code: 'failed-precondition',
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = DecideReplenishmentSuggestionUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          suggestionId: 'suggestion-1',
          userId: 'manager-1',
          action: ReplenishmentDecisionAction.discard,
        );

        expect(result, isA<AppFailure<ReplenishmentDecisionResult>>());
        expect(analytics.loggedEvents, isEmpty);
      },
    );
  });
}
