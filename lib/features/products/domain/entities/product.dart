import 'package:freezed_annotation/freezed_annotation.dart';

import '../value_objects/ean.dart';
import '../value_objects/product_gender.dart';
import '../value_objects/product_status.dart';
import '../value_objects/product_sync_status.dart';
import '../value_objects/sku.dart';
import '../value_objects/target_audience.dart';
import 'product_custom_field_value.dart';

part 'product.freezed.dart';

/// Product catalog entry for EPIC-08.
///
/// The tenant field [organizationId] is immutable after creation and must be
/// resolved from the authenticated session/active organization context,
/// never from a form field. [companyId] is optional because some
/// organizations share a single catalog across companies.
///
/// [ean] may be absent: a product can carry its barcode on the color/size
/// variant instead of at the product level (see TASK-064 business rules).
/// The completeness rule for [ProductStatus.active] (name, SKU and category
/// minimally filled) is enforced by `PublishProductUseCase` (TASK-065), never
/// by this entity or by UI widgets.
///
/// [seoTitle]/[seoDescription]/[seoSlug] (TASK-065) are optional and only
/// meaningful once a shareable/white-label catalog (EPIC-25) reads them —
/// they carry no completeness requirement of their own.
@freezed
abstract class Product with _$Product {
  const Product._();

  const factory Product({
    required String id,
    required String organizationId,
    String? companyId,
    required Sku sku,
    required String reference,
    required String name,
    String? shortDescription,
    String? fullDescription,
    String? brand,
    String? collectionId,
    String? seasonId,
    String? line,
    String? categoryId,
    String? subcategoryId,
    ProductGender? gender,
    TargetAudience? targetAudience,
    String? fabric,
    String? composition,
    String? supplierId,
    String? ncm,
    Ean? ean,
    @Default(<String>[]) List<String> tags,
    required ProductStatus status,
    DateTime? launchDate,
    String? seoTitle,
    String? seoDescription,
    String? seoSlug,
    @Default(<String>[]) List<String> photoUrls,
    @Default(<String>[]) List<String> videoUrls,
    @Default(<ProductCustomFieldValue>[])
    List<ProductCustomFieldValue> customFieldValues,
    required DateTime createdAt,
    required String createdBy,
    required DateTime updatedAt,
    required String updatedBy,
    DateTime? deletedAt,
    required int version,
    required ProductSyncStatus syncStatus,
  }) = _Product;
}
