import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('CreatePriceListUseCase', () {
    late _FakePriceListRepository repository;
    late CreatePriceListUseCase useCase;

    setUp(() {
      repository = _FakePriceListRepository();
      useCase = CreatePriceListUseCase(repository);
    });

    Future<AppResult<PriceList>> call({
      String currency = 'BRL',
      DateTime? validFrom,
      DateTime? validTo,
      PriceListScopeType scope = PriceListScopeType.company,
      String? scopeValue,
      int priority = 0,
    }) {
      return useCase(
        id: 'price-list-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Tabela Padrão',
        currency: currency,
        validFrom: validFrom ?? DateTime.utc(2026, 1, 1),
        validTo: validTo,
        scope: scope,
        scopeValue: scopeValue,
        priority: priority,
        createdBy: 'user-1',
      );
    }

    test(
      'creates a valid price list as draft, version 1, pending sync',
      () async {
        final result = await call();

        expect(result, isA<AppSuccess<PriceList>>());
        final priceList = (result as AppSuccess<PriceList>).value;
        expect(priceList.status, PriceListStatus.draft);
        expect(priceList.version, 1);
        expect(priceList.syncStatus, PriceListSyncStatus.pending);
        expect(priceList.currency, 'BRL');
        expect(repository.created, hasLength(1));
      },
    );

    test('rejects validTo before validFrom', () async {
      final result = await call(
        validFrom: DateTime.utc(2026, 6, 1),
        validTo: DateTime.utc(2026, 1, 1),
      );

      expect(result, isA<AppFailure<PriceList>>());
      final failure = (result as AppFailure<PriceList>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure as ValidationFailure).fieldErrors.containsKey('validTo'),
        isTrue,
      );
      expect(repository.created, isEmpty);
    });

    test('rejects validTo equal to validFrom', () async {
      final sameInstant = DateTime.utc(2026, 1, 1);
      final result = await call(validFrom: sameInstant, validTo: sameInstant);

      expect(result, isA<AppFailure<PriceList>>());
    });

    test('rejects a missing/empty currency', () async {
      final result = await call(currency: '');

      expect(result, isA<AppFailure<PriceList>>());
      final failure = (result as AppFailure<PriceList>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors.containsKey('currency'),
        isTrue,
      );
    });

    test('rejects a currency that is not a 3-letter ISO code', () async {
      final result = await call(currency: 'R\$');

      expect(result, isA<AppFailure<PriceList>>());
    });

    test('rejects channel scope without a scopeValue', () async {
      final result = await call(scope: PriceListScopeType.channel);

      expect(result, isA<AppFailure<PriceList>>());
      final failure = (result as AppFailure<PriceList>).failure;
      expect(
        (failure as ValidationFailure).fieldErrors.containsKey('scopeValue'),
        isTrue,
      );
    });

    test('rejects segment scope without a scopeValue', () async {
      final result = await call(scope: PriceListScopeType.segment);

      expect(result, isA<AppFailure<PriceList>>());
    });

    test('accepts channel scope with a scopeValue', () async {
      final result = await call(
        scope: PriceListScopeType.channel,
        scopeValue: 'wholesale',
      );

      expect(result, isA<AppSuccess<PriceList>>());
      expect((result as AppSuccess<PriceList>).value.scopeValue, 'wholesale');
    });

    test('rejects a company-scope scopeValue being set', () async {
      final result = await call(
        scope: PriceListScopeType.company,
        scopeValue: 'wholesale',
      );

      expect(result, isA<AppFailure<PriceList>>());
    });

    test('rejects a negative priority', () async {
      final result = await call(priority: -1);

      expect(result, isA<AppFailure<PriceList>>());
    });
  });
}

final class _FakePriceListRepository implements PriceListRepository {
  final List<PriceList> created = <PriceList>[];

  @override
  Future<AppResult<PriceList>> create({required PriceList priceList}) async {
    created.add(priceList);
    return AppSuccess<PriceList>(priceList);
  }

  @override
  Future<AppResult<PriceList>> update({required PriceList priceList}) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PriceList?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PriceList>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) {
    throw UnimplementedError();
  }
}
