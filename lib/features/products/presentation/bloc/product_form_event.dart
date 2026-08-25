import '../../domain/entities/product.dart';
import '../../domain/value_objects/product_gender.dart';
import '../../domain/value_objects/target_audience.dart';

/// Events for [ProductFormBloc] (TASK-065), grouped by the multi-section
/// form they drive — "eventos separados por seção", never one monolithic
/// event for the whole form.
sealed class ProductFormEvent {
  const ProductFormEvent();
}

final class ProductFormStarted extends ProductFormEvent {
  const ProductFormStarted({
    required this.organizationId,
    required this.companyId,
    required this.userId,
    required this.actorName,
    required this.canPublish,
    this.initialProduct,
  });

  final String organizationId;
  final String companyId;
  final String userId;
  final String actorName;

  /// Whether the caller holds `Capability.catalogManage` — gates
  /// [ProductFormPublishRequested], not create/edit access itself (that is
  /// already gated at the page level, before this bloc is even created).
  final bool canPublish;
  final Product? initialProduct;
}

/// "Básico": name, SKU, reference, brand.
final class ProductFormBasicSectionChanged extends ProductFormEvent {
  const ProductFormBasicSectionChanged({
    required this.name,
    required this.sku,
    required this.reference,
    required this.brand,
  });

  final String name;
  final String sku;
  final String reference;
  final String brand;
}

/// "Categoria": category/subcategory, collection, season, line, gender,
/// target audience.
final class ProductFormCategorySectionChanged extends ProductFormEvent {
  const ProductFormCategorySectionChanged({
    required this.categoryId,
    required this.subcategoryId,
    required this.collectionId,
    required this.seasonId,
    required this.line,
    required this.gender,
    required this.targetAudience,
  });

  final String categoryId;
  final String subcategoryId;
  final String collectionId;
  final String seasonId;
  final String line;
  final ProductGender? gender;
  final TargetAudience? targetAudience;
}

/// "Cores": reusable color palette ids associated to this product.
final class ProductFormColorsChanged extends ProductFormEvent {
  const ProductFormColorsChanged(this.colorIds);

  final List<String> colorIds;
}

/// "Grade": reusable size-grid template associated to this product.
final class ProductFormSizeGridTemplateChanged extends ProductFormEvent {
  const ProductFormSizeGridTemplateChanged(this.sizeGridTemplateId);

  final String sizeGridTemplateId;
}

/// "Conteúdo": short/full description and tags.
final class ProductFormContentSectionChanged extends ProductFormEvent {
  const ProductFormContentSectionChanged({
    required this.shortDescription,
    required this.fullDescription,
    required this.tags,
  });

  final String shortDescription;
  final String fullDescription;
  final List<String> tags;
}

/// "Características": fabric, composition, supplier, NCM, EAN.
final class ProductFormCharacteristicsSectionChanged extends ProductFormEvent {
  const ProductFormCharacteristicsSectionChanged({
    required this.fabric,
    required this.composition,
    required this.supplierId,
    required this.ncm,
    required this.ean,
  });

  final String fabric;
  final String composition;
  final String supplierId;
  final String ncm;
  final String ean;
}

/// "SEO": only meaningful once a shareable/white-label catalog reads it.
final class ProductFormSeoSectionChanged extends ProductFormEvent {
  const ProductFormSeoSectionChanged({
    required this.seoTitle,
    required this.seoDescription,
    required this.seoSlug,
  });

  final String seoTitle;
  final String seoDescription;
  final String seoSlug;
}

/// "Agendamento": future launch/publication date.
final class ProductFormScheduleSectionChanged extends ProductFormEvent {
  const ProductFormScheduleSectionChanged(this.launchDate);

  final DateTime? launchDate;
}

final class ProductFormDraftSaved extends ProductFormEvent {
  const ProductFormDraftSaved();
}

final class ProductFormSubmitted extends ProductFormEvent {
  const ProductFormSubmitted();
}

final class ProductFormPublishRequested extends ProductFormEvent {
  const ProductFormPublishRequested();
}
