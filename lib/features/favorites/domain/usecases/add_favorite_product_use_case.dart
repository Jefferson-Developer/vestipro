import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/favorite_product.dart';
import '../repositories/favorite_repository.dart';

/// Favorites a product for the signed-in user (TASK-079) — local-first and
/// idempotent: tapping "favoritar" repeatedly, even offline, never creates
/// more than one favorite for the same ([organizationId], [userId],
/// [productId]) triple.
@injectable
final class AddFavoriteProductUseCase {
  const AddFavoriteProductUseCase(this._repository);

  final FavoriteRepository _repository;

  Future<AppResult<FavoriteProduct>> call({
    required String organizationId,
    required String userId,
    required String productId,
    String? companyId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUserId = userId.trim();
    final trimmedProductId = productId.trim();

    if (trimmedOrganizationId.isEmpty ||
        trimmedUserId.isEmpty ||
        trimmedProductId.isEmpty) {
      return const AppFailure<FavoriteProduct>(
        ValidationFailure(
          'Invalid add-favorite payload.',
          code: 'invalid_add_favorite_payload',
        ),
      );
    }

    return _repository.addFavorite(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
      productId: trimmedProductId,
      companyId: companyId,
    );
  }
}
