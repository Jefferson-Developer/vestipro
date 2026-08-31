import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('LoadInitialPaymentTermOfflineDataUseCase', () {
    late _FakePaymentTermRepository repository;
    late _FakePaymentTermLocalStoreRepository localStore;
    late LoadInitialPaymentTermOfflineDataUseCase useCase;

    setUp(() {
      repository = _FakePaymentTermRepository();
      localStore = _FakePaymentTermLocalStoreRepository();
      useCase = LoadInitialPaymentTermOfflineDataUseCase(
        repository,
        localStore,
      );
    });

    PaymentTerm paymentTerm(String id) {
      final now = DateTime.utc(2026, 1, 1);
      return PaymentTerm(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Condição $id',
        installments: const <PaymentInstallment>[],
        averageTermDays: 30,
        status: PaymentTermStatus.active,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
      );
    }

    test('rejects an invalid payload before touching any repository', () async {
      final result = await useCase(organizationId: '', companyId: 'company-1');

      expect(result, isA<AppFailure<int>>());
      expect(localStore.replaceCalls, isEmpty);
    });

    test('replaces the local payment term cache with every company payment '
        'term', () async {
      repository.paymentTerms.addAll(<PaymentTerm>[
        paymentTerm('a'),
        paymentTerm('b'),
        paymentTerm('c'),
      ]);

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect(result, isA<AppSuccess<int>>());
      expect((result as AppSuccess<int>).value, 3);
      expect(localStore.replaceCalls, hasLength(1));
      expect(localStore.replaceCalls.single, hasLength(3));
    });

    test('propagates a remote repository failure without touching the local '
        'store', () async {
      repository.listFailure = const ConnectivityFailure('offline');

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect(result, isA<AppFailure<int>>());
      expect(localStore.replaceCalls, isEmpty);
    });
  });
}

final class _FakePaymentTermRepository implements PaymentTermRepository {
  final List<PaymentTerm> paymentTerms = <PaymentTerm>[];
  Failure? listFailure;

  @override
  Future<AppResult<List<PaymentTerm>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    if (listFailure != null) {
      return AppFailure<List<PaymentTerm>>(listFailure!);
    }
    return AppSuccess<List<PaymentTerm>>(List<PaymentTerm>.of(paymentTerms));
  }

  @override
  Future<AppResult<PaymentTerm>> create({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PaymentTerm>> update({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PaymentTerm?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }
}

final class _FakePaymentTermLocalStoreRepository
    implements PaymentTermLocalStoreRepository {
  final List<List<PaymentTerm>> replaceCalls = <List<PaymentTerm>>[];

  @override
  Future<AppResult<void>> replaceInitialLoad({
    required String organizationId,
    required String companyId,
    required List<PaymentTerm> paymentTerms,
  }) async {
    replaceCalls.add(paymentTerms);
    return const AppSuccess<void>(null);
  }

  @override
  Future<AppResult<void>> upsert({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PaymentTerm>>> getAll({
    required String organizationId,
    required String companyId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<int>> count({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<int>(replaceCalls.isEmpty ? 0 : replaceCalls.last.length);
  }
}
