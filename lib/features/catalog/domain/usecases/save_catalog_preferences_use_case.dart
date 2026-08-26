import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/catalog_preferences.dart';
import '../repositories/catalog_preferences_repository.dart';

/// Persists the catalog view mode/filter (TASK-082) a user just left the
/// browsing screen with, so reopening it restores exactly where they left
/// off. Best-effort from `CatalogFilterBloc`'s point of view — a failure
/// here never blocks browsing itself, it only means the next open falls
/// back to the default view.
@injectable
final class SaveCatalogPreferencesUseCase {
  SaveCatalogPreferencesUseCase(this._repository);

  final CatalogPreferencesRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String userId,
    required CatalogPreferences preferences,
  }) {
    return _repository.save(
      organizationId: organizationId.trim(),
      userId: userId.trim(),
      preferences: preferences,
    );
  }
}
