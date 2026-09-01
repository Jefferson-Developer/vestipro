import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';

class _MockTargetRepository extends Mock implements TargetRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

void main() {
  group('CreateTargetUseCase', () {
    late _MockTargetRepository repository;
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;
    late FakeAnalyticsService analytics;
    late CreateTargetUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildFallbackTarget());
      registerFallbackValue(TargetDimensionType.salesRep);
      registerFallbackValue(TargetMetricType.revenue);
    });

    setUp(() {
      repository = _MockTargetRepository();
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
      analytics = FakeAnalyticsService();
      useCase = CreateTargetUseCase(repository, permissionService, analytics);
      when(() => repository.create(target: any(named: 'target'))).thenAnswer((
        invocation,
      ) async {
        return AppSuccess<Target>(invocation.namedArguments[#target] as Target);
      });
      when(
        () => repository.listByDimension(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          dimensionType: any(named: 'dimensionType'),
          dimensionId: any(named: 'dimensionId'),
          metricType: any(named: 'metricType'),
        ),
      ).thenAnswer((_) async => const AppSuccess<List<Target>>(<Target>[]));
      _stubMembership(membershipRepository, 'manager-1', 'SALES_MANAGER');
    });

    Future<AppResult<Target>> callUseCase({
      DateTime? startDate,
      DateTime? endDate,
      double targetValue = 100000,
      TargetStatus status = TargetStatus.active,
      String createdBy = 'manager-1',
    }) {
      return useCase.call(
        id: 'target-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: TargetDimensionType.salesRep,
        dimensionId: 'user-1',
        periodGranularity: TargetPeriodGranularity.monthly,
        startDate: startDate ?? DateTime.utc(2026, 1, 1),
        endDate: endDate ?? DateTime.utc(2026, 2, 1),
        metricType: TargetMetricType.revenue,
        targetValue: targetValue,
        status: status,
        createdBy: createdBy,
      );
    }

    test('creates an active target with version 1 and pending sync', () async {
      final result = await callUseCase();

      expect(result, isA<AppSuccess<Target>>());
      final target = (result as AppSuccess<Target>).value;
      expect(target.status, TargetStatus.active);
      expect(target.version, 1);
      expect(target.syncStatus, TargetSyncStatus.pending);
      expect(target.currency, 'BRL');
      expect(
        analytics.loggedEvents.any(
          (event) => event.name == AnalyticsEvents.targetCreated,
        ),
        isTrue,
      );
    });

    test('denies creation for a SALES_REP actor and never calls the repository '
        '(RBAC)', () async {
      _stubMembership(membershipRepository, 'rep-1', 'SALES_REP');

      final result = await callUseCase(createdBy: 'rep-1');

      expect(result, isA<AppFailure<Target>>());
      final failure = (result as AppFailure<Target>).failure;
      expect(failure, isA<PermissionFailure>());
      expect((failure as PermissionFailure).code, 'target_manage_denied');
      verifyNever(() => repository.create(target: any(named: 'target')));
    });

    test('rejects a negative targetValue', () async {
      final result = await callUseCase(targetValue: -1);

      expect(result, isA<AppFailure<Target>>());
      final failure = (result as AppFailure<Target>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('targetValue', 'TargetValue cannot be negative.'),
      );
      verifyNever(() => repository.create(target: any(named: 'target')));
    });

    test('accepts a zero targetValue (the domain boundary)', () async {
      final result = await callUseCase(targetValue: 0);
      expect(result, isA<AppSuccess<Target>>());
    });

    test('rejects an inverted period (endDate before startDate)', () async {
      final result = await callUseCase(
        startDate: DateTime.utc(2026, 2, 1),
        endDate: DateTime.utc(2026, 1, 1),
      );

      expect(result, isA<AppFailure<Target>>());
      final failure = (result as AppFailure<Target>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors,
        containsPair('endDate', 'EndDate must be after startDate.'),
      );
      verifyNever(() => repository.create(target: any(named: 'target')));
    });

    test('rejects a zero-length period (endDate equal to startDate)', () async {
      final sameInstant = DateTime.utc(2026, 1, 1);
      final result = await callUseCase(
        startDate: sameInstant,
        endDate: sameInstant,
      );

      expect(result, isA<AppFailure<Target>>());
      verifyNever(() => repository.create(target: any(named: 'target')));
    });

    test('rejects an active target overlapping another active target for the '
        'same dimension/metric', () async {
      when(
        () => repository.listByDimension(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          dimensionType: any(named: 'dimensionType'),
          dimensionId: any(named: 'dimensionId'),
          metricType: any(named: 'metricType'),
        ),
      ).thenAnswer(
        (_) async => AppSuccess<List<Target>>(<Target>[
          _buildFallbackTarget(
            startDate: DateTime.utc(2026, 1, 15),
            endDate: DateTime.utc(2026, 2, 15),
          ),
        ]),
      );

      final result = await callUseCase();

      expect(result, isA<AppFailure<Target>>());
      final failure = (result as AppFailure<Target>).failure;
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'target_period_overlap');
      verifyNever(() => repository.create(target: any(named: 'target')));
    });

    test(
      'allows an overlap against a closed (no longer active) target',
      () async {
        when(
          () => repository.listByDimension(
            organizationId: any(named: 'organizationId'),
            companyId: any(named: 'companyId'),
            dimensionType: any(named: 'dimensionType'),
            dimensionId: any(named: 'dimensionId'),
            metricType: any(named: 'metricType'),
          ),
        ).thenAnswer(
          (_) async => AppSuccess<List<Target>>(<Target>[
            _buildFallbackTarget(
              status: TargetStatus.closed,
              startDate: DateTime.utc(2026, 1, 15),
              endDate: DateTime.utc(2026, 2, 15),
            ),
          ]),
        );

        final result = await callUseCase();
        expect(result, isA<AppSuccess<Target>>());
      },
    );

    test('skips the overlap check entirely for a draft target', () async {
      when(
        () => repository.listByDimension(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          dimensionType: any(named: 'dimensionType'),
          dimensionId: any(named: 'dimensionId'),
          metricType: any(named: 'metricType'),
        ),
      ).thenAnswer(
        (_) async => AppSuccess<List<Target>>(<Target>[
          _buildFallbackTarget(
            startDate: DateTime.utc(2026, 1, 15),
            endDate: DateTime.utc(2026, 2, 15),
          ),
        ]),
      );

      final result = await callUseCase(status: TargetStatus.draft);

      expect(result, isA<AppSuccess<Target>>());
      verifyNever(
        () => repository.listByDimension(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          dimensionType: any(named: 'dimensionType'),
          dimensionId: any(named: 'dimensionId'),
          metricType: any(named: 'metricType'),
        ),
      );
    });

    test('propagates a repository query failure without creating', () async {
      when(
        () => repository.listByDimension(
          organizationId: any(named: 'organizationId'),
          companyId: any(named: 'companyId'),
          dimensionType: any(named: 'dimensionType'),
          dimensionId: any(named: 'dimensionId'),
          metricType: any(named: 'metricType'),
        ),
      ).thenAnswer(
        (_) async => const AppFailure<List<Target>>(
          UnexpectedFailure('boom', code: 'unexpected'),
        ),
      );

      final result = await callUseCase();

      expect(result, isA<AppFailure<Target>>());
      final failure = (result as AppFailure<Target>).failure;
      expect(failure, isA<UnexpectedFailure>());
      verifyNever(() => repository.create(target: any(named: 'target')));
    });
  });
}

void _stubMembership(
  _MockMembershipRepository membershipRepository,
  String userId,
  String roleName,
) {
  when(
    () =>
        membershipRepository.getByUser(organizationId: 'org-1', userId: userId),
  ).thenAnswer(
    (_) async => AppSuccess<Membership>(
      Membership(
        id: userId,
        organizationId: 'org-1',
        userId: userId,
        roleId: roleName,
        roleName: roleName,
        status: MembershipStatus.active,
        version: 1,
        createdAt: DateTime.utc(2026, 1, 1),
        createdBy: 'owner-1',
        updatedAt: DateTime.utc(2026, 1, 1),
        updatedBy: 'owner-1',
      ),
    ),
  );
}

Target _buildFallbackTarget({
  DateTime? startDate,
  DateTime? endDate,
  TargetStatus status = TargetStatus.active,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Target(
    id: 'fallback-target',
    organizationId: 'org-1',
    companyId: 'company-1',
    dimensionType: TargetDimensionType.salesRep,
    dimensionId: 'user-1',
    periodGranularity: TargetPeriodGranularity.monthly,
    startDate: startDate ?? now,
    endDate: endDate ?? DateTime.utc(2026, 2, 1),
    metricType: TargetMetricType.revenue,
    targetValue: 0,
    currency: 'BRL',
    status: status,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
    version: 1,
    syncStatus: TargetSyncStatus.pending,
  );
}
