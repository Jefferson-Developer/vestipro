import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/permissions/permissions.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/audit_log/audit_log.dart';
import 'package:vestipro/features/organizations/organizations.dart';
import 'package:vestipro/features/targets/targets.dart';

class _MockTargetRepository extends Mock implements TargetRepository {}

class _MockMembershipRepository extends Mock implements MembershipRepository {}

class _FakeAuditLogRepository implements AuditLogRepository {
  final List<AuditLogEntry> recorded = <AuditLogEntry>[];

  @override
  Future<AppResult<AuditLogEntry>> record(AuditLogEntry entry) async {
    recorded.add(entry);
    return AppSuccess<AuditLogEntry>(entry);
  }

  @override
  Future<AppResult<List<AuditLogEntry>>> listByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    AuditAction? action,
    String? actorUserId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<AuditLogEntryPage>> listPageByOrganization({
    required String organizationId,
    int limit = 50,
    DateTime? before,
    DateTime? from,
    DateTime? to,
    Set<AuditAction> actions = const <AuditAction>{},
    String? actorUserId,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  group('UpdateTargetUseCase', () {
    late _MockTargetRepository repository;
    late _MockMembershipRepository membershipRepository;
    late PermissionService permissionService;
    late _FakeAuditLogRepository auditLogRepository;
    late FakeAnalyticsService analytics;
    late UpdateTargetUseCase useCase;
    late Target existing;

    setUpAll(() {
      registerFallbackValue(TargetDimensionType.salesRep);
      registerFallbackValue(TargetMetricType.revenue);
      registerFallbackValue(_buildTarget());
    });

    setUp(() {
      repository = _MockTargetRepository();
      membershipRepository = _MockMembershipRepository();
      permissionService = PermissionService(membershipRepository);
      auditLogRepository = _FakeAuditLogRepository();
      analytics = FakeAnalyticsService();
      useCase = UpdateTargetUseCase(
        repository,
        permissionService,
        auditLogRepository,
        analytics,
      );
      existing = _buildTarget();

      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer((_) async => AppSuccess<Target>(existing));
      when(() => repository.update(target: any(named: 'target'))).thenAnswer((
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
      ).thenAnswer((_) async => AppSuccess<List<Target>>(<Target>[existing]));
      _stubMembership(membershipRepository, 'manager-1', 'SALES_MANAGER');
    });

    Future<AppResult<Target>> callUseCase({
      double targetValue = 150000,
      DateTime? startDate,
      DateTime? endDate,
      TargetStatus status = TargetStatus.active,
      String updatedBy = 'manager-1',
      double? currentAchievedValue,
      bool confirmReduceBelowAchieved = false,
    }) {
      return useCase.call(
        organizationId: 'org-1',
        id: 'target-1',
        periodGranularity: TargetPeriodGranularity.monthly,
        startDate: startDate ?? DateTime.utc(2026, 1, 1),
        endDate: endDate ?? DateTime.utc(2026, 2, 1),
        metricType: TargetMetricType.revenue,
        targetValue: targetValue,
        currency: 'BRL',
        status: status,
        updatedBy: updatedBy,
        actorName: 'Manager One',
        currentAchievedValue: currentAchievedValue,
        confirmReduceBelowAchieved: confirmReduceBelowAchieved,
      );
    }

    test('updates the target, bumps version and logs targetUpdated', () async {
      final result = await callUseCase(targetValue: 200000);

      expect(result, isA<AppSuccess<Target>>());
      final updated = (result as AppSuccess<Target>).value;
      expect(updated.targetValue, 200000);
      expect(updated.version, existing.version + 1);
      expect(
        analytics.loggedEvents.any(
          (event) => event.name == AnalyticsEvents.targetUpdated,
        ),
        isTrue,
      );
    });

    test('records an audit log entry with previous and new values', () async {
      await callUseCase(targetValue: 200000);

      expect(auditLogRepository.recorded, hasLength(1));
      final entry = auditLogRepository.recorded.single;
      expect(entry.action, AuditAction.targetUpdated);
      expect(entry.entityType, 'target');
      expect(entry.entityId, existing.id);
      expect(entry.previousValue?['targetValue'], existing.targetValue);
      expect(entry.newValue?['targetValue'], 200000);
    });

    test('denies the update for a SALES_REP actor and never calls the '
        'repository (RBAC)', () async {
      _stubMembership(membershipRepository, 'rep-1', 'SALES_REP');

      final result = await callUseCase(updatedBy: 'rep-1');

      expect(result, isA<AppFailure<Target>>());
      final failure = (result as AppFailure<Target>).failure;
      expect(failure, isA<PermissionFailure>());
      expect((failure as PermissionFailure).code, 'target_manage_denied');
      verifyNever(() => repository.update(target: any(named: 'target')));
      expect(auditLogRepository.recorded, isEmpty);
    });

    test('rejects an active period overlapping another active target for the '
        'same dimension/metric, excluding itself', () async {
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
          existing,
          _buildTarget(
            id: 'other-target',
            startDate: DateTime.utc(2026, 1, 15),
            endDate: DateTime.utc(2026, 2, 15),
          ),
        ]),
      );

      final result = await callUseCase();

      expect(result, isA<AppFailure<Target>>());
      final failure = (result as AppFailure<Target>).failure;
      expect((failure as ValidationFailure).code, 'target_period_overlap');
      verifyNever(() => repository.update(target: any(named: 'target')));
    });

    test(
      'does not flag an overlap against itself (same id, unchanged period)',
      () async {
        final result = await callUseCase();
        expect(result, isA<AppSuccess<Target>>());
      },
    );

    test('requires confirmation before lowering targetValue below what was '
        'already achieved', () async {
      final result = await callUseCase(
        targetValue: 50000,
        currentAchievedValue: 80000,
      );

      expect(result, isA<AppFailure<Target>>());
      final failure = (result as AppFailure<Target>).failure;
      expect(
        (failure as ValidationFailure).code,
        'target_value_below_achieved',
      );
      verifyNever(() => repository.update(target: any(named: 'target')));
    });

    test(
      'proceeds lowering targetValue below achieved once confirmed',
      () async {
        final result = await callUseCase(
          targetValue: 50000,
          currentAchievedValue: 80000,
          confirmReduceBelowAchieved: true,
        );

        expect(result, isA<AppSuccess<Target>>());
      },
    );

    test('propagates a not-found failure without updating', () async {
      when(
        () => repository.getById(
          organizationId: any(named: 'organizationId'),
          id: any(named: 'id'),
        ),
      ).thenAnswer(
        (_) async => const AppFailure<Target>(
          NotFoundFailure('Target not found.', code: 'target_not_found'),
        ),
      );

      final result = await callUseCase();

      expect(result, isA<AppFailure<Target>>());
      verifyNever(() => repository.update(target: any(named: 'target')));
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

Target _buildTarget({
  String id = 'target-1',
  DateTime? startDate,
  DateTime? endDate,
}) {
  final now = DateTime.utc(2026, 1, 1);
  return Target(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    dimensionType: TargetDimensionType.salesRep,
    dimensionId: 'user-1',
    periodGranularity: TargetPeriodGranularity.monthly,
    startDate: startDate ?? DateTime.utc(2026, 1, 1),
    endDate: endDate ?? DateTime.utc(2026, 2, 1),
    metricType: TargetMetricType.revenue,
    targetValue: 100000,
    currency: 'BRL',
    status: TargetStatus.active,
    createdAt: now,
    createdBy: 'manager-1',
    updatedAt: now,
    updatedBy: 'manager-1',
    version: 1,
    syncStatus: TargetSyncStatus.pending,
  );
}
