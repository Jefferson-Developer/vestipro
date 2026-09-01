import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/targets/targets.dart';

class _MockTargetRepository extends Mock implements TargetRepository {}

void main() {
  group('CreateTargetUseCase', () {
    late _MockTargetRepository repository;
    late CreateTargetUseCase useCase;

    setUpAll(() {
      registerFallbackValue(_buildFallbackTarget());
      registerFallbackValue(TargetDimensionType.salesRep);
      registerFallbackValue(TargetMetricType.revenue);
    });

    setUp(() {
      repository = _MockTargetRepository();
      useCase = CreateTargetUseCase(repository);
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
    });

    Future<AppResult<Target>> callUseCase({
      DateTime? startDate,
      DateTime? endDate,
      double targetValue = 100000,
      TargetStatus status = TargetStatus.active,
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
        createdBy: 'manager-1',
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
