import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/customers/customers.dart';

void main() {
  group('CustomerSegmentCriteria', () {
    test('combines three or more filter facets via AND simultaneously', () {
      const criteria = CustomerSegmentCriteria(
        portfolioFilters: CustomerPortfolioFilters(
          statuses: <CustomerStatus>{CustomerStatus.active},
          stateCodes: <String>{'SC', 'SP'},
          potentials: <String>{'Alto'},
          lastPurchase: CustomerLastPurchaseFilter.last90Days,
        ),
        purchasedCategoryCodes: <String>{'inverno'},
      );

      expect(criteria.combinedFacetCount, 5);
      expect(criteria.isEmpty, isFalse);
    });

    test('normalized() trims/lowercases category codes and dedupes UFs', () {
      const criteria = CustomerSegmentCriteria(
        portfolioFilters: CustomerPortfolioFilters(stateCodes: <String>{'sc'}),
        purchasedCategoryCodes: <String>{' Inverno ', 'inverno', ''},
      );

      final normalized = criteria.normalized();

      expect(normalized.purchasedCategoryCodes, <String>{'inverno'});
      expect(normalized.portfolioFilters.stateCodes, <String>{'SC'});
    });

    test('toPortfolioFilters() applies portfolio filters but not the purchased '
        'category criterion yet (no order history data source until '
        'EPIC-08/13)', () {
      const criteria = CustomerSegmentCriteria(
        portfolioFilters: CustomerPortfolioFilters(
          potentials: <String>{'Alto'},
        ),
        purchasedCategoryCodes: <String>{'praia'},
      );

      final filters = criteria.toPortfolioFilters();

      expect(filters.potentials, <String>{'Alto'});
      expect(filters, criteria.portfolioFilters);
    });

    test('toJson()/fromJson() round-trips every facet', () {
      const criteria = CustomerSegmentCriteria(
        portfolioFilters: CustomerPortfolioFilters(
          statuses: <CustomerStatus>{
            CustomerStatus.active,
            CustomerStatus.prospect,
          },
          stateCodes: <String>{'SC'},
          potentials: <String>{'Alto'},
          lastPurchase: CustomerLastPurchaseFilter.last30Days,
        ),
        purchasedCategoryCodes: <String>{'inverno'},
      );

      final restored = CustomerSegmentCriteria.fromJson(criteria.toJson());

      expect(restored, criteria);
      expect(restored.combinedFacetCount, criteria.combinedFacetCount);
    });

    test('empty criteria has no combined facets', () {
      expect(CustomerSegmentCriteria.empty.isEmpty, isTrue);
      expect(CustomerSegmentCriteria.empty.combinedFacetCount, 0);
    });
  });
}
