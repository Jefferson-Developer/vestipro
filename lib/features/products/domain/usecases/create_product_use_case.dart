import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product.dart';
import '../entities/product_custom_field_value.dart';
import '../repositories/product_repository.dart';
import '../value_objects/ean.dart';
import '../value_objects/product_gender.dart';
import '../value_objects/product_status.dart';
import '../value_objects/product_sync_status.dart';
import '../value_objects/sku.dart';
import '../value_objects/target_audience.dart';
import 'product_use_case_helpers.dart';

/// Creates a new Product (TASK-065), always as [ProductStatus.draft].
///
/// Publishing (transitioning to [ProductStatus.active]) is a dedicated,
/// separate step (`PublishProductUseCase`), never something this use case
/// accepts a `status` argument for — "rascunho pode ser salvo com campos
/// incompletos; publicação é bloqueada até completude" (the task's business
/// rule) is easiest to guarantee by construction when creation can only ever
/// produce a draft.
@injectable
final class CreateProductUseCase {
  CreateProductUseCase(this._repository);

  final ProductRepository _repository;

  Future<AppResult<Product>> call({
    required String id,
    required String organizationId,
    String? companyId,
    required String sku,
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
    String? ean,
    List<String> tags = const <String>[],
    List<String> colorIds = const <String>[],
    String? sizeGridTemplateId,
    DateTime? launchDate,
    String? seoTitle,
    String? seoDescription,
    String? seoSlug,
    List<ProductCustomFieldValue> customFieldValues =
        const <ProductCustomFieldValue>[],
    required String createdBy,
  }) async {
    final trimmedId = id.trim();
    final trimmedOrganizationId = organizationId.trim();
    final trimmedReference = reference.trim();
    final trimmedName = name.trim();
    final trimmedCreatedBy = createdBy.trim();
    final fieldErrors = <String, String>{};

    if (trimmedId.isEmpty) fieldErrors['id'] = 'Id is required.';
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedReference.isEmpty) {
      fieldErrors['reference'] = 'Informe a referência do produto.';
    }
    if (trimmedName.isEmpty) {
      fieldErrors['name'] = 'Informe o nome do produto.';
    }
    if (trimmedCreatedBy.isEmpty) {
      fieldErrors['createdBy'] = 'CreatedBy is required.';
    }

    Sku? parsedSku;
    try {
      parsedSku = Sku.parse(sku);
    } on ValidationException catch (exception) {
      fieldErrors.addAll(
        exception.fieldErrors.isEmpty
            ? <String, String>{'sku': exception.message}
            : exception.fieldErrors,
      );
    }

    Ean? parsedEan;
    final trimmedEan = ean?.trim();
    if (trimmedEan != null && trimmedEan.isNotEmpty) {
      try {
        parsedEan = Ean.parse(trimmedEan);
      } on ValidationException catch (exception) {
        fieldErrors.addAll(
          exception.fieldErrors.isEmpty
              ? <String, String>{'ean': exception.message}
              : exception.fieldErrors,
        );
      }
    }

    if (fieldErrors.isNotEmpty || parsedSku == null) {
      return AppFailure<Product>(
        ValidationFailure(
          'Invalid product creation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_create_payload',
        ),
      );
    }

    final duplicateResult = await _repository.existsBySku(
      organizationId: trimmedOrganizationId,
      sku: parsedSku,
    );
    if (duplicateResult is AppFailure<bool>) {
      return AppFailure<Product>(duplicateResult.failure);
    }
    if ((duplicateResult as AppSuccess<bool>).value) {
      return AppFailure<Product>(
        const ConflictFailure(
          'Product SKU already exists in this organization.',
          code: 'product_sku_already_exists',
        ),
      );
    }

    final now = DateTime.now().toUtc();
    final product = Product(
      id: trimmedId,
      organizationId: trimmedOrganizationId,
      companyId: normalizeProductOptional(companyId),
      sku: parsedSku,
      reference: trimmedReference,
      name: trimmedName,
      shortDescription: normalizeProductOptional(shortDescription),
      fullDescription: normalizeProductOptional(fullDescription),
      brand: normalizeProductOptional(brand),
      collectionId: normalizeProductOptional(collectionId),
      seasonId: normalizeProductOptional(seasonId),
      line: normalizeProductOptional(line),
      categoryId: normalizeProductOptional(categoryId),
      subcategoryId: normalizeProductOptional(subcategoryId),
      gender: gender,
      targetAudience: targetAudience,
      fabric: normalizeProductOptional(fabric),
      composition: normalizeProductOptional(composition),
      supplierId: normalizeProductOptional(supplierId),
      ncm: normalizeProductOptional(ncm),
      ean: parsedEan,
      tags: normalizeProductTags(tags),
      colorIds: _normalizeIds(colorIds),
      sizeGridTemplateId: normalizeProductOptional(sizeGridTemplateId),
      status: ProductStatus.draft,
      launchDate: launchDate?.toUtc(),
      seoTitle: normalizeProductOptional(seoTitle),
      seoDescription: normalizeProductOptional(seoDescription),
      seoSlug: normalizeProductOptional(seoSlug),
      customFieldValues: customFieldValues,
      createdAt: now,
      createdBy: trimmedCreatedBy,
      updatedAt: now,
      updatedBy: trimmedCreatedBy,
      version: 1,
      syncStatus: ProductSyncStatus.pending,
    );

    return _repository.create(product: product);
  }
}

List<String> _normalizeIds(List<String> values) => values
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toSet()
    .toList(growable: false);
