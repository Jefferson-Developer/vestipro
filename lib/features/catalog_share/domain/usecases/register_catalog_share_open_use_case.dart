import 'package:injectable/injectable.dart';

import '../repositories/catalog_share_lookup_repository.dart';

/// Fires the best-effort "this link was just opened" counter (TASK-081).
/// Never fails/throws — see `CatalogShareLookupRepository.registerOpen`'s
/// own doc — so `CatalogSharePublicBloc` can call this without wrapping it
/// in any error handling of its own, and must never `await` it before
/// rendering the preview it already has.
@injectable
final class RegisterCatalogShareOpenUseCase {
  const RegisterCatalogShareOpenUseCase(this._repository);

  final CatalogShareLookupRepository _repository;

  Future<void> call({required String token}) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return _repository.registerOpen(token: trimmed);
  }
}
