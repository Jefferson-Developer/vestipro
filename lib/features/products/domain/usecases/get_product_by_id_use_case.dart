import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Looks up a single Product by id, scoped to [organizationId].
///
/// Not annotated with `@injectable`: [ProductRepository] has no concrete
/// implementation registered yet (TASK-064 models domain/data only), so this
/// use case is wired manually once TASK-065 registers a repository, the same
/// precedent set by Lead's TASK-055 use cases.
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
