import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../products/domain/entities/collection.dart';
import '../../../products/domain/repositories/collection_repository.dart';
import '../entities/catalog_home_item.dart';
import '../entities/catalog_home_section.dart';
import '../entities/catalog_home_section_config.dart';

/// Builds the catalog home's "coleções em destaque" section (TASK-076) from
/// the active `Collection`s of [organizationId] — the same data TASK-066's
/// collection management screen reads, so the home never keeps a second
/// source of truth for "which collections are current".
///
/// Sorted by [Collection.startDate] (falling back to [Collection.year],
/// then [Collection.createdAt]) descending — the most recently opened
/// collection is the one worth featuring first — and capped at
/// [CatalogHomeSectionConfig.itemLimit].
@injectable
final class GetFeaturedCollectionsSectionUseCase {
  GetFeaturedCollectionsSectionUseCase(this._collectionRepository);

  final CollectionRepository _collectionRepository;

  Future<AppResult<CatalogHomeSection>> call({
    required String organizationId,
    required CatalogHomeSectionConfig config,
  }) async {
    final result = await _collectionRepository.listByOrganization(
      organizationId.trim(),
    );

    return result.fold(
      onSuccess: (collections) {
        final featured =
            collections.where((collection) => collection.isActive).toList()
              ..sort(_compareMostRecentFirst);

        final items = featured
            .take(config.itemLimit)
            .map(_toItem)
            .toList(growable: false);

        return AppSuccess<CatalogHomeSection>(
          CatalogHomeSection(
            type: config.type,
            title: config.title,
            order: config.order,
            priority: config.priority,
            items: items,
          ),
        );
      },
      onFailure: (failure) => AppFailure<CatalogHomeSection>(failure),
    );
  }

  int _compareMostRecentFirst(Collection a, Collection b) {
    final aRank = a.startDate ?? _fallbackDate(a);
    final bRank = b.startDate ?? _fallbackDate(b);
    return bRank.compareTo(aRank);
  }

  DateTime _fallbackDate(Collection collection) {
    if (collection.year != null) {
      return DateTime.utc(collection.year!);
    }
    return collection.createdAt;
  }

  CatalogHomeItem _toItem(Collection collection) {
    return CatalogHomeItem(
      id: collection.id,
      title: collection.name,
      subtitle: collection.year?.toString(),
    );
  }
}
