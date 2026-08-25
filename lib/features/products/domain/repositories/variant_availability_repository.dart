import '../../../../core/utils/utils.dart';
import '../entities/variant_availability.dart';

abstract interface class VariantAvailabilityRepository {
  Future<AppResult<List<VariantAvailability>>> listByVariantIds({
    required String organizationId,
    required Iterable<String> variantIds,
  });

  Future<AppResult<List<VariantAvailability>>> listByProductIds({
    required String organizationId,
    required Iterable<String> productIds,
  });
}
