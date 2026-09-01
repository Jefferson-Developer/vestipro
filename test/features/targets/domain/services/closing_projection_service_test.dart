import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('ClosingProjectionService.compute', () {
    const service = ClosingProjectionService();
    final createdAt = DateTime.utc(2026, 1, 1);

    Target buildTarget({
      double targetValue = 100000,
      DateTime? startDate,
      DateTime? endDate,
    }) {
      return Target(
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
        currency: 'BRL',
        status: TargetStatus.active,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: createdAt,
        updatedBy: 'user-1',
        version: 1,
        syncStatus: TargetSyncStatus.pending,
      );
    }

    test('período recém-iniciado (0% decorrido): projeção é calculada mas '
        'sinalizada como baixa confiabilidade, nunca escondida', () {
      final target = buildTarget(
        startDate: DateTime.utc(2026, 3, 1),
        endDate: DateTime.utc(2026, 4, 1),
      );
      final now = DateTime.utc(2026, 1, 1);
      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 0,
        now: now,
      );

      final projection = service.compute(progress);

      expect(projection.reliability, ProjectionReliability.lowConfidence);
      expect(projection.isLowConfidence, isTrue);
      expect(projection.isFinalResult, isFalse);
      expect(projection.projectedValue, 0);
      expect(projection.methodologyDescription, isNotEmpty);
    });

    test('menos de 10% do período decorrido: ainda sinalizado como baixa '
        'confiabilidade mesmo já tendo iniciado', () {
      final target = buildTarget(); // Jan 1 - Feb 1 (31 dias)
      final now = DateTime.utc(2026, 1, 3, 12); // ~2.5 dias decorridos (~8%)
      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 5000,
        now: now,
      );

      final projection = service.compute(progress);

      expect(projection.reliability, ProjectionReliability.lowConfidence);
    });

    test('meio do período: projeção linear confiável, consistente com o ritmo '
        'observado', () {
      final target = buildTarget(); // Jan 1 - Feb 1 (31 dias)
      final now = DateTime.utc(2026, 1, 16); // 15 dias decorridos (~48.4%)
      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 40000,
        now: now,
      );

      final projection = service.compute(progress);

      expect(projection.reliability, ProjectionReliability.reliable);
      expect(projection.isLowConfidence, isFalse);
      // 40000 / (15/31) ~= 82_666.67
      expect(projection.projectedValue, closeTo(82666.67, 1));
      expect(projection.isAboveTarget, isFalse);
    });

    test('período já encerrado: projeção é o valor final realizado, sem '
        'extrapolar, e marcada como resultado final', () {
      final target = buildTarget(); // Jan 1 - Feb 1
      final now = DateTime.utc(2026, 3, 15); // bem depois do fim
      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 130000,
        calculatedAt: DateTime.utc(2026, 2, 1),
        now: now,
      );

      final projection = service.compute(progress);

      expect(projection.reliability, ProjectionReliability.periodEnded);
      expect(projection.isFinalResult, isTrue);
      expect(projection.isLowConfidence, isFalse);
      expect(projection.projectedValue, 130000);
      expect(projection.isAboveTarget, isTrue);
      expect(projection.methodologyDescription, contains('Período encerrado'));
    });

    test('meta zerada: percentual projetado nunca divide por zero', () {
      final target = buildTarget(targetValue: 0);
      final now = DateTime.utc(2026, 1, 16);

      final zeroRealized = service.compute(
        TargetProgressViewModel.compute(
          target: target,
          realizedValue: 0,
          now: now,
        ),
      );
      expect(zeroRealized.projectedAchievementPercentage, 0);
      expect(zeroRealized.isAboveTarget, isTrue);

      final anyRealized = service.compute(
        TargetProgressViewModel.compute(
          target: target,
          realizedValue: 500,
          now: now,
        ),
      );
      expect(anyRealized.projectedAchievementPercentage, 100);
      expect(anyRealized.isAboveTarget, isTrue);
    });

    test('a projeção nunca diverge do realizado/projectedValue já calculado '
        'pelo dashboard de atingimento (TASK-116), para o mesmo ViewModel de '
        'entrada', () {
      final scenarios = <TargetProgressViewModel>[
        TargetProgressViewModel.compute(
          target: buildTarget(),
          realizedValue: 40000,
          now: DateTime.utc(2026, 1, 16),
        ),
        TargetProgressViewModel.compute(
          target: buildTarget(
            startDate: DateTime.utc(2026, 3, 1),
            endDate: DateTime.utc(2026, 4, 1),
          ),
          realizedValue: 0,
          now: DateTime.utc(2026, 1, 1),
        ),
        TargetProgressViewModel.compute(
          target: buildTarget(),
          realizedValue: 90000,
          now: DateTime.utc(2026, 3, 15),
        ),
      ];

      for (final progress in scenarios) {
        final projection = service.compute(progress);
        expect(
          projection.projectedValue,
          progress.projectedValue,
          reason:
              'ClosingProjectionService deve usar exatamente o mesmo '
              'realizado/projectedValue que TargetProgressViewModel '
              '(TASK-116) já calculou, nunca um número divergente.',
        );
        expect(
          projection.projectedAchievementPercentage,
          progress.projectedAchievementPercentage,
        );
      }
    });

    test('estratégia customizada substitui a fórmula sem quebrar o contrato '
        'de ClosingProjectionService', () {
      const customStrategy = _FixedProjectionStrategy(9999);
      const customService = ClosingProjectionService(strategy: customStrategy);
      final target = buildTarget();
      final progress = TargetProgressViewModel.compute(
        target: target,
        realizedValue: 40000,
        now: DateTime.utc(2026, 1, 16),
      );

      final projection = customService.compute(progress);

      expect(projection.projectedValue, 9999);
      expect(projection.methodologyDescription, 'estratégia fixa de teste');
    });
  });
}

final class _FixedProjectionStrategy implements ProjectionStrategy {
  const _FixedProjectionStrategy(this._fixedValue);

  final double _fixedValue;

  @override
  String get methodologyDescription => 'estratégia fixa de teste';

  @override
  double project({
    required double realizedValue,
    required double elapsedFraction,
  }) => _fixedValue;
}
