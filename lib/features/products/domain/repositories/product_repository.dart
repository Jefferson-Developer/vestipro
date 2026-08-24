import '../../../../core/utils/utils.dart';
import '../entities/product.dart';

/// Domain contract for Product persistence, decoupled from Firestore/Drift.
///
/// TASK-064 modeled the entity and the basic read use case with only
/// [getById] as a contract-only repository, no concrete implementation, the
/// same precedent set by `LeadRepository` in TASK-055. Create/update
/// (cadastro/edição de produto) and a first concrete implementation land in
/// TASK-065.
abstract interface class ProductRepository {
  Future<AppResult<Product>> getById({
    required String organizationId,
    required String id,
  });
}
