import '../../../../core/utils/utils.dart';
import '../entities/catalog_preferences.dart';

/// Local persistence for the last catalog view mode/filter a user left the
/// browsing screen with (TASK-082).
///
/// Scoped by [organizationId] **and** [userId] — unlike
/// `CatalogHomeCacheRepository` (organization/company only), a filter
/// preference is personal: two users of the same organization/device must
/// never see each other's last filter, and switching the active
/// organization must never leak a filter from one tenant into another.
abstract interface class CatalogPreferencesRepository {
  Future<AppResult<CatalogPreferences?>> load({
    required String organizationId,
    required String userId,
  });

  Future<AppResult<void>> save({
    required String organizationId,
    required String userId,
    required CatalogPreferences preferences,
  });
}
