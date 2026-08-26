import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/features/catalog/catalog.dart';

void main() {
  group('CatalogCampaign.isVisibleAt', () {
    final now = DateTime.utc(2026, 6, 15);

    CatalogCampaign build({
      bool active = true,
      DateTime? startAt,
      DateTime? endAt,
      DateTime? deletedAt,
    }) {
      final createdAt = DateTime.utc(2026, 1, 1);
      return CatalogCampaign(
        id: 'campaign-1',
        organizationId: 'org-1',
        title: 'Campanha de Verão',
        order: 0,
        active: active,
        startAt: startAt,
        endAt: endAt,
        deletedAt: deletedAt,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: createdAt,
        updatedBy: 'user-1',
      );
    }

    test('is visible with no window and active', () {
      expect(build().isVisibleAt(now), isTrue);
    });

    test('is not visible when inactive', () {
      expect(build(active: false).isVisibleAt(now), isFalse);
    });

    test('is not visible when soft-deleted', () {
      expect(
        build(deletedAt: DateTime.utc(2026, 5, 1)).isVisibleAt(now),
        isFalse,
      );
    });

    test('is not visible before startAt', () {
      expect(
        build(startAt: DateTime.utc(2026, 7, 1)).isVisibleAt(now),
        isFalse,
      );
    });

    test('is visible exactly at startAt', () {
      expect(build(startAt: now).isVisibleAt(now), isTrue);
    });

    test('is not visible after endAt', () {
      expect(build(endAt: DateTime.utc(2026, 6, 1)).isVisibleAt(now), isFalse);
    });

    test('is visible exactly at endAt', () {
      expect(build(endAt: now).isVisibleAt(now), isTrue);
    });

    test('is visible within an open window', () {
      expect(
        build(
          startAt: DateTime.utc(2026, 6, 1),
          endAt: DateTime.utc(2026, 6, 30),
        ).isVisibleAt(now),
        isTrue,
      );
    });
  });

  group('CatalogCampaign.statusAt', () {
    final now = DateTime.utc(2026, 6, 15);

    CatalogCampaign build({
      bool active = true,
      DateTime? startAt,
      DateTime? endAt,
      DateTime? deletedAt,
    }) {
      final createdAt = DateTime.utc(2026, 1, 1);
      return CatalogCampaign(
        id: 'campaign-1',
        organizationId: 'org-1',
        title: 'Campanha de Verão',
        order: 0,
        active: active,
        startAt: startAt,
        endAt: endAt,
        deletedAt: deletedAt,
        createdAt: createdAt,
        createdBy: 'user-1',
        updatedAt: createdAt,
        updatedBy: 'user-1',
      );
    }

    test('is active with no window and active', () {
      expect(build().statusAt(now), CatalogCampaignStatus.active);
    });

    test('is inactive when deactivated', () {
      expect(
        build(active: false).statusAt(now),
        CatalogCampaignStatus.inactive,
      );
    });

    test('is inactive when soft-deleted, even if the window is open', () {
      expect(
        build(deletedAt: DateTime.utc(2026, 5, 1)).statusAt(now),
        CatalogCampaignStatus.inactive,
      );
    });

    test('is scheduled when startAt is still in the future', () {
      expect(
        build(startAt: DateTime.utc(2026, 7, 1)).statusAt(now),
        CatalogCampaignStatus.scheduled,
      );
    });

    test('is expired when endAt has already passed', () {
      expect(
        build(endAt: DateTime.utc(2026, 6, 1)).statusAt(now),
        CatalogCampaignStatus.expired,
      );
    });

    test('is active within an open window', () {
      expect(
        build(
          startAt: DateTime.utc(2026, 6, 1),
          endAt: DateTime.utc(2026, 6, 30),
        ).statusAt(now),
        CatalogCampaignStatus.active,
      );
    });
  });
}
