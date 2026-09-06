/// Every `Product`/`ProductVariant` field a spreadsheet column can be mapped
/// to during a product import (TASK-168, EPIC-22) — a closed set, mirroring
/// `CustomerImportField` (TASK-167): a gestor maps a column to one of these,
/// never to an arbitrary free-text key, so both the client mapping step and
/// the `processProductImportJob` Cloud Function agree on exactly what each
/// mapped column means.
///
/// One spreadsheet row always describes exactly one product+color+size
/// variant (`tasks.md`'s "uma linha por variante" shape) — a product with a
/// full size grid appears as several rows sharing the same [sku]/
/// [reference]/[name]/... but a different [color]/[size].
///
/// [ignored] is not a `Product`/`ProductVariant` field: it marks a column the
/// gestor chose not to import.
enum ProductImportField {
  sku,
  reference,
  name,
  shortDescription,
  brand,
  categoryName,
  subcategoryName,
  collectionName,
  colorName,
  sizeLabel,
  basePrice,
  barcode,
  ignored,
}

extension ProductImportFieldCode on ProductImportField {
  /// Stable identifier persisted in `ProductImportMapping`/
  /// `ProductImportTemplate` (Firestore) and sent to the
  /// `startProductImportJob` Cloud Function — never the enum index.
  String get code {
    return switch (this) {
      ProductImportField.sku => 'sku',
      ProductImportField.reference => 'reference',
      ProductImportField.name => 'name',
      ProductImportField.shortDescription => 'shortDescription',
      ProductImportField.brand => 'brand',
      ProductImportField.categoryName => 'categoryName',
      ProductImportField.subcategoryName => 'subcategoryName',
      ProductImportField.collectionName => 'collectionName',
      ProductImportField.colorName => 'colorName',
      ProductImportField.sizeLabel => 'sizeLabel',
      ProductImportField.basePrice => 'basePrice',
      ProductImportField.barcode => 'barcode',
      ProductImportField.ignored => 'ignored',
    };
  }

  /// Portuguese label shown in the column-mapping step
  /// (`ProductImportMappingStep`).
  String get label {
    return switch (this) {
      ProductImportField.sku => 'SKU',
      ProductImportField.reference => 'Referência',
      ProductImportField.name => 'Nome do produto',
      ProductImportField.shortDescription => 'Descrição',
      ProductImportField.brand => 'Marca',
      ProductImportField.categoryName => 'Categoria',
      ProductImportField.subcategoryName => 'Subcategoria',
      ProductImportField.collectionName => 'Coleção',
      ProductImportField.colorName => 'Cor',
      ProductImportField.sizeLabel => 'Tamanho',
      ProductImportField.basePrice => 'Preço base',
      ProductImportField.barcode => 'Código de barras (EAN)',
      ProductImportField.ignored => 'Não importar',
    };
  }

  static ProductImportField? fromCode(String code) {
    for (final field in ProductImportField.values) {
      if (field.code == code) return field;
    }
    return null;
  }
}

/// Every [ProductImportField] a mapping must assign to a column before an
/// import can start — enforced by `validateProductImportMapping`. [sku],
/// [reference], [name], [colorName] and [sizeLabel] are always required:
/// `Product.sku`/`Product.reference`/`Product.name` are non-nullable, and a
/// sellable `ProductVariant` never exists without a color and a size
/// (TASK-072). Category, collection, price and barcode are optional per
/// `tasks.md`'s business rules for this task ("preço só é importado quando a
/// planilha o fornece").
const Set<ProductImportField> kRequiredProductImportFields =
    <ProductImportField>{
      ProductImportField.sku,
      ProductImportField.reference,
      ProductImportField.name,
      ProductImportField.colorName,
      ProductImportField.sizeLabel,
    };
