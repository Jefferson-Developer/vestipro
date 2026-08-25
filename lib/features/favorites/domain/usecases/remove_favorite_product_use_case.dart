import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../repositories/favorite_repository.dart';

/// Unfavorites a product for the signed-in user (TASK-079) — a no-op (not a
/// failure) when it was not favorited, so a duplicated/late tap after a
/// previous unfavorite already landed never surfaces an error.
@injectable
final class RemoveFavoriteProductUseCase {
  const RemoveFavoriteProductUseCase(this._repository);

  final FavoriteRepository _repository;

  Future<AppResult<void>> call({
    required String organizationId,
    required String userId,
    required String productId,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedUserId = userId.trim();
    final trimmedProductId = productId.trim();

    if (trimmedOrganizationId.isEmpty ||
        trimmedUserId.isEmpty ||
        trimmedProductId.isEmpty) {
      return const AppFailure<void>(
        ValidationFailure(
          'Invalid remove-favorite payload.',
          code: 'invalid_remove_favorite_payload',
        ),
      );
    }

    return _repository.removeFavorite(
      organizationId: trimmedOrganizationId,
      userId: trimmedUserId,
      productId: trimmedProductId,
    );
  }
}
