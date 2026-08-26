import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../entities/catalog_preferences.dart';
import '../repositories/catalog_preferences_repository.dart';

/// Reads the last catalog view mode/filter (TASK-082) a user left the
/// browsing screen with. `null` (inside a success) means there is simply no
/// saved preference yet — not a failure.
@injectable
final class LoadCatalogPreferencesUseCase {
  LoadCatalogPreferencesUseCase(this._repository);

  final CatalogPreferencesRepository _repository;

  Future<AppResult<CatalogPreferences?>> call({
    required String organizationId,
    required String userId,
  }) {
    return _repository.load(
      organizationId: organizationId.trim(),
      userId: userId.trim(),
    );
  }
}
