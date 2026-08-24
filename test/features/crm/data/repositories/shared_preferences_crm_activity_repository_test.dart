import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/crm/data/repositories/shared_preferences_crm_activity_repository.dart';
import 'package:vestipro/features/crm/crm.dart';

void main() {
  group('SharedPreferencesCrmActivityRepository', () {
    late SharedPreferencesCrmActivityRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = const SharedPreferencesCrmActivityRepository(
        CrmActivityMapper(),
      );
    });

    test('lists customer timeline newest-first with pagination', () async {
      await repository.create(
        activity: _activity(
          id: 'old',
          customerId: 'customer-1',
          occurredAt: DateTime.utc(2026, 8, 20, 12),
        ),
      );
      await repository.create(
        activity: _activity(
          id: 'new',
          customerId: 'customer-1',
          occurredAt: DateTime.utc(2026, 8, 22, 12),
        ),
      );
      await repository.create(
        activity: _activity(
          id: 'middle',
          customerId: 'customer-1',
          occurredAt: DateTime.utc(2026, 8, 21, 12),
        ),
      );
      await repository.create(
        activity: _activity(
          id: 'other-customer',
          customerId: 'customer-2',
          occurredAt: DateTime.utc(2026, 8, 23, 12),
        ),
      );

      final firstPage = await repository.listForCustomer(
        organizationId: 'org-1',
        customerId: 'customer-1',
        limit: 2,
      );

      expect(firstPage, isA<AppSuccess<CrmActivityPageResult>>());
      final page = (firstPage as AppSuccess<CrmActivityPageResult>).value;
      expect(page.activities.map((activity) => activity.id), ['new', 'middle']);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'middle');
      expect(page.isFromLocalCache, isTrue);

      final secondPage = await repository.listForCustomer(
        organizationId: 'org-1',
        customerId: 'customer-1',
        limit: 2,
        cursor: page.nextCursor,
      );
      final second = (secondPage as AppSuccess<CrmActivityPageResult>).value;
      expect(second.activities.map((activity) => activity.id), ['old']);
      expect(second.hasMore, isFalse);
    });

    test(
      'persists pending offline activity across repository instances',
      () async {
        final activity = _activity(id: 'activity-1', customerId: 'customer-1');
        await repository.create(activity: activity);

        final reloaded = const SharedPreferencesCrmActivityRepository(
          CrmActivityMapper(),
        );
        final result = await reloaded.listForCustomer(
          organizationId: 'org-1',
          customerId: 'customer-1',
        );

        final page = (result as AppSuccess<CrmActivityPageResult>).value;
        expect(page.activities.single.id, 'activity-1');
        expect(
          page.activities.single.syncStatus,
          CrmActivitySyncStatus.pending,
        );
      },
    );
  });
}

CrmActivity _activity({
  required String id,
  required String customerId,
  DateTime? occurredAt,
}) {
  final now = DateTime.utc(2026, 8, 24, 12);
  return CrmActivity(
    id: id,
    organizationId: 'org-1',
    type: CrmActivityType.phoneCall,
    customerId: customerId,
    userId: 'rep-1',
    occurredAt: occurredAt ?? now,
    description: 'Ligacao registrada',
    createdAt: now,
    createdBy: 'rep-1',
    updatedAt: now,
    updatedBy: 'rep-1',
    version: 1,
    syncStatus: CrmActivitySyncStatus.pending,
  );
}
