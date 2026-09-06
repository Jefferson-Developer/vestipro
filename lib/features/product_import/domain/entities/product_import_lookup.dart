import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_import_lookup.freezed.dart';

/// Name-to-id lookup tables resolved **client-side**, right before a
/// `ProductImportJob` starts, from the organization's own local `Category`/
/// `Collection`/`ProductColor` catalogs (TASK-067/TASK-066/TASK-070) — never
/// resolved by the Cloud Function itself.
///
/// This exists because Category/Collection/ProductColor (unlike
/// `ProductVariant`) have no remote/Firestore-backed store yet
/// (`SharedPreferencesCategoryRepository`/`SharedPreferencesCollectionRepository`/
/// `SharedPreferencesProductColorRepository` — a pre-existing architectural
/// gap, documented in `TASK-168-...-CONCLUIDA.md`, not introduced by this
/// task): a server-side Cloud Function has no way to look up "categoria
/// Camisaria" by name, since that catalog lives only in the requesting
/// device's local storage. So the device that starts the import resolves
/// every distinct name found in the file's preview against its own local
/// catalog first, and sends only the resulting ids — the server then only
/// ever trusts an id it can look up in a lookup table it was explicitly
/// given, never a name it would have to invent meaning for. A spreadsheet
/// name absent from these maps is always rejected (or, for
/// [categoryIdByName]/[collectionIdByName], created client-side first when
/// the gestor opts into "criar automaticamente" — `tasks.md`), never
/// silently guessed.
///
/// Keys are normalized (trimmed, lower-cased) so "Camisaria"/"camisaria "
/// both resolve to the same id.
@freezed
abstract class ProductImportLookup with _$ProductImportLookup {
  const factory ProductImportLookup({
    @Default(<String, String>{}) Map<String, String> categoryIdByName,
    @Default(<String, String>{}) Map<String, String> collectionIdByName,

    /// Never auto-created (`tasks.md` only allows create-or-reject for
    /// categoria/coleção, not for cor) — a color name missing here always
    /// rejects the row.
    @Default(<String, String>{}) Map<String, String> colorIdByName,

    /// Every `SizeGridSize.label` (normalized) -> id of the single
    /// `SizeGridTemplate` selected for this import run
    /// (`ProductImportMapping.sizeGridTemplateId`) — sent for the exact same
    /// reason as the maps above: `SizeGridTemplate` also has no
    /// remote/Firestore-backed store yet
    /// (`SharedPreferencesSizeGridTemplateRepository`), so
    /// `processProductImportJob` has no way to look up "P"/"38" against the
    /// chosen grid's sizes itself. A `sizeLabel` cell absent from this map
    /// always rejects the row ("grade de tamanho inexistente") — never
    /// inferred.
    @Default(<String, String>{}) Map<String, String> sizeIdByLabel,
  }) = _ProductImportLookup;
}
