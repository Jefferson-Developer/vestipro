import 'package:injectable/injectable.dart';

import '../core/offline/domain/offline_package_entity_loader.dart';
import '../features/customers/domain/services/customer_offline_package_entity_loader.dart';
import '../features/pricing/domain/services/payment_term_offline_package_entity_loader.dart';
import '../features/pricing/domain/services/price_list_offline_package_entity_loader.dart';

/// Registers every [OfflinePackageEntityLoader] implementation
/// `DownloadOfflinePackageUseCase` (TASK-107) orchestrates.
///
/// This lives in `lib/app/` — the composition root — rather than inside
/// `lib/core/offline/`, because `core` must never depend on `features`
/// (see `AGENTS.md`/`flutter-senior-architect`): only the app-level wiring
/// layer is allowed to know about every feature's concrete loader at once.
///
/// To add a new entity to the offline package once its feature has a
/// Drift-backed local store and an `OfflinePackageEntityLoader`
/// implementation, add it to the list below — nothing in `core/offline`
/// needs to change.
@module
abstract class OfflinePackageLoadersModule {
  @lazySingleton
  List<OfflinePackageEntityLoader> offlinePackageEntityLoaders(
    CustomerOfflinePackageEntityLoader customers,
    PriceListOfflinePackageEntityLoader priceLists,
    PaymentTermOfflinePackageEntityLoader paymentTerms,
  ) {
    return List<OfflinePackageEntityLoader>.unmodifiable(
      <OfflinePackageEntityLoader>[customers, priceLists, paymentTerms],
    );
  }
}
