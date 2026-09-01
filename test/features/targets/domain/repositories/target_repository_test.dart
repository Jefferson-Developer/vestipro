import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/targets/targets.dart';

/// Minimal in-memory fake exercising the [TargetRepository] contract —
/// TASK-114 models the contract only (no concrete production
/// implementation yet, mirroring `OpportunityRepository`'s TASK-057), so
/// this fake exists purely to prove [TargetRepository.listByDimension]'s
/// dimension + metric query contract behaves as documented.
class _FakeTargetRepository implements TargetRepository {
  final List<Target> _targets = <Target>[];

  @override
  Future<AppResult<Target>> create({required Target target}) async {
    _targets.add(target);
    return AppSuccess<Target>(target);
  }

  @override
  Future<AppResult<Target>> update({required Target target}) async {
    final index = _targets.indexWhere((existing) => existing.id == target.id);
    if (index == -1) {
      return const AppFailure<Target>(
        NotFoundFailure('Target not found.', code: 'target_not_found'),
      );
    }
    _targets[index] = target;
    return AppSuccess<Target>(target);
  }

  @override
  Future<AppResult<Target>> getById({
    required String organizationId,
    required String id,
  }) async {
    for (final target in _targets) {
      if (target.organizationId == organizationId && target.id == id) {
        return AppSuccess<Target>(target);
      }
    }
    return const AppFailure<Target>(
      NotFoundFailure('Target not found.', code: 'target_not_found'),
    );
  }

  @override
  Future<AppResult<List<Target>>> listByDimension({
    required String organizationId,
    String? companyId,
    required TargetDimensionType dimensionType,
    required String dimensionId,
    TargetMetricType? metricType,
  }) async {
    final results = _targets
        .where((target) {
          if (target.organizationId != organizationId) return false;
          if (companyId != null && target.companyId != companyId) return false;
          if (target.dimensionType != dimensionType) return false;
          if (target.dimensionId != dimensionId) return false;
          if (metricType != null && target.metricType != metricType) {
            return false;
          }
          return true;
        })
        .toList(growable: false);
    return AppSuccess<List<Target>>(results);
  }
}

void main() {
  group('TargetRepository (fake datasource)', () {
    late _FakeTargetRepository repository;

    Target buildTarget({
      required String id,
      TargetDimensionType dimensionType = TargetDimensionType.salesRep,
      String dimensionId = 'user-1',
      TargetMetricType metricType = TargetMetricType.revenue,
      String companyId = 'company-1',
      DateTime? startDate,
      DateTime? endDate,
    }) {
      final now = DateTime.utc(2026, 1, 1);
      return Target(
        id: id,
        organizationId: 'org-1',
        companyId: companyId,
        dimensionType: dimensionType,
        dimensionId: dimensionId,
        periodGranularity: TargetPeriodGranularity.monthly,
        startDate: startDate ?? DateTime.utc(2026, 1, 1),
        endDate: endDate ?? DateTime.utc(2026, 2, 1),
        metricType: metricType,
        targetValue: 50000,
        currency: 'BRL',
        status: TargetStatus.active,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: TargetSyncStatus.synced,
      );
    }

    setUp(() {
      repository = _FakeTargetRepository();
    });

    test('listByDimension returns every period for a sales rep in the current '
        'month', () async {
      await repository.create(
        target: buildTarget(
          id: 'target-1',
          startDate: DateTime.utc(2026, 1, 1),
          endDate: DateTime.utc(2026, 2, 1),
        ),
      );
      await repository.create(
        target: buildTarget(
          id: 'target-2',
          dimensionId: 'user-2',
          startDate: DateTime.utc(2026, 1, 1),
          endDate: DateTime.utc(2026, 2, 1),
        ),
      );

      final result = await repository.listByDimension(
        organizationId: 'org-1',
        dimensionType: TargetDimensionType.salesRep,
        dimensionId: 'user-1',
      );

      expect(result, isA<AppSuccess<List<Target>>>());
      final targets = (result as AppSuccess<List<Target>>).value;
      expect(targets, hasLength(1));
      expect(targets.single.id, 'target-1');
    });

    test('listByDimension narrows by metricType when a team has both a '
        'revenue and a positivação target in the same quarter', () async {
      await repository.create(
        target: buildTarget(
          id: 'revenue-target',
          dimensionType: TargetDimensionType.team,
          dimensionId: 'team-1',
          metricType: TargetMetricType.revenue,
          startDate: DateTime.utc(2026, 1, 1),
          endDate: DateTime.utc(2026, 4, 1),
        ),
      );
      await repository.create(
        target: buildTarget(
          id: 'positivacao-target',
          dimensionType: TargetDimensionType.team,
          dimensionId: 'team-1',
          metricType: TargetMetricType.positivacao,
          startDate: DateTime.utc(2026, 1, 1),
          endDate: DateTime.utc(2026, 4, 1),
        ),
      );

      final result = await repository.listByDimension(
        organizationId: 'org-1',
        dimensionType: TargetDimensionType.team,
        dimensionId: 'team-1',
        metricType: TargetMetricType.positivacao,
      );

      final targets = (result as AppSuccess<List<Target>>).value;
      expect(targets, hasLength(1));
      expect(targets.single.id, 'positivacao-target');
    });

    test('listByDimension narrows by companyId when supplied', () async {
      await repository.create(
        target: buildTarget(id: 'company-1-target', companyId: 'company-1'),
      );
      await repository.create(
        target: buildTarget(id: 'company-2-target', companyId: 'company-2'),
      );

      final result = await repository.listByDimension(
        organizationId: 'org-1',
        companyId: 'company-2',
        dimensionType: TargetDimensionType.salesRep,
        dimensionId: 'user-1',
      );

      final targets = (result as AppSuccess<List<Target>>).value;
      expect(targets, hasLength(1));
      expect(targets.single.id, 'company-2-target');
    });
  });
}
