import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/catalog_share.dart';
import '../repositories/catalog_share_repository.dart';

/// Revokes an active catalog share (TASK-081), invalidating its link
/// immediately. The real authorization decision (only the creator or an
/// OWNER/ADMIN may succeed) is always `revokeCatalogShareLink`'s.
@injectable
final class RevokeCatalogShareUseCase {
  const RevokeCatalogShareUseCase(this._repository);

  final CatalogShareRepository _repository;

  Future<AppResult<CatalogShare>> call({
    required String organizationId,
    required String shareId,
  }) {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedShareId = shareId.trim();

    if (trimmedOrganizationId.isEmpty || trimmedShareId.isEmpty) {
      return Future<AppResult<CatalogShare>>.value(
        AppFailure<CatalogShare>(
          const ValidationFailure(
            'organizationId e shareId são obrigatórios.',
            code: 'invalid_revoke_catalog_share_payload',
          ),
        ),
      );
    }

    return _repository.revoke(
      organizationId: trimmedOrganizationId,
      shareId: trimmedShareId,
    );
  }
}
