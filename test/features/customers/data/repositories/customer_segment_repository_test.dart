import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/customers/customers.dart';
import 'package:vestipro/features/customers/data/datasources/shared_preferences_customer_segment_data_source.dart';
import 'package:vestipro/features/customers/data/mappers/customer_segment_mapper.dart';
import 'package:vestipro/features/customers/data/repositories/customer_segment_repository_impl.dart';

void main() {
  group('CustomerSegmentRepositoryImpl (SharedPreferences)', () {
    late CustomerSegmentRepositoryImpl repository;
    final now = DateTime.utc(2026, 8, 24);

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = CustomerSegmentRepositoryImpl(
        dataSource: const SharedPreferencesCustomerSegmentDataSource(),
        mapper: const CustomerSegmentMapper(),
      );
    });

    CustomerSegment segment({
      required String id,
      required String organizationId,
      CustomerSegmentCriteria criteria = CustomerSegmentCriteria.empty,
      CustomerSegmentVisibility visibility = CustomerSegmentVisibility.private,
    }) {
      return CustomerSegment(
        id: id,
        organizationId: organizationId,
        name: 'Segmento $id',
        criteria: criteria,
        visibility: visibility,
        createdBy: 'rep-1',
        createdAt: now,
        updatedAt: now,
        updatedBy: 'rep-1',
      );
    }

    test('persists a segment and reapplies it after reload', () async {
      final created = segment(
        id: 'segment-1',
        organizationId: 'org-1',
        criteria: const CustomerSegmentCriteria(
          portfolioFilters: CustomerPortfolioFilters(
            statuses: <CustomerStatus>{CustomerStatus.active},
            stateCodes: <String>{'SC'},
            potentials: <String>{'Alto'},
            lastPurchase: CustomerLastPurchaseFilter.last90Days,
          ),
          purchasedCategoryCodes: <String>{'inverno'},
        ),
        visibility: CustomerSegmentVisibility.shared,
      );

      final createResult = await repository.create(created);
      expect(createResult, isA<AppSuccess<CustomerSegment>>());

      // Reload with a brand-new repository/data source instance to prove the
      // segment survived — this is what "reaplicação de segmento salvo"
      // means: the saved criteria must come back unchanged after a restart.
      final reloaded = CustomerSegmentRepositoryImpl(
        dataSource: const SharedPreferencesCustomerSegmentDataSource(),
        mapper: const CustomerSegmentMapper(),
      );
      final listResult = await reloaded.listByOrganization('org-1');

      expect(listResult, isA<AppSuccess<List<CustomerSegment>>>());
      final segments = (listResult as AppSuccess<List<CustomerSegment>>).value;
      expect(segments, hasLength(1));
      expect(segments.single.criteria, created.criteria);
      expect(segments.single.visibility, CustomerSegmentVisibility.shared);
    });

    test('scopes segments strictly by organization', () async {
      await repository.create(
        segment(id: 'segment-a', organizationId: 'org-1'),
      );
      await repository.create(
        segment(id: 'segment-b', organizationId: 'org-2'),
      );

      final result = await repository.listByOrganization('org-1');

      final segments = (result as AppSuccess<List<CustomerSegment>>).value;
      expect(segments.map((segment) => segment.id), <String>['segment-a']);
    });

    test('deletes a segment permanently', () async {
      await repository.create(
        segment(id: 'segment-1', organizationId: 'org-1'),
      );

      final deleteResult = await repository.delete(
        organizationId: 'org-1',
        id: 'segment-1',
      );
      expect(deleteResult, isA<AppSuccess<void>>());

      final listResult = await repository.listByOrganization('org-1');
      expect((listResult as AppSuccess<List<CustomerSegment>>).value, isEmpty);
    });
  });
}
