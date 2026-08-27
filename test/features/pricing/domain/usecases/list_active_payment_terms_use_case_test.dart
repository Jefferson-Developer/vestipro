import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('ListActivePaymentTermsUseCase', () {
    late _FakePaymentTermRepository repository;
    late ListActivePaymentTermsUseCase useCase;

    setUp(() {
      repository = _FakePaymentTermRepository();
      useCase = ListActivePaymentTermsUseCase(repository);
    });

    test('returns only active terms', () async {
      repository.terms = <PaymentTerm>[
        _term('a', status: PaymentTermStatus.active),
        _term('b', status: PaymentTermStatus.inactive),
      ];

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect(
        (result as AppSuccess<List<PaymentTerm>>).value.map((term) => term.id),
        <String>['a'],
      );
    });

    test('filters by associated price list when restriction exists', () async {
      repository.terms = <PaymentTerm>[
        _term('a', priceListIds: const <String>['vip']),
        _term('b'),
        _term('c', priceListIds: const <String>['other']),
      ];

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        priceListId: 'vip',
      );

      expect(
        (result as AppSuccess<List<PaymentTerm>>).value.map((term) => term.id),
        <String>['a', 'b'],
      );
    });

    test('returns empty list when there are no active terms', () async {
      repository.terms = const <PaymentTerm>[];

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
      );

      expect((result as AppSuccess<List<PaymentTerm>>).value, isEmpty);
    });
  });
}

PaymentTerm _term(
  String id, {
  PaymentTermStatus status = PaymentTermStatus.active,
  List<String> priceListIds = const <String>[],
}) {
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
    status: status,
    priceListIds: priceListIds,
    createdAt: now,
    createdBy: 'user-1',
    updatedAt: now,
    updatedBy: 'user-1',
  );
}

final class _FakePaymentTermRepository implements PaymentTermRepository {
  List<PaymentTerm> terms = <PaymentTerm>[];

  @override
  Future<AppResult<PaymentTerm>> create({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PaymentTerm?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PaymentTerm>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<PaymentTerm>>(terms);
  }

  @override
  Future<AppResult<PaymentTerm>> update({required PaymentTerm paymentTerm}) {
    throw UnimplementedError();
  }
}
