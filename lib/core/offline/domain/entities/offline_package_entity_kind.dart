/// Every entity the offline package download (TASK-107, seção 5.1 de
/// `tasks.md`) can carry to the device.
///
/// Only a subset of these currently has a registered
/// `OfflinePackageEntityLoader` — see [DownloadOfflinePackageUseCase] and
/// `OfflineInjectionModule.offlinePackageEntityLoaders` for the up-to-date
/// list of which ones are actually wired today. The remaining values exist
/// so callers (status screens, the future Central de Sincronização —
/// TASK-112) can already talk about the full target scope from `tasks.md`
/// and clearly show "não disponível ainda" for entities whose own
/// feature-level Drift local store does not exist yet, instead of the type
/// silently growing every time a new loader is registered.
enum OfflinePackageEntityKind {
  customers,
  priceLists,
  paymentTerms,
  priceListItems,
  productVariants,
  stockBalances,
  campaigns,
  targets,
}

extension OfflinePackageEntityKindCode on OfflinePackageEntityKind {
  /// Stable identifier persisted in `OfflinePackageLoadStatusTable.entityKind`
  /// — never the enum index, so reordering [OfflinePackageEntityKind] can
  /// never silently change what an already-persisted row means.
  String get code {
    return switch (this) {
      OfflinePackageEntityKind.customers => 'customers',
      OfflinePackageEntityKind.priceLists => 'price_lists',
      OfflinePackageEntityKind.paymentTerms => 'payment_terms',
      OfflinePackageEntityKind.priceListItems => 'price_list_items',
      OfflinePackageEntityKind.productVariants => 'product_variants',
      OfflinePackageEntityKind.stockBalances => 'stock_balances',
      OfflinePackageEntityKind.campaigns => 'campaigns',
      OfflinePackageEntityKind.targets => 'targets',
    };
  }

  static OfflinePackageEntityKind? fromCode(String code) {
    for (final kind in OfflinePackageEntityKind.values) {
      if (kind.code == code) {
        return kind;
      }
    }
    return null;
  }
}
