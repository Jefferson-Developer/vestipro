import '../../../../core/utils/utils.dart';
import '../entities/discount_policy.dart';

abstract interface class DiscountPolicyRepository {
  Future<AppResult<DiscountPolicy>> create({
    required DiscountPolicy discountPolicy,
  });

  Future<AppResult<DiscountPolicy>> update({
    required DiscountPolicy discountPolicy,
  });

  Future<AppResult<DiscountPolicy?>> getById({
    required String organizationId,
    required String id,
  });

  Future<AppResult<List<DiscountPolicy>>> listByCompany({
    required String organizationId,
    required String companyId,
  });
}
