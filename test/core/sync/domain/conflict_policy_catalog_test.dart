import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/sync/sync.dart';

void main() {
  group('ConflictPolicyCatalog', () {
    test('order and orderItem (financial/critical entities) are always '
        'manualResolution — never lastWriteWins, never fieldMerge', () {
      expect(
        ConflictPolicyCatalog.policyFor(OutboxEntityType.order),
        ConflictPolicy.manualResolution,
      );
      expect(
        ConflictPolicyCatalog.policyFor(OutboxEntityType.orderItem),
        ConflictPolicy.manualResolution,
      );
    });

    test('customer is fieldMerge', () {
      expect(
        ConflictPolicyCatalog.policyFor(OutboxEntityType.customer),
        ConflictPolicy.fieldMerge,
      );
    });

    test('crmActivity is lastWriteWins', () {
      expect(
        ConflictPolicyCatalog.policyFor(OutboxEntityType.crmActivity),
        ConflictPolicy.lastWriteWins,
      );
    });

    test('every OutboxEntityType value maps to exactly one policy (isolation: '
        'no entity silently falls through without an explicit decision)', () {
      for (final entityType in OutboxEntityType.values) {
        expect(
          () => ConflictPolicyCatalog.policyFor(entityType),
          returnsNormally,
        );
      }
    });
  });
}
