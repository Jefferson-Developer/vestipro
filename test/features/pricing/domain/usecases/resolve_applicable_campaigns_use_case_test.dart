import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('ResolveApplicableCampaignsUseCase', () {
    final now = DateTime.utc(2026, 8, 27);

    PromotionalCampaign campaign({
      required String id,
      required int priority,
      bool stackable = false,
      DateTime? validTo,
      String customerSegment = 'vip',
      List<String> productIds = const <String>['product-1'],
    }) {
      return PromotionalCampaign(
        id: id,
        organizationId: 'org-1',
        companyId: 'company-1',
        name: id,
        validFrom: DateTime.utc(2026, 8, 1),
        validTo: validTo ?? DateTime.utc(2026, 8, 31),
        customerSegment: customerSegment,
        productIds: productIds,
        discountType: PromotionalDiscountType.percentage,
        discountValue: 10,
        stackableWithOtherCampaigns: stackable,
        priority: priority,
        status: PromotionalCampaignStatus.active,
        createdAt: now,
        createdBy: 'admin-1',
        updatedAt: now,
        updatedBy: 'admin-1',
      );
    }

    test('returns empty when no campaign is eligible', () async {
      final useCase = ResolveApplicableCampaignsUseCase(
        _FakePromotionalCampaignRepository(const <PromotionalCampaign>[]),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerSegment: 'vip',
        productId: 'product-1',
        now: now,
      );

      final value = (result as AppSuccess<PromotionalCampaignResolution>).value;
      expect(value.eligibleCampaigns, isEmpty);
      expect(value.appliedCampaigns, isEmpty);
    });

    test('returns one campaign when a single campaign is eligible', () async {
      final useCase = ResolveApplicableCampaignsUseCase(
        _FakePromotionalCampaignRepository(<PromotionalCampaign>[
          campaign(id: 'campaign-1', priority: 1),
        ]),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerSegment: 'vip',
        productId: 'product-1',
        now: now,
      );

      final value = (result as AppSuccess<PromotionalCampaignResolution>).value;
      expect(value.appliedCampaigns.single.campaignId, 'campaign-1');
    });

    test('keeps multiple stackable campaigns', () async {
      final useCase = ResolveApplicableCampaignsUseCase(
        _FakePromotionalCampaignRepository(<PromotionalCampaign>[
          campaign(id: 'campaign-1', priority: 2, stackable: true),
          campaign(id: 'campaign-2', priority: 1, stackable: true),
        ]),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerSegment: 'vip',
        productId: 'product-1',
        now: now,
      );

      final value = (result as AppSuccess<PromotionalCampaignResolution>).value;
      expect(value.appliedCampaigns, hasLength(2));
    });

    test(
      'resolves the highest-priority non-stackable campaign deterministically',
      () async {
        final useCase = ResolveApplicableCampaignsUseCase(
          _FakePromotionalCampaignRepository(<PromotionalCampaign>[
            campaign(id: 'campaign-b', priority: 5),
            campaign(id: 'campaign-a', priority: 5),
            campaign(id: 'campaign-c', priority: 9),
          ]),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          customerSegment: 'vip',
          productId: 'product-1',
          now: now,
        );

        final value =
            (result as AppSuccess<PromotionalCampaignResolution>).value;
        expect(value.winningCampaign?.id, 'campaign-c');
        expect(value.appliedCampaigns.single.campaignId, 'campaign-c');
      },
    );

    test('excludes expired campaigns', () async {
      final useCase = ResolveApplicableCampaignsUseCase(
        _FakePromotionalCampaignRepository(<PromotionalCampaign>[
          campaign(
            id: 'campaign-1',
            priority: 1,
            validTo: DateTime.utc(2026, 8, 10),
          ),
        ]),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerSegment: 'vip',
        productId: 'product-1',
        now: now,
      );

      final value = (result as AppSuccess<PromotionalCampaignResolution>).value;
      expect(value.appliedCampaigns, isEmpty);
    });

    test('excludes campaigns from another customer segment', () async {
      final useCase = ResolveApplicableCampaignsUseCase(
        _FakePromotionalCampaignRepository(<PromotionalCampaign>[
          campaign(id: 'campaign-1', priority: 1, customerSegment: 'outlet'),
        ]),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        customerSegment: 'vip',
        productId: 'product-1',
        now: now,
      );

      final value = (result as AppSuccess<PromotionalCampaignResolution>).value;
      expect(value.appliedCampaigns, isEmpty);
    });
  });
}

final class _FakePromotionalCampaignRepository
    implements PromotionalCampaignRepository {
  _FakePromotionalCampaignRepository(this._items);

  final List<PromotionalCampaign> _items;

  @override
  Future<AppResult<PromotionalCampaign>> create({
    required PromotionalCampaign campaign,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<PromotionalCampaign?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<PromotionalCampaign>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<PromotionalCampaign>>(
      _items
          .where(
            (item) =>
                item.organizationId == organizationId &&
                item.companyId == companyId,
          )
          .toList(growable: false),
    );
  }

  @override
  Future<AppResult<PromotionalCampaign>> update({
    required PromotionalCampaign campaign,
  }) {
    throw UnimplementedError();
  }
}
