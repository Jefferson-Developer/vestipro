import 'package:injectable/injectable.dart';

import '../repositories/favorite_repository.dart';

/// Reactive set of favorited `Product.id`s for the signed-in user
/// (TASK-079) — what `FavoriteStatusCubit` watches to keep every favorite
/// button (grid card, product detail, favorites screen) in sync with a
/// single local write, instead of each surface polling/re-fetching on its
/// own.
@injectable
final class WatchFavoriteProductIdsUseCase {
  const WatchFavoriteProductIdsUseCase(this._repository);

  final FavoriteRepository _repository;

  Stream<Set<String>> call({
    required String organizationId,
    required String userId,
  }) {
    return _repository.watchFavoriteProductIds(
      organizationId: organizationId,
      userId: userId,
    );
  }
}
