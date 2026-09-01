import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('DriftTargetAchievementRepository', () {
    late AppDatabase database;
    late DriftTargetAchievementRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftTargetAchievementRepository(database);
    });

    tearDown(() => database.close());

    test(
      'no local Target row yet resolves to an uncalculated snapshot',
      () async {
        final result = await repository.getForTarget(
          organizationId: 'org-1',
          targetId: 'target-1',
        );

        final snapshot =
            (result as AppSuccess<TargetAchievementSnapshot>).value;
        expect(snapshot.isCalculated, isFalse);
        expect(snapshot.realizedValue, isNull);
        expect(snapshot.calculatedAt, isNull);
      },
    );

    test('a Target row with a null achievedValueCache resolves to an '
        'uncalculated snapshot, never zero', () async {
      await database.upsertTarget(
        TargetsTableCompanion.insert(
          id: 'target-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          dimensionId: 'user-1',
          periodStart: DateTime.utc(2026, 1, 1),
          periodEnd: DateTime.utc(2026, 2, 1),
          metric: 'revenue',
          targetValue: 100000,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'user-1',
          version: 1,
          syncStatus: 'synced',
        ),
      );

      final result = await repository.getForTarget(
        organizationId: 'org-1',
        targetId: 'target-1',
      );

      final snapshot = (result as AppSuccess<TargetAchievementSnapshot>).value;
      expect(snapshot.isCalculated, isFalse);
    });

    test('a Target row with a populated achievedValueCache resolves to a '
        'calculated snapshot, timestamped from the row\'s updatedAt', () async {
      final updatedAt = DateTime.utc(2026, 1, 20, 8);
      await database.upsertTarget(
        TargetsTableCompanion.insert(
          id: 'target-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          dimensionId: 'user-1',
          periodStart: DateTime.utc(2026, 1, 1),
          periodEnd: DateTime.utc(2026, 2, 1),
          metric: 'revenue',
          targetValue: 100000,
          achievedValueCache: const Value(42000),
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
          updatedAt: updatedAt,
          updatedBy: 'user-1',
          version: 1,
          syncStatus: 'synced',
        ),
      );

      final result = await repository.getForTarget(
        organizationId: 'org-1',
        targetId: 'target-1',
      );

      final snapshot = (result as AppSuccess<TargetAchievementSnapshot>).value;
      expect(snapshot.isCalculated, isTrue);
      expect(snapshot.realizedValue, 42000);
      expect(snapshot.calculatedAt!.isAtSameMomentAs(updatedAt), isTrue);
    });

    test('never resolves a Target row belonging to a different '
        'organizationId', () async {
      await database.upsertTarget(
        TargetsTableCompanion.insert(
          id: 'target-1',
          organizationId: 'other-org',
          companyId: 'company-1',
          dimensionId: 'user-1',
          periodStart: DateTime.utc(2026, 1, 1),
          periodEnd: DateTime.utc(2026, 2, 1),
          metric: 'revenue',
          targetValue: 100000,
          achievedValueCache: const Value(42000),
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'user-1',
          version: 1,
          syncStatus: 'synced',
        ),
      );

      final result = await repository.getForTarget(
        organizationId: 'org-1',
        targetId: 'target-1',
      );

      final snapshot = (result as AppSuccess<TargetAchievementSnapshot>).value;
      expect(snapshot.isCalculated, isFalse);
    });

    test('watchForTarget emits a fresh snapshot once the cached achieved '
        'value is updated by a future sync pass', () async {
      await database.upsertTarget(
        TargetsTableCompanion.insert(
          id: 'target-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          dimensionId: 'user-1',
          periodStart: DateTime.utc(2026, 1, 1),
          periodEnd: DateTime.utc(2026, 2, 1),
          metric: 'revenue',
          targetValue: 100000,
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
          updatedAt: DateTime.utc(2026, 1, 1),
          updatedBy: 'user-1',
          version: 1,
          syncStatus: 'synced',
        ),
      );

      final emissions = <TargetAchievementSnapshot>[];
      final subscription = repository
          .watchForTarget(organizationId: 'org-1', targetId: 'target-1')
          .listen(emissions.add);

      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions.single.isCalculated, isFalse);

      await database.upsertTarget(
        TargetsTableCompanion.insert(
          id: 'target-1',
          organizationId: 'org-1',
          companyId: 'company-1',
          dimensionId: 'user-1',
          periodStart: DateTime.utc(2026, 1, 1),
          periodEnd: DateTime.utc(2026, 2, 1),
          metric: 'revenue',
          targetValue: 100000,
          achievedValueCache: const Value(75000),
          createdAt: DateTime.utc(2026, 1, 1),
          createdBy: 'user-1',
          updatedAt: DateTime.utc(2026, 1, 25),
          updatedBy: 'sync-engine',
          version: 2,
          syncStatus: 'synced',
        ),
      );

      await pumpEventQueue();
      expect(emissions, hasLength(2));
      expect(emissions.last.isCalculated, isTrue);
      expect(emissions.last.realizedValue, 75000);

      await subscription.cancel();
    });
  });
}
