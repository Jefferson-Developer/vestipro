import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/targets/targets.dart';

void main() {
  group('DriftPositivacaoRepository', () {
    late AppDatabase database;
    late DriftPositivacaoRepository repository;

    final periodStart = DateTime.utc(2026, 9);
    final periodEnd = DateTime.utc(2026, 10);

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftPositivacaoRepository(database);
    });

    tearDown(() => database.close());

    Future<void> insertRow({
      required String id,
      int? totalPortfolio,
      int? positivatedCount,
      List<String>? nonPositivatedCustomerIds,
      DateTime? calculatedAt,
    }) {
      return database
          .into(database.positivacaoSnapshotsTable)
          .insert(
            PositivacaoSnapshotsTableCompanion.insert(
              id: id,
              organizationId: 'org-1',
              companyId: 'company-1',
              dimensionType: 'salesRep',
              dimensionId: 'seller-1',
              periodStart: periodStart,
              periodEnd: periodEnd,
              totalPortfolio: Value(totalPortfolio),
              positivatedCount: Value(positivatedCount),
              nonPositivatedCustomerIdsJson: Value(
                nonPositivatedCustomerIds == null
                    ? null
                    : jsonEncode(nonPositivatedCustomerIds),
              ),
              calculatedAt: Value(calculatedAt),
            ),
          );
    }

    test('no local row yet resolves to an uncalculated snapshot', () async {
      final result = await repository.getForDimension(
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: PositivacaoDimensionType.salesRep,
        dimensionId: 'seller-1',
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      final snapshot = (result as AppSuccess<PositivacaoSnapshot>).value;
      expect(snapshot.isCalculated, isFalse);
      expect(snapshot.totalPortfolio, isNull);
      expect(snapshot.positivatedCount, isNull);
    });

    test('a row with a null calculatedAt resolves to an uncalculated '
        'snapshot, never zero', () async {
      await insertRow(
        id: 'org-1:salesRep:seller-1:${periodStart.toIso8601String()}',
      );

      final result = await repository.getForDimension(
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: PositivacaoDimensionType.salesRep,
        dimensionId: 'seller-1',
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      final snapshot = (result as AppSuccess<PositivacaoSnapshot>).value;
      expect(snapshot.isCalculated, isFalse);
    });

    test('a fully populated row resolves to a calculated snapshot with the '
        'pending customer list decoded', () async {
      final calculatedAt = DateTime.utc(2026, 9, 15);
      await insertRow(
        id: 'org-1:salesRep:seller-1:${periodStart.toIso8601String()}',
        totalPortfolio: 10,
        positivatedCount: 6,
        nonPositivatedCustomerIds: <String>['customer-2', 'customer-9'],
        calculatedAt: calculatedAt,
      );

      final result = await repository.getForDimension(
        organizationId: 'org-1',
        companyId: 'company-1',
        dimensionType: PositivacaoDimensionType.salesRep,
        dimensionId: 'seller-1',
        periodStart: periodStart,
        periodEnd: periodEnd,
      );

      final snapshot = (result as AppSuccess<PositivacaoSnapshot>).value;
      expect(snapshot.isCalculated, isTrue);
      expect(snapshot.totalPortfolio, 10);
      expect(snapshot.positivatedCount, 6);
      expect(snapshot.percentage, 60);
      expect(snapshot.nonPositivatedCustomerIds, <String>[
        'customer-2',
        'customer-9',
      ]);
      expect(snapshot.calculatedAt!.isAtSameMomentAs(calculatedAt), isTrue);
    });

    test(
      'never resolves a row belonging to a different organizationId',
      () async {
        await insertRow(
          id: 'other-org:salesRep:seller-1:${periodStart.toIso8601String()}',
          totalPortfolio: 10,
          positivatedCount: 6,
          calculatedAt: DateTime.utc(2026, 9, 15),
        );

        final result = await repository.getForDimension(
          organizationId: 'org-1',
          companyId: 'company-1',
          dimensionType: PositivacaoDimensionType.salesRep,
          dimensionId: 'seller-1',
          periodStart: periodStart,
          periodEnd: periodEnd,
        );

        final snapshot = (result as AppSuccess<PositivacaoSnapshot>).value;
        expect(snapshot.isCalculated, isFalse);
      },
    );

    test('watchForDimension emits a fresh snapshot once a future pipeline '
        'inserts the row', () async {
      final emissions = <PositivacaoSnapshot>[];
      final subscription = repository
          .watchForDimension(
            organizationId: 'org-1',
            companyId: 'company-1',
            dimensionType: PositivacaoDimensionType.salesRep,
            dimensionId: 'seller-1',
            periodStart: periodStart,
            periodEnd: periodEnd,
          )
          .listen(emissions.add);

      await pumpEventQueue();
      expect(emissions, hasLength(1));
      expect(emissions.single.isCalculated, isFalse);

      await insertRow(
        id: 'org-1:salesRep:seller-1:${periodStart.toIso8601String()}',
        totalPortfolio: 4,
        positivatedCount: 1,
        calculatedAt: DateTime.utc(2026, 9, 20),
      );

      await pumpEventQueue();
      expect(emissions, hasLength(2));
      expect(emissions.last.isCalculated, isTrue);
      expect(emissions.last.positivatedCount, 1);

      await subscription.cancel();
    });
  });
}
