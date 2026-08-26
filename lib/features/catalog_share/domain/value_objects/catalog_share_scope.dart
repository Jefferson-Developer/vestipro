/// What a [CatalogShare]'s items represent (TASK-081, EPIC-10): a single
/// product, a hand-picked selection of products, or every product in a
/// collection — mirrors `functions/src/catalog/catalog-share-shared.ts`'s
/// `CatalogShareScope` exactly.
enum CatalogShareScope {
  /// Exactly one product (`CatalogShare.items` has length 1).
  product,

  /// A hand-picked, multi-product selection.
  selection,

  /// Every product in a named collection at the moment the share was
  /// created (`CatalogShare.collectionId`/`collectionName`).
  collection,
}

extension CatalogShareScopeCode on CatalogShareScope {
  /// The literal value `createCatalogShareLink`/`getCatalogShareLink` send
  /// and return, matching `CatalogShareScope` in
  /// `functions/src/catalog/catalog-share-shared.ts` exactly.
  String get code {
    return switch (this) {
      CatalogShareScope.product => 'product',
      CatalogShareScope.selection => 'selection',
      CatalogShareScope.collection => 'collection',
    };
  }
}

/// Parses a raw scope code back into a [CatalogShareScope], or `null` for
/// anything unrecognized — same "caller decides how to handle an unknown
/// value" precedent as `inviteStatusFromCode`/`inviteAcceptanceOutcomeFromCode`.
CatalogShareScope? catalogShareScopeFromCode(String code) {
  for (final scope in CatalogShareScope.values) {
    if (scope.code == code) return scope;
  }
  return null;
}
