import '../value_objects/catalog_filter_key.dart';
import '../value_objects/variant_availability_status.dart';
import 'product.dart';

/// The set of catalog filter dimensions a representative can combine while
/// browsing the catalog (TASK-082, EPIC-10): coleção, estação, marca,
/// categoria, cor, tamanho, disponibilidade, lançamento, tags e
/// material/tecido.
///
/// Lives in `features/products/domain` (not `features/catalog/domain`)
/// because it is fundamentally a filter over [Product] fields, consumed
/// directly by `ProductRepository.listCatalog` — keeping the existing
/// dependency direction (`catalog` depends on `products`, never the other
/// way around) that every other catalog use case (e.g.
/// `ListCatalogProductsUseCase`) already follows.
///
/// **Faixa de preço is intentionally not modeled here.** The specification
/// requires it to "respeitar a tabela de preço vigente do usuário/empresa
/// ativa" — but no `PriceList`/pricing-engine exists yet in VestiPro
/// (EPIC-11, `docs/tasks/TASK-083` onward, still pending in the backlog).
/// Adding `priceMin`/`priceMax` fields with no price data anywhere to
/// compare against would either silently do nothing (misleading) or be
/// faked client-side (forbidden by this very task's business rules, which
/// explicitly ban client-inferred filtering). Deferred until EPIC-11 lands;
/// tracked as a pending item in TASK-082's completion doc, never silently
/// dropped.
///
/// [matches] only ever inspects fields that live directly on [Product] —
/// [availability] and [size] filtering need data from other repositories
/// (`VariantAvailabilityRepository`/`SizeGridTemplateRepository`) and are
/// therefore applied by the caller (`CatalogFilterBloc`) after the page is
/// fetched, never by this method or by `ProductRepository` itself.
final class CatalogFilter {
  const CatalogFilter({
    this.collectionId,
    this.seasonId,
    this.brand,
    this.categoryId,
    this.colorIds = const <String>{},
    this.sizes = const <String>{},
    this.availability,
    this.launchOnly = false,
    this.tags = const <String>{},
    this.material,
  });

  final String? collectionId;
  final String? seasonId;
  final String? brand;
  final String? categoryId;

  /// Matches a `Product` whose `colorIds` contains *any* of these.
  final Set<String> colorIds;

  /// Size labels (e.g. `{"P", "M"}`), matched case-insensitively against the
  /// `SizeGridSize.label`s of the product's size grid template — see
  /// [matches]'s doc for why this is never checked here.
  final Set<String> sizes;

  /// Real stock signal (`VariantAvailabilityRepository`), never inferred —
  /// see [matches]'s doc for why this is never checked here.
  final VariantAvailabilityStatus? availability;

  /// "Lançamento": only products with a `launchDate` set.
  final bool launchOnly;

  /// Matches a `Product` whose `tags` contains *any* of these.
  final Set<String> tags;

  /// Free-text match against `Product.fabric` (case-insensitive, substring).
  final String? material;

  static const empty = CatalogFilter();

  bool get isEmpty => this == const CatalogFilter();

  int get activeCount =>
      (collectionId != null && collectionId!.isNotEmpty ? 1 : 0) +
      (seasonId != null && seasonId!.isNotEmpty ? 1 : 0) +
      (brand != null && brand!.isNotEmpty ? 1 : 0) +
      (categoryId != null && categoryId!.isNotEmpty ? 1 : 0) +
      colorIds.length +
      sizes.length +
      (availability != null ? 1 : 0) +
      (launchOnly ? 1 : 0) +
      tags.length +
      (material != null && material!.isNotEmpty ? 1 : 0);

  CatalogFilter normalized() {
    return CatalogFilter(
      collectionId: _trimmedOrNull(collectionId),
      seasonId: _trimmedOrNull(seasonId),
      brand: _trimmedOrNull(brand),
      categoryId: _trimmedOrNull(categoryId),
      colorIds: Set<String>.unmodifiable(
        colorIds.map((id) => id.trim()).where((id) => id.isNotEmpty),
      ),
      sizes: Set<String>.unmodifiable(
        sizes.map((size) => size.trim()).where((size) => size.isNotEmpty),
      ),
      availability: availability,
      launchOnly: launchOnly,
      tags: Set<String>.unmodifiable(
        tags.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty),
      ),
      material: _trimmedOrNull(material),
    );
  }

  CatalogFilter copyWith({
    String? collectionId,
    bool clearCollectionId = false,
    String? seasonId,
    bool clearSeasonId = false,
    String? brand,
    bool clearBrand = false,
    String? categoryId,
    bool clearCategoryId = false,
    Set<String>? colorIds,
    Set<String>? sizes,
    VariantAvailabilityStatus? availability,
    bool clearAvailability = false,
    bool? launchOnly,
    Set<String>? tags,
    String? material,
    bool clearMaterial = false,
  }) {
    return CatalogFilter(
      collectionId: clearCollectionId
          ? null
          : (collectionId ?? this.collectionId),
      seasonId: clearSeasonId ? null : (seasonId ?? this.seasonId),
      brand: clearBrand ? null : (brand ?? this.brand),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      colorIds: colorIds ?? this.colorIds,
      sizes: sizes ?? this.sizes,
      availability: clearAvailability
          ? null
          : (availability ?? this.availability),
      launchOnly: launchOnly ?? this.launchOnly,
      tags: tags ?? this.tags,
      material: clearMaterial ? null : (material ?? this.material),
    ).normalized();
  }

  /// Removes a single active filter chip, identified by [key] — for a
  /// set-valued dimension ([CatalogFilterKey.color]/[size]/[tag]), [value]
  /// selects which one to drop; every other dimension ignores [value] and
  /// clears entirely.
  CatalogFilter removing(CatalogFilterKey key, {String? value}) {
    return switch (key) {
      CatalogFilterKey.collection => copyWith(clearCollectionId: true),
      CatalogFilterKey.season => copyWith(clearSeasonId: true),
      CatalogFilterKey.brand => copyWith(clearBrand: true),
      CatalogFilterKey.category => copyWith(clearCategoryId: true),
      CatalogFilterKey.color => copyWith(
        colorIds: colorIds.where((id) => id != value).toSet(),
      ),
      CatalogFilterKey.size => copyWith(
        sizes: sizes.where((size) => size != value).toSet(),
      ),
      CatalogFilterKey.availability => copyWith(clearAvailability: true),
      CatalogFilterKey.launch => copyWith(launchOnly: false),
      CatalogFilterKey.tag => copyWith(
        tags: tags.where((tag) => tag != value).toSet(),
      ),
      CatalogFilterKey.material => copyWith(clearMaterial: true),
    };
  }

  /// Every active filter chip currently set, as `(key, rawValue)` pairs —
  /// presentation resolves the human-readable label (e.g. a collection
  /// name from its id) since this entity carries no reference vocabulary.
  List<(CatalogFilterKey key, String value)> activeEntries() {
    return <(CatalogFilterKey, String)>[
      if (collectionId != null && collectionId!.isNotEmpty)
        (CatalogFilterKey.collection, collectionId!),
      if (seasonId != null && seasonId!.isNotEmpty)
        (CatalogFilterKey.season, seasonId!),
      if (brand != null && brand!.isNotEmpty) (CatalogFilterKey.brand, brand!),
      if (categoryId != null && categoryId!.isNotEmpty)
        (CatalogFilterKey.category, categoryId!),
      for (final colorId in colorIds) (CatalogFilterKey.color, colorId),
      for (final size in sizes) (CatalogFilterKey.size, size),
      if (availability != null)
        (CatalogFilterKey.availability, availability!.name),
      if (launchOnly) (CatalogFilterKey.launch, 'launch'),
      for (final tag in tags) (CatalogFilterKey.tag, tag),
      if (material != null && material!.isNotEmpty)
        (CatalogFilterKey.material, material!),
    ];
  }

  /// Whether [product] satisfies every dimension checkable from [Product]
  /// alone — see this class's doc for why [availability]/[sizes] are
  /// excluded here.
  bool matches(Product product) {
    if (collectionId != null && product.collectionId != collectionId) {
      return false;
    }
    if (seasonId != null && product.seasonId != seasonId) return false;
    if (brand != null &&
        (product.brand == null ||
            product.brand!.trim().toLowerCase() != brand!.toLowerCase())) {
      return false;
    }
    if (categoryId != null &&
        product.categoryId != categoryId &&
        product.subcategoryId != categoryId) {
      return false;
    }
    if (colorIds.isNotEmpty &&
        !product.colorIds.any((id) => colorIds.contains(id))) {
      return false;
    }
    if (tags.isNotEmpty && !product.tags.any((tag) => tags.contains(tag))) {
      return false;
    }
    if (material != null &&
        (product.fabric == null ||
            !product.fabric!.toLowerCase().contains(material!.toLowerCase()))) {
      return false;
    }
    if (launchOnly && product.launchDate == null) return false;
    return true;
  }

  static const _collectionKey = 'collectionId';
  static const _seasonKey = 'seasonId';
  static const _brandKey = 'brand';
  static const _categoryKey = 'categoryId';
  static const _colorsKey = 'colors';
  static const _sizesKey = 'sizes';
  static const _availabilityKey = 'availability';
  static const _launchKey = 'launch';
  static const _tagsKey = 'tags';
  static const _materialKey = 'material';

  Map<String, String> toQueryParameters() {
    return <String, String>{
      if (collectionId != null && collectionId!.isNotEmpty)
        _collectionKey: collectionId!,
      if (seasonId != null && seasonId!.isNotEmpty) _seasonKey: seasonId!,
      if (brand != null && brand!.isNotEmpty) _brandKey: brand!,
      if (categoryId != null && categoryId!.isNotEmpty)
        _categoryKey: categoryId!,
      if (colorIds.isNotEmpty) _colorsKey: colorIds.join(','),
      if (sizes.isNotEmpty) _sizesKey: sizes.join(','),
      if (availability != null) _availabilityKey: availability!.name,
      if (launchOnly) _launchKey: '1',
      if (tags.isNotEmpty) _tagsKey: tags.join(','),
      if (material != null && material!.isNotEmpty) _materialKey: material!,
    };
  }

  static CatalogFilter fromQueryParameters(Map<String, String> query) {
    return CatalogFilter(
      collectionId: query[_collectionKey],
      seasonId: query[_seasonKey],
      brand: query[_brandKey],
      categoryId: query[_categoryKey],
      colorIds: _csvSet(query[_colorsKey]),
      sizes: _csvSet(query[_sizesKey]),
      availability: _availabilityFromCode(query[_availabilityKey]),
      launchOnly: query[_launchKey] == '1',
      tags: _csvSet(query[_tagsKey]),
      material: query[_materialKey],
    ).normalized();
  }

  static Set<String> _csvSet(String? value) {
    if (value == null || value.trim().isEmpty) return const <String>{};
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  static VariantAvailabilityStatus? _availabilityFromCode(String? code) {
    if (code == null) return null;
    for (final status in VariantAvailabilityStatus.values) {
      if (status.name == code) return status;
    }
    return null;
  }

  static String? _trimmedOrNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogFilter &&
        other.collectionId == collectionId &&
        other.seasonId == seasonId &&
        other.brand == brand &&
        other.categoryId == categoryId &&
        _setEquals(other.colorIds, colorIds) &&
        _setEquals(other.sizes, sizes) &&
        other.availability == availability &&
        other.launchOnly == launchOnly &&
        _setEquals(other.tags, tags) &&
        other.material == material;
  }

  @override
  int get hashCode => Object.hash(
    collectionId,
    seasonId,
    brand,
    categoryId,
    Object.hashAllUnordered(colorIds),
    Object.hashAllUnordered(sizes),
    availability,
    launchOnly,
    Object.hashAllUnordered(tags),
    material,
  );

  static bool _setEquals<T>(Set<T> first, Set<T> second) {
    return first.length == second.length && first.containsAll(second);
  }
}
