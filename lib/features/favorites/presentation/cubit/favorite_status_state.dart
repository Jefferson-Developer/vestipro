/// Which `Product.id`s are currently favorited by the signed-in user, for
/// whatever ([organizationId], [companyId]) scope [FavoriteStatusCubit] was
/// last started with (TASK-079).
final class FavoriteStatusState {
  const FavoriteStatusState({this.favoriteProductIds = const <String>{}});

  final Set<String> favoriteProductIds;

  bool isFavorite(String productId) => favoriteProductIds.contains(productId);

  FavoriteStatusState copyWith({Set<String>? favoriteProductIds}) {
    return FavoriteStatusState(
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
    );
  }
}
