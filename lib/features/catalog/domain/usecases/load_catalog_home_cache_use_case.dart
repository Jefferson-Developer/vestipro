import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/catalog_home_snapshot.dart';
import '../repositories/catalog_home_cache_repository.dart';

/// Reads the last cached catalog home (TASK-076) for instant paint/offline
/// use. `null` (inside a success) means there is simply no cache yet, e.g.
/// first ever open — not a failure.
@injectable
final class LoadCatalogHomeCacheUseCase {
  LoadCatalogHomeCacheUseCase(this._repository);

  final CatalogHomeCacheRepository _repository;

  Future<AppResult<CatalogHomeSnapshot?>> call({
    required String organizationId,
    String? companyId,
  }) {
    return _repository.load(
      organizationId: organizationId.trim(),
      companyId: companyId,
    );
  }
}
