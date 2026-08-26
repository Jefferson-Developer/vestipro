import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/catalog_share_preview.dart';
import '../repositories/catalog_share_lookup_repository.dart';

/// Previews a catalog share [token] (TASK-081) — the only client-side check
/// is that a token was actually provided; every other decision (unknown/
/// expired/revoked/valid) is the repository's (ultimately
/// `getCatalogShareLink`'s).
@injectable
final class PreviewCatalogShareUseCase {
  const PreviewCatalogShareUseCase(this._repository);

  final CatalogShareLookupRepository _repository;

  Future<AppResult<CatalogSharePreview>> call({required String token}) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return Future<AppResult<CatalogSharePreview>>.value(
        AppFailure<CatalogSharePreview>(
          const ValidationFailure(
            'Token de compartilhamento ausente.',
            code: 'catalog_share_token_required',
          ),
        ),
      );
    }

    return _repository.preview(token: trimmed);
  }
}
