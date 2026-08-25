import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/variant_availability.dart';
import '../entities/variant_availability_snapshot.dart';
import '../repositories/variant_availability_repository.dart';

@injectable
final class GetVariantAvailabilityUseCase {
  const GetVariantAvailabilityUseCase(this._repository);

  final VariantAvailabilityRepository _repository;

  Future<AppResult<VariantAvailabilitySnapshot>> call({
    required String organizationId,
    Iterable<String> variantIds = const <String>[],
    Iterable<String> productIds = const <String>[],
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    if (trimmedOrganizationId.isEmpty) {
      return const AppFailure<VariantAvailabilitySnapshot>(
        ValidationFailure(
          'Invalid variant availability payload.',
          fieldErrors: <String, String>{
            'organizationId': 'OrganizationId is required.',
          },
          code: 'invalid_variant_availability_payload',
        ),
      );
    }

    final trimmedVariantIds = _cleanIds(variantIds);
    final trimmedProductIds = _cleanIds(productIds);
    if (trimmedVariantIds.isEmpty && trimmedProductIds.isEmpty) {
      return const AppSuccess<VariantAvailabilitySnapshot>(
        VariantAvailabilitySnapshot(),
      );
    }

    final all = <VariantAvailability>[];
    if (trimmedVariantIds.isNotEmpty) {
      final result = await _repository.listByVariantIds(
        organizationId: trimmedOrganizationId,
        variantIds: trimmedVariantIds,
      );
      if (result is AppFailure<List<VariantAvailability>>) {
        return AppFailure<VariantAvailabilitySnapshot>(result.failure);
      }
      all.addAll((result as AppSuccess<List<VariantAvailability>>).value);
    }

    if (trimmedProductIds.isNotEmpty) {
      final result = await _repository.listByProductIds(
        organizationId: trimmedOrganizationId,
        productIds: trimmedProductIds,
      );
      if (result is AppFailure<List<VariantAvailability>>) {
        return AppFailure<VariantAvailabilitySnapshot>(result.failure);
      }
      all.addAll((result as AppSuccess<List<VariantAvailability>>).value);
    }

    return AppSuccess<VariantAvailabilitySnapshot>(
      VariantAvailabilitySnapshot.fromList(all),
    );
  }

  List<String> _cleanIds(Iterable<String> ids) {
    return ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
