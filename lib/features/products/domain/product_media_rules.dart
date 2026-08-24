/// Pure list-transformation rules for `Product.media` (TASK-068), mirroring
/// `product_completeness_validator.dart`/`category_cycle_validator.dart`:
/// plain functions over already-loaded data, never a repository call or a
/// widget concern, so `ProductMediaBloc` never re-implements this logic
/// inline.
library;

import 'entities/product_media.dart';
import 'value_objects/product_media_type.dart';

/// The next `order` value for a newly appended item of [type] within
/// [media] — one past the current highest order of that same type, `0` when
/// [media] has none of [type] yet.
int nextProductMediaOrder(List<ProductMedia> media, ProductMediaType type) {
  final ordersOfType = media
      .where((item) => item.type == type)
      .map((item) => item.order);
  if (ordersOfType.isEmpty) return 0;
  return ordersOfType.reduce((a, b) => a > b ? a : b) + 1;
}

/// Appends [newMedia] to [media], assigning it the next order for its type
/// (see [nextProductMediaOrder] — [newMedia.order] is ignored/overwritten).
///
/// A freshly appended [ProductMediaType.photo] is automatically promoted to
/// `principal` when [media] has no photo yet — this is what lets "produto
/// não pode sair do rascunho sem imagem principal" (TASK-068) resolve itself
/// the moment a seller uploads the very first photo, instead of requiring a
/// separate manual "tornar principal" step for the common case of a single
/// photo.
List<ProductMedia> appendProductMedia(
  List<ProductMedia> media,
  ProductMedia newMedia,
) {
  final order = nextProductMediaOrder(media, newMedia.type);
  final isFirstPhoto =
      newMedia.type == ProductMediaType.photo &&
      !media.any((item) => item.type == ProductMediaType.photo);
  return List<ProductMedia>.unmodifiable(<ProductMedia>[
    ...media,
    newMedia.copyWith(order: order, principal: isFirstPhoto),
  ]);
}

/// Reassigns `order` for every item of [type] in [media] to match
/// [orderedIds] (already the caller's fully reordered id sequence for that
/// type — the same "caller hands back its own already-reordered list"
/// contract `ReorderCategoriesUseCase` uses for sibling categories).
///
/// [orderedIds] must be exactly the current ids of [type] in [media] — no
/// missing id, no extra id, nothing from a different type — otherwise
/// [media] is returned unchanged, since a mismatched set almost always means
/// the caller built [orderedIds] from a stale snapshot.
List<ProductMedia> reorderProductMedia(
  List<ProductMedia> media, {
  required ProductMediaType type,
  required List<String> orderedIds,
}) {
  final currentIds = media
      .where((item) => item.type == type)
      .map((item) => item.id)
      .toSet();
  final requestedIds = orderedIds.toSet();
  if (requestedIds.length != orderedIds.length ||
      requestedIds.length != currentIds.length ||
      !requestedIds.containsAll(currentIds)) {
    return media;
  }

  final orderById = <String, int>{
    for (var index = 0; index < orderedIds.length; index++)
      orderedIds[index]: index,
  };
  return List<ProductMedia>.unmodifiable(
    media
        .map(
          (item) => item.type == type
              ? item.copyWith(order: orderById[item.id]!)
              : item,
        )
        .toList(growable: false),
  );
}

/// Marks the [ProductMediaType.photo] identified by [mediaId] as `principal`
/// and every other photo as not — the invariant "no máximo uma foto
/// principal por produto" (TASK-068). Returns [media] unchanged if [mediaId]
/// does not exist or is not a photo (a video can never become principal).
List<ProductMedia> setPrincipalProductMedia(
  List<ProductMedia> media, {
  required String mediaId,
}) {
  final target = _findById(media, mediaId);
  if (target == null || target.type != ProductMediaType.photo) return media;

  return List<ProductMedia>.unmodifiable(
    media
        .map(
          (item) => item.type == ProductMediaType.photo
              ? item.copyWith(principal: item.id == mediaId)
              : item,
        )
        .toList(growable: false),
  );
}

/// Removes the media identified by [mediaId] from [media], compacting the
/// `order` of whatever remains of its type down to a dense `0..n-1`
/// sequence.
///
/// When the removed item was the `principal` photo, this automatically
/// promotes the next remaining photo (by `order`) to `principal` — TASK-068's
/// "excluir a imagem principal exige escolher outra automaticamente" option,
/// chosen over blocking the deletion so a seller can always remove a bad
/// photo without first being forced to pick a replacement. If no photo is
/// left, the product simply has none — `hasPrincipalPhoto` on `Product`
/// naturally goes back to blocking publish until a new photo is uploaded.
List<ProductMedia> removeProductMedia(
  List<ProductMedia> media, {
  required String mediaId,
}) {
  final target = _findById(media, mediaId);
  if (target == null) return media;

  final remaining = media.where((item) => item.id != mediaId).toList();
  final wasPrincipal =
      target.type == ProductMediaType.photo && target.principal;

  for (final type in ProductMediaType.values) {
    final ofType = remaining.where((item) => item.type == type).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    for (var index = 0; index < ofType.length; index++) {
      final compacted = ofType[index];
      final position = remaining.indexWhere((item) => item.id == compacted.id);
      remaining[position] = compacted.copyWith(order: index);
    }
  }

  if (!wasPrincipal) return List<ProductMedia>.unmodifiable(remaining);

  final remainingPhotos =
      remaining.where((item) => item.type == ProductMediaType.photo).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
  if (remainingPhotos.isEmpty) {
    return List<ProductMedia>.unmodifiable(remaining);
  }

  final promotedId = remainingPhotos.first.id;
  return List<ProductMedia>.unmodifiable(
    remaining
        .map(
          (item) => item.type == ProductMediaType.photo
              ? item.copyWith(principal: item.id == promotedId)
              : item,
        )
        .toList(growable: false),
  );
}

ProductMedia? _findById(List<ProductMedia> media, String id) {
  for (final item in media) {
    if (item.id == id) return item;
  }
  return null;
}
