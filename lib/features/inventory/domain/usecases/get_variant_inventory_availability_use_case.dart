import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/variant_inventory_availability.dart';
import '../repositories/variant_stock_balance_repository.dart';

@injectable
final class GetVariantInventoryAvailabilityUseCase {
  const GetVariantInventoryAvailabilityUseCase(this._repository);

  final VariantStockBalanceRepository _repository;

  Future<AppResult<VariantInventoryAvailability>> call({
    required String organizationId,
    required String variantId,
    String? warehouseId,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedVariantId = variantId.trim();
    if (trimmedOrganizationId.isEmpty || trimmedVariantId.isEmpty) {
      return Future<AppResult<VariantInventoryAvailability>>.value(
        const AppFailure<VariantInventoryAvailability>(
          ValidationFailure(
            'Invalid inventory availability payload.',
            fieldErrors: <String, String>{
              'organizationId': 'OrganizationId is required.',
              'variantId': 'VariantId is required.',
            },
            code: 'invalid_inventory_availability_payload',
          ),
        ),
      );
    }

    return _repository.getAvailability(
      organizationId: trimmedOrganizationId,
      variantId: trimmedVariantId,
      warehouseId: warehouseId?.trim(),
    );
  }
}
