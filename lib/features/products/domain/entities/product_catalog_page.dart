import 'package:freezed_annotation/freezed_annotation.dart';

import 'product.dart';

part 'product_catalog_page.freezed.dart';

/// One cursor-paginated page of the full product catalog (TASK-077),
/// returned by `ProductRepository.listCatalog`.
///
/// Cursor-based (never offset/page-number based) so a caller can keep
/// appending pages to an already-rendered list — `AppProductGrid`'s
/// "carregar mais" control — without ever needing to know a total count, and
/// without shifting results when items are added/removed between page
/// fetches, the same reasoning `AppPagination`'s own docs give for
/// [AppPaginationMode.loadMore].
///
/// [nextCursor] is only meaningful when [hasMore] is `true`; it is `null`
/// once the last page has been returned.
@freezed
abstract class ProductCatalogPage with _$ProductCatalogPage {
  const factory ProductCatalogPage({
    required List<Product> products,
    required bool hasMore,
    String? nextCursor,
  }) = _ProductCatalogPage;
}
