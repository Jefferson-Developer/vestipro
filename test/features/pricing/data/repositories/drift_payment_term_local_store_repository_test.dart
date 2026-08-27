import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/database/database.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/data/mappers/payment_term_local_mapper.dart';
import 'package:vestipro/features/pricing/data/repositories/drift_payment_term_local_store_repository.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('DriftPaymentTermLocalStoreRepository', () {
    late AppDatabase database;
    late DriftPaymentTermLocalStoreRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = DriftPaymentTermLocalStoreRepository(
        database,
        const PaymentTermLocalMapper(),
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('replaceInitialLoad stores payment terms for offline load', () async {
      final result = await repository.replaceInitialLoad(
        organizationId: 'org-1',
        companyId: 'company-1',
        paymentTerms: <PaymentTerm>[_term('a'), _term('b')],
      );

      expect(result, isA<AppSuccess<void>>());
      final count = await repository.count(
        organizationId: 'org-1',
        companyId: 'company-1',
      );
      expect((count as AppSuccess<int>).value, 2);
    });
  });
}

PaymentTerm _term(String id) {
  final now = DateTime.utc(2026, 1, 1);
  return PaymentTerm(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    name: 'Term $id',
    installments: const <PaymentInstallment>[
      PaymentInstallment(percentage: 100, dueInDays: 30),
    ],
    averageTermDays: 30,
    status: PaymentTermStatus.active,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}
