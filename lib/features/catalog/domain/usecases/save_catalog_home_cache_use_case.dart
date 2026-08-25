import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/catalog_home_snapshot.dart';
import '../repositories/catalog_home_cache_repository.dart';

/// Persists the freshly-loaded catalog home (TASK-076) so the next open can
/// paint instantly and offline use keeps showing the last known sections
/// (stale-while-revalidate). Best-effort: a caller (`CatalogHomeBloc`) never
/// blocks the "ready" state on this succeeding.
@injectable
final class SaveCatalogHomeCacheUseCase {
  SaveCatalogHomeCacheUseCase(this._repository);

  final CatalogHomeCacheRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    String? companyId,
    required CatalogHomeSnapshot snapshot,
  }) {
    return _repository.save(
      organizationId: organizationId.trim(),
      companyId: companyId,
      snapshot: snapshot,
    );
  }
}
