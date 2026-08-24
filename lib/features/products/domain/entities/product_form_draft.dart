/// Persisted local draft for an unfinished product form (TASK-065).
///
/// Every field mirrors one editable section of `ProductFormPage`, kept as
/// raw strings (never [Sku]/[Ean] value objects): a draft is explicitly
/// allowed to be incomplete or malformed while the user is still typing —
/// parsing/validation only happens when the form is actually submitted
/// (`CreateProductUseCase`/`UpdateProductUseCase`) or published
/// (`PublishProductUseCase`), never here.
final class ProductFormDraft {
  const ProductFormDraft({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    this.productId,
    this.name,
    this.sku,
    this.reference,
    this.brand,
    this.categoryId,
    this.subcategoryId,
    this.collectionId,
    this.seasonId,
    this.line,
    this.gender,
    this.targetAudience,
    this.shortDescription,
    this.fullDescription,
    this.tags = const <String>[],
    this.fabric,
    this.composition,
    this.supplierId,
    this.ncm,
    this.ean,
    this.seoTitle,
    this.seoDescription,
    this.seoSlug,
    this.launchDate,
    required this.savedAt,
  });

  final String organizationId;
  final String companyId;
  final String userId;

  /// Set only while editing an already-created Product — `null` while
  /// drafting a brand-new one, so `ProductFormBloc` never confuses a resumed
  /// "new product" draft with a resumed "edit" draft for a different id.
  final String? productId;
  final String? name;
  final String? sku;
  final String? reference;
  final String? brand;
  final String? categoryId;
  final String? subcategoryId;
  final String? collectionId;
  final String? seasonId;
  final String? line;
  final String? gender;
  final String? targetAudience;
  final String? shortDescription;
  final String? fullDescription;
  final List<String> tags;
  final String? fabric;
  final String? composition;
  final String? supplierId;
  final String? ncm;
  final String? ean;
  final String? seoTitle;
  final String? seoDescription;
  final String? seoSlug;
  final DateTime? launchDate;
  final DateTime savedAt;
}
