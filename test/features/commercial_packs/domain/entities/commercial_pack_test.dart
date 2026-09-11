import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/commercial_packs/commercial_packs.dart';

/// Sentinel used so `validToOverride: null` in the [commercialPack] helper
/// below is distinguishable from "not passed" (which should fall back to
/// the default `validTo`).
const Object _unset = Object();

void main() {
  group('CommercialPack', () {
    final validFrom = DateTime.utc(2026, 1, 1);
    final validTo = DateTime.utc(2026, 12, 31);

    CommercialPack commercialPack({
      CommercialPackStatus status = CommercialPackStatus.active,
      DateTime? validFromOverride,
      Object? validToOverride = _unset,
      String? customerSegment,
      String? channel,
      DateTime? deletedAt,
    }) {
      final now = DateTime.utc(2026, 6, 1);
      return CommercialPack(
        id: 'pack-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        packCode: 'PACK-1',
        version: 1,
        name: 'Kit Verão',
        packType: CommercialPackType.kit,
        status: status,
        pricingPolicyType: CommercialPackPricingPolicyType.componentSum,
        stockPolicyType: CommercialPackStockPolicyType.consumeComponentBalances,
        customerSegment: customerSegment,
        channel: channel,
        validFrom: validFromOverride ?? validFrom,
        validTo: identical(validToOverride, _unset)
            ? validTo
            : validToOverride as DateTime?,
        components: const <PackComponent>[
          PackComponent(
            id: 'component-1',
            scopeType: PackComponentScopeType.variant,
            scopeReferenceId: 'variant-1',
            compositionType: PackComponentCompositionType.fixed,
            quantity: 1,
          ),
        ],
        createdAt: now,
        createdBy: 'user-1',
        updatedAt: now,
        updatedBy: 'user-1',
        deletedAt: deletedAt,
        syncStatus: CommercialPackSyncStatus.synced,
      );
    }

    test('a valid commercial pack can be created with all required fields', () {
      final result = commercialPack();

      expect(result.id, 'pack-1');
      expect(result.packCode, 'PACK-1');
      expect(result.version, 1);
      expect(result.status, CommercialPackStatus.active);
      expect(result.components, hasLength(1));
      expect(result.assortmentRules, isEmpty);
    });

    test(
      'isWithinValidityWindow is true strictly between validFrom/validTo',
      () {
        final result = commercialPack();

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
      final result = commercialPack(validToOverride: null);

      expect(result.isWithinValidityWindow(DateTime.utc(2099, 1, 1)), isTrue);
    });

    test('isApplicableAt is false when status is not active, even inside the '
        'validity window', () {
      final result = commercialPack(status: CommercialPackStatus.draft);

      expect(result.isApplicableAt(DateTime.utc(2026, 6, 1)), isFalse);
    });

    test('isApplicableAt is false outside the validity window, even when '
        'status is still flagged active', () {
      final result = commercialPack();

      expect(result.isApplicableAt(DateTime.utc(2027, 1, 1)), isFalse);
    });

    test('isApplicableAt is false once soft-deleted', () {
      final result = commercialPack(deletedAt: DateTime.utc(2026, 3, 1));

      expect(result.isApplicableAt(DateTime.utc(2026, 6, 1)), isFalse);
    });

    test('isApplicableAt is true when active and inside the window', () {
      final result = commercialPack();

      expect(result.isApplicableAt(DateTime.utc(2026, 6, 1)), isTrue);
    });

    test('a pack with no customerSegment/channel narrowing matches every '
        'customer context', () {
      final result = commercialPack();

      expect(
        result.matchesCustomerContext(
          candidateSegment: 'premium',
          candidateChannel: 'ecommerce',
        ),
        isTrue,
      );
      expect(result.matchesCustomerContext(), isTrue);
    });

    test('a pack narrowed to a customerSegment only matches that segment', () {
      final result = commercialPack(customerSegment: 'vip');

      expect(result.matchesCustomerContext(candidateSegment: 'vip'), isTrue);
      expect(
        result.matchesCustomerContext(candidateSegment: 'regular'),
        isFalse,
      );
      expect(result.matchesCustomerContext(), isFalse);
    });

    test('a pack narrowed to a channel only matches that channel', () {
      final result = commercialPack(channel: 'wholesale');

      expect(
        result.matchesCustomerContext(candidateChannel: 'wholesale'),
        isTrue,
      );
      expect(
        result.matchesCustomerContext(candidateChannel: 'ecommerce'),
        isFalse,
      );
    });

    test(
      'a pack narrowed to both segment and channel requires both to match',
      () {
        final result = commercialPack(
          customerSegment: 'vip',
          channel: 'wholesale',
        );

        expect(
          result.matchesCustomerContext(
            candidateSegment: 'vip',
            candidateChannel: 'wholesale',
          ),
          isTrue,
        );
        expect(
          result.matchesCustomerContext(
            candidateSegment: 'vip',
            candidateChannel: 'ecommerce',
          ),
          isFalse,
        );
      },
    );
  });
}
