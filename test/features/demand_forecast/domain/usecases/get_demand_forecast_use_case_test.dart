import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/demand_forecast/demand_forecast.dart';
import 'package:vestipro/features/organizations/organizations.dart';

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeDemandForecastRepository implements DemandForecastRepository {
  _FakeDemandForecastRepository(this._result);

  final AppResult<DemandForecast?> _result;
  int callCount = 0;

  @override
  Future<AppResult<DemandForecast?>> getLatestForecast({
    required String organizationId,
    required String companyId,
    required DemandForecastScopeType scopeType,
    required String scopeId,
  }) async {
    callCount += 1;
    return _result;
  }
}

DemandForecast _buildForecast() {
  return DemandForecast(
    id: 'company-1_product_product-1_2026-08',
    organizationId: 'org-1',
    companyId: 'company-1',
    scopeType: DemandForecastScopeType.product,
    scopeId: 'product-1',
    scopeLabel: 'Camisa Polo',
    anchorMonthKey: '2026-08',
    status: DemandForecastStatus.forecast,
    observedPeriodsCount: 12,
    model: 'holtLinearTrend',
    modelVersion: 'holt-linear-trend-v1',
    residualStdDev: 2.5,
    history: const <DemandForecastHistoryPoint>[],
    forecastPeriods: const <DemandForecastPeriodProjection>[],
    generatedAt: DateTime.utc(2026, 9, 2),
    updatedAt: DateTime.utc(2026, 9, 2),
    version: 1,
  );
}

void main() {
  group('GetDemandForecastUseCase', () {
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
      'reads through the repository and logs demandForecastViewed when the caller has report.viewSensitive',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'manager-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
        );
        final repository = _FakeDemandForecastRepository(
          AppSuccess<DemandForecast?>(_buildForecast()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GetDemandForecastUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requestedByUserId: 'manager-1',
          scopeType: DemandForecastScopeType.product,
          scopeId: 'product-1',
        );

        expect(result, isA<AppSuccess<DemandForecast?>>());
        expect(repository.callCount, 1);
        expect(
          analytics.loggedEvents.any(
            (event) => event.name == AnalyticsEvents.demandForecastViewed,
          ),
          isTrue,
        );
      },
    );

    test(
      'succeeds with a null forecast (never generated yet) and still logs the view event',
      () async {
        when(
          () => membershipRepository.getByUser(
            organizationId: 'org-1',
            userId: 'manager-1',
          ),
        ).thenAnswer(
          (_) async => AppSuccess<Membership>(buildMembership('SALES_MANAGER')),
        );
        final repository = _FakeDemandForecastRepository(
          const AppSuccess<DemandForecast?>(null),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GetDemandForecastUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requestedByUserId: 'manager-1',
          scopeType: DemandForecastScopeType.product,
          scopeId: 'never-forecasted',
        );

        expect(result, isA<AppSuccess<DemandForecast?>>());
        expect((result as AppSuccess<DemandForecast?>).value, isNull);
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
        final repository = _FakeDemandForecastRepository(
          AppSuccess<DemandForecast?>(_buildForecast()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GetDemandForecastUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requestedByUserId: 'rep-1',
          scopeType: DemandForecastScopeType.product,
          scopeId: 'product-1',
        );

        expect(result, isA<AppFailure<DemandForecast?>>());
        expect(
          (result as AppFailure<DemandForecast?>).failure.code,
          'demand_forecast_view_denied',
        );
        expect(repository.callCount, 0);
        expect(analytics.loggedEvents, isEmpty);
      },
    );

    test(
      'fails validation without calling the repository or membership lookup for a blank scopeId',
      () async {
        final repository = _FakeDemandForecastRepository(
          AppSuccess<DemandForecast?>(_buildForecast()),
        );
        final analytics = FakeAnalyticsService();
        final useCase = GetDemandForecastUseCase(
          repository,
          permissionService,
          analytics,
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          requestedByUserId: 'manager-1',
          scopeType: DemandForecastScopeType.product,
          scopeId: '   ',
        );

        expect(result, isA<AppFailure<DemandForecast?>>());
        expect(
          (result as AppFailure<DemandForecast?>).failure.code,
          'invalid_demand_forecast_request',
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
