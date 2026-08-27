import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/pricing/pricing.dart';

/// Sentinel used so `validToOverride: null` in the [priceList] helper below
/// is distinguishable from "not passed" (which should fall back to the
/// default `validTo`).
const Object _unset = Object();

void main() {
  group('PriceList', () {
    final validFrom = DateTime.utc(2026, 1, 1);
    final validTo = DateTime.utc(2026, 12, 31);

    PriceList priceList({
      PriceListStatus status = PriceListStatus.active,
      DateTime? validFromOverride,
      Object? validToOverride = _unset,
      PriceListScopeType scope = PriceListScopeType.company,
      String? scopeValue,
      DateTime? deletedAt,
    }) {
      final now = DateTime.utc(2026, 6, 1);
      return PriceList(
        id: 'price-list-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        name: 'Tabela Padrão',
        currency: 'BRL',
        validFrom: validFromOverride ?? validFrom,
        validTo: identical(validToOverride, _unset)
            ? validTo
            : validToOverride as DateTime?,
        status: status,
        scope: scope,
        scopeValue: scopeValue,
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        deletedAt: deletedAt,
        version: 1,
        syncStatus: PriceListSyncStatus.synced,
      );
    }

    test('a valid price list can be created with all required fields', () {
      final result = priceList();

      expect(result.id, 'price-list-1');
      expect(result.currency, 'BRL');
      expect(result.status, PriceListStatus.active);
      expect(result.priority, 0);
    });

    test(
      'isWithinValidityWindow is true strictly between validFrom/validTo',
      () {
        final result = priceList();

        expect(result.isWithinValidityWindow(DateTime.utc(2026, 6, 1)), isTrue);
        expect(result.isWithinValidityWindow(validFrom), isTrue);
        expect(result.isWithinValidityWindow(validTo), isTrue);
        expect(
          result.isWithinValidityWindow(DateTime.utc(2025, 12, 31)),
          isFalse,
        );
        expect(
          result.isWithinValidityWindow(DateTime.utc(2027, 1, 1)),
          isFalse,
        );
      },
    );

    test('a null validTo never expires by date alone', () {
      final result = priceList(validToOverride: null);

      expect(result.isWithinValidityWindow(DateTime.utc(2099, 1, 1)), isTrue);
    });

    test('isApplicableAt is false when status is not active, even inside the '
        'validity window', () {
      final result = priceList(status: PriceListStatus.draft);

      expect(result.isApplicableAt(DateTime.utc(2026, 6, 1)), isFalse);
    });

    test('isApplicableAt is false outside the validity window, even when '
        'status is still flagged active (TASK-083 business rule)', () {
      final result = priceList();

      expect(result.isApplicableAt(DateTime.utc(2027, 1, 1)), isFalse);
    });

    test('isApplicableAt is false once soft-deleted', () {
      final result = priceList(deletedAt: DateTime.utc(2026, 3, 1));

      expect(result.isApplicableAt(DateTime.utc(2026, 6, 1)), isFalse);
    });

    test('isApplicableAt is true when active and inside the window', () {
      final result = priceList();

      expect(result.isApplicableAt(DateTime.utc(2026, 6, 1)), isTrue);
    });

    test('company scope matches every customer context', () {
      final result = priceList();

      expect(
        result.matchesCustomerContext(
          customerChannel: 'ecommerce',
          customerSegment: 'premium',
        ),
        isTrue,
      );
      expect(result.matchesCustomerContext(), isTrue);
    });

    test('channel scope only matches the same customer channel', () {
      final result = priceList(
        scope: PriceListScopeType.channel,
        scopeValue: 'wholesale',
      );

      expect(
        result.matchesCustomerContext(customerChannel: 'wholesale'),
        isTrue,
      );
      expect(
        result.matchesCustomerContext(customerChannel: 'ecommerce'),
        isFalse,
      );
      expect(result.matchesCustomerContext(), isFalse);
    });

    test('segment scope only matches the same customer segment', () {
      final result = priceList(
        scope: PriceListScopeType.segment,
        scopeValue: 'vip',
      );

      expect(result.matchesCustomerContext(customerSegment: 'vip'), isTrue);
      expect(
        result.matchesCustomerContext(customerSegment: 'regular'),
        isFalse,
      );
    });
  });
}
