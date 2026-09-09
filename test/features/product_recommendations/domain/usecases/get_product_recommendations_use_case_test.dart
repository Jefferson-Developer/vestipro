import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/product_recommendations/product_recommendations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeProductRecommendationRepository
    implements ProductRecommendationRepository {
  _FakeProductRecommendationRepository(this._result);

  final AppResult<ProductRecommendation?> _result;
  int callCount = 0;

  @override
  Future<AppResult<ProductRecommendation?>> getRecommendation({
    required String organizationId,
    required String companyId,
    required ProductRecommendationScopeType scopeType,
    required String scopeId,
  }) async {
    callCount += 1;
    return _result;
  }
}

ProductRecommendation _buildRecommendation({
  ProductRecommendationScopeType scopeType =
      ProductRecommendationScopeType.product,
  String scopeId = 'product-1',
  bool fallbackApplied = false,
  bool insufficientData = false,
}) {
  return ProductRecommendation(
    id: 'company-1_${scopeType.code}_$scopeId',
    organizationId: 'org-1',
    companyId: 'company-1',
    scopeType: scopeType,
    scopeId: scopeId,
    items: insufficientData
        ? const <ProductRecommendationItem>[]
        : <ProductRecommendationItem>[
            const ProductRecommendationItem(
              productId: 'product-2',
              productName: 'Calça Jeans',
              score: 0.5,
              reasonCode: ProductRecommendationReasonCode.boughtTogether,
              reasonLabel: 'Clientes que compraram X também compraram Y.',
              relatedProductId: 'product-1',
              relatedProductName: 'Camiseta Básica',
            ),
          ],
    fallbackApplied: fallbackApplied,
    insufficientData: insufficientData,
    signalsUsed: insufficientData
        ? const <String>[]
        : const <String>['order_submitted_item_co_occurrence'],
    lookbackDays: 180,
    model: 'itemCoOccurrenceV1',
    modelVersion: 'co-occurrence-v1',
    generatedAt: DateTime.utc(2026, 9, 8),
    version: 1,
  );
}

void main() {
  group('GetProductRecommendationsUseCase', () {
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;

    setUp(() {
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
    });

    Membership buildMembership(String roleName, {String userId = 'rep-1'}) {
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
      'reads through the repository without a membership lookup for product scope',
      () async {
        final repository = _FakeProductRecommendationRepository(
          AppSuccess<ProductRecommendation?>(_buildRecommendation()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GetProductRecommendationsUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requestedByUserId: 'rep-1',
          scopeType: ProductRecommendationScopeType.product,
          scopeId: 'product-1',
        );

        expect(result, isA<AppSuccess<ProductRecommendation?>>());
        expect(repository.callCount, 1);
        verifyNever(
          () => membershipRepository.getByUser(
            organizationId: any(named: 'organizationId'),
            userId: any(named: 'userId'),
          ),
        );
        expect(
          analytics.loggedEvents.any(
            (event) =>
                event.name == AnalyticsEvents.productRecommendationsViewed,
          ),
          isTrue,
        );
      },
    );

    test(
      'reads through the repository when the caller has customerView, for customer scope',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'rep-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_REP')),
        );
        final repository = _FakeProductRecommendationRepository(
          AppSuccess<ProductRecommendation?>(
            _buildRecommendation(
              scopeType: ProductRecommendationScopeType.customer,
              scopeId: 'customer-1',
            ),
          ),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GetProductRecommendationsUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requestedByUserId: 'rep-1',
          scopeType: ProductRecommendationScopeType.customer,
          scopeId: 'customer-1',
        );

        expect(result, isA<AppSuccess<ProductRecommendation?>>());
        expect(repository.callCount, 1);
      },
    );

    test(
      'fails without calling the repository when the caller lacks customerView for customer scope',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'rep-1',
          ),
        ).thenAnswer(
          (_) async =>
              const AppFailure<Membership>(NotFoundFailure('not found')),
        );
        final repository = _FakeProductRecommendationRepository(
          AppSuccess<ProductRecommendation?>(_buildRecommendation()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GetProductRecommendationsUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requestedByUserId: 'rep-1',
          scopeType: ProductRecommendationScopeType.customer,
          scopeId: 'customer-1',
        );

        expect(result, isA<AppFailure<ProductRecommendation?>>());
        expect(
          (result as AppFailure<ProductRecommendation?>).failure.code,
          'product_recommendation_view_denied',
        );
        expect(repository.callCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'succeeds with a null recommendation (never generated yet) and still logs the view event',
      () async {
        final repository = _FakeProductRecommendationRepository(
          const AppSuccess<ProductRecommendation?>(null),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GetProductRecommendationsUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requestedByUserId: 'rep-1',
          scopeType: ProductRecommendationScopeType.segment,
          scopeId: 'company-best-sellers',
        );

        expect(result, isA<AppSuccess<ProductRecommendation?>>());
        expect((result as AppSuccess<ProductRecommendation?>).value, isNull);
      },
    );

    test(
      'fails validation without calling the repository or membership lookup for a blank scopeId',
      () async {
        final repository = _FakeProductRecommendationRepository(
          AppSuccess<ProductRecommendation?>(_buildRecommendation()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GetProductRecommendationsUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requestedByUserId: 'rep-1',
          scopeType: ProductRecommendationScopeType.product,
          scopeId: '   ',
        );

        expect(result, isA<AppFailure<ProductRecommendation?>>());
        expect(
          (result as AppFailure<ProductRecommendation?>).failure.code,
          'invalid_product_recommendation_request',
        );
        expect(repository.callCount, 0);
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
