import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/catalog_share.dart';
import '../repositories/catalog_share_repository.dart';

/// Re-reads a catalog share by id (TASK-081) — used to refresh
/// `openCount`/`lastOpenedAt` on the origin screen after a share was
/// created ("vendedor consegue ver, na origem do compartilhamento, se e
/// quando o link foi aberto").
@injectable
final class GetCatalogShareUseCase {
  const GetCatalogShareUseCase(this._repository);

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
            code: 'invalid_get_catalog_share_payload',
          ),
        ),
      );
    }

    return _repository.getById(
      organizationId: trimmedOrganizationId,
      shareId: trimmedShareId,
    );
  }
}
