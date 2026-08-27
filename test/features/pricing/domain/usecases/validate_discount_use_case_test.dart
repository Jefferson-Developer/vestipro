import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/pricing/pricing.dart';

void main() {
  group('ValidateDiscountUseCase', () {
    final now = DateTime.utc(2026, 8, 27);

    DiscountPolicy policy({
      double maxDiscountPercent = 15,
      double? requiresApprovalAbovePercent = 10,
      List<String> priceListIds = const <String>[],
    }) {
      return DiscountPolicy(
        id: 'policy-1',
        organizationId: 'org-1',
        companyId: 'company-1',
        role: 'SALES_REP',
        maxDiscountPercent: maxDiscountPercent,
        priceListIds: priceListIds,
        requiresApprovalAbovePercent: requiresApprovalAbovePercent,
        status: DiscountPolicyStatus.active,
        createdAt: now,
        createdBy: 'admin-1',
        updatedAt: now,
        updatedBy: 'admin-1',
        syncStatus: 'synced',
      );
    }

    test(
      'returns allowed when discount stays within approval threshold',
      () async {
        final useCase = ValidateDiscountUseCase(
          _FakeDiscountPolicyRepository(<DiscountPolicy>[policy()]),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          role: 'SALES_REP',
          requestedDiscountPercent: 8,
          priceListId: 'vip',
          requestedByUserId: 'rep-1',
          now: now,
        );

        expect(result, isA<AppSuccess<DiscountValidationResult>>());
        expect(
          (result as AppSuccess<DiscountValidationResult>).value,
          isA<DiscountAllowed>(),
        );
      },
    );

    test(
      'returns approval when discount exceeds threshold but not the maximum',
      () async {
        final useCase = ValidateDiscountUseCase(
          _FakeDiscountPolicyRepository(<DiscountPolicy>[policy()]),
        );

        final result = await useCase(
          organizationId: 'org-1',
          companyId: 'company-1',
          role: 'SALES_REP',
          requestedDiscountPercent: 12,
          priceListId: 'vip',
          requestedByUserId: 'rep-1',
          orderDraftId: 'draft-1',
          now: now,
        );

        final value =
            (result as AppSuccess<DiscountValidationResult>).value
                as DiscountRequiresApproval;
        expect(value.approvalRequest.orderDraftId, 'draft-1');
        expect(value.approvalRequest.requestedDiscountPercent, 12);
      },
    );

    test('returns blocked when discount exceeds the maximum', () async {
      final useCase = ValidateDiscountUseCase(
        _FakeDiscountPolicyRepository(<DiscountPolicy>[policy()]),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        role: 'SALES_REP',
        requestedDiscountPercent: 18,
        priceListId: 'vip',
        requestedByUserId: 'rep-1',
        now: now,
      );

      expect(
        (result as AppSuccess<DiscountValidationResult>).value,
        isA<DiscountBlocked>(),
      );
    });

    test('blocks explicitly when there is no policy for the profile', () async {
      final useCase = ValidateDiscountUseCase(
        _FakeDiscountPolicyRepository(const <DiscountPolicy>[]),
      );

      final result = await useCase(
        organizationId: 'org-1',
        companyId: 'company-1',
        role: 'SALES_REP',
        requestedDiscountPercent: 5,
        priceListId: 'vip',
        requestedByUserId: 'rep-1',
        now: now,
      );

      final value =
          (result as AppSuccess<DiscountValidationResult>).value
              as DiscountBlocked;
      expect(value.policy, isNull);
      expect(value.reason, contains('Nenhuma política'));
    });
  });
}

final class _FakeDiscountPolicyRepository implements DiscountPolicyRepository {
  _FakeDiscountPolicyRepository(this._items);

  final List<DiscountPolicy> _items;

  @override
  Future<AppResult<DiscountPolicy>> create({
    required DiscountPolicy discountPolicy,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<DiscountPolicy?>> getById({
    required String organizationId,
    required String id,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<AppResult<List<DiscountPolicy>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    return AppSuccess<List<DiscountPolicy>>(
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
  Future<AppResult<DiscountPolicy>> update({
    required DiscountPolicy discountPolicy,
  }) {
    throw UnimplementedError();
  }
}
