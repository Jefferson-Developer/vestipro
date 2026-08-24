import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Looks up a single Product by id, scoped to [organizationId].
///
/// TASK-065 registered `SharedPreferencesProductRepository` as the first
/// concrete [ProductRepository] implementation, so this use case is now
/// `@injectable` (it was wired manually in TASK-064, when no implementation
/// existed yet).
@injectable
final class GetProductByIdUseCase {
  const GetProductByIdUseCase(this._repository);

  final ProductRepository _repository;

  Future<AppResult<Product>> call({
    required String organizationId,
    required String id,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedId = id.trim();

    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';

    if (fieldErrors.isNotEmpty) {
      return Future<AppResult<Product>>.value(
        AppFailure<Product>(
          ValidationFailure(
            'Invalid product lookup payload.',
            fieldErrors: fieldErrors,
            code: 'invalid_product_lookup_payload',
          ),
        ),
      );
    }

    return _repository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedId,
    );
  }
}
