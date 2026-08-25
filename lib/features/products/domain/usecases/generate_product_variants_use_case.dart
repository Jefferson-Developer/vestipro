import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/product.dart';
import '../entities/product_color.dart';
import '../entities/product_variant.dart';
import '../entities/size_grid_template.dart';
import '../repositories/product_color_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/product_variant_repository.dart';
import '../repositories/size_grid_template_repository.dart';
import '../value_objects/product_sync_status.dart';
import '../value_objects/product_variant_status.dart';
import '../value_objects/sku.dart';

@injectable
final class GenerateProductVariantsUseCase {
  GenerateProductVariantsUseCase(
    this._productRepository,
    this._colorRepository,
    this._sizeGridTemplateRepository,
    this._variantRepository,
  );

  final ProductRepository _productRepository;
  final ProductColorRepository _colorRepository;
  final SizeGridTemplateRepository _sizeGridTemplateRepository;
  final ProductVariantRepository _variantRepository;
  final Uuid _uuid = const Uuid();

  Future<AppResult<List<ProductVariant>>> call({
    required String organizationId,
    required String productId,
    required String generatedBy,
  }) async {
    final trimmedOrganizationId = organizationId.trim();
    final trimmedProductId = productId.trim();
    final fieldErrors = <String, String>{};
    if (trimmedOrganizationId.isEmpty) {
      fieldErrors['organizationId'] = 'OrganizationId is required.';
    }
    if (trimmedProductId.isEmpty) {
      fieldErrors['productId'] = 'ProductId is required.';
    }
    if (generatedBy.trim().isEmpty) {
      fieldErrors['generatedBy'] = 'GeneratedBy is required.';
    }
    if (fieldErrors.isNotEmpty) {
      return AppFailure<List<ProductVariant>>(
        ValidationFailure(
          'Invalid product variant generation payload.',
          fieldErrors: fieldErrors,
          code: 'invalid_product_variant_generation_payload',
        ),
      );
    }

    final productResult = await _productRepository.getById(
      organizationId: trimmedOrganizationId,
      id: trimmedProductId,
    );
    if (productResult is AppFailure<Product>) {
      return AppFailure<List<ProductVariant>>(productResult.failure);
    }
    final product = (productResult as AppSuccess<Product>).value;

    final templateId = product.sizeGridTemplateId?.trim();
    if (product.colorIds.isEmpty || templateId == null || templateId.isEmpty) {
      return const AppFailure<List<ProductVariant>>(
        ValidationFailure(
          'Product needs colors and a size grid template to generate variants.',
          fieldErrors: <String, String>{
            'colorIds': 'Associe ao menos uma cor ao produto.',
            'sizeGridTemplateId': 'Associe um template de grade ao produto.',
          },
          code: 'product_variant_generation_missing_matrix',
        ),
      );
    }

    final colors = <ProductColor>[];
    for (final colorId in product.colorIds) {
      final colorResult = await _colorRepository.getById(
        organizationId: trimmedOrganizationId,
        id: colorId,
      );
      if (colorResult is AppFailure<ProductColor>) {
        return AppFailure<List<ProductVariant>>(colorResult.failure);
      }
      colors.add((colorResult as AppSuccess<ProductColor>).value);
    }

    final templateResult = await _sizeGridTemplateRepository.getById(
      organizationId: trimmedOrganizationId,
      id: templateId,
    );
    if (templateResult is AppFailure<SizeGridTemplate>) {
      return AppFailure<List<ProductVariant>>(templateResult.failure);
    }
    final template = (templateResult as AppSuccess<SizeGridTemplate>).value;

    final existingResult = await _variantRepository.listByProduct(
      organizationId: trimmedOrganizationId,
      productId: trimmedProductId,
    );
    if (existingResult is AppFailure<List<ProductVariant>>) {
      return existingResult;
    }
    final existing = (existingResult as AppSuccess<List<ProductVariant>>).value;
    final byCombination = <String, ProductVariant>{
      for (final variant in existing) variant.combinationKey: variant,
    };
    final desiredKeys = <String>{};
    final generatedOrUpdated = <ProductVariant>[];

    for (final color in colors) {
      for (final size in template.orderedSizes) {
        final key = '${product.id}|${color.id}|${size.id}';
        desiredKeys.add(key);
        final current = byCombination[key];
        if (current != null) {
          if (!current.isActive) {
            final reactivated = current.copyWith(
              status: ProductVariantStatus.active,
              updatedAt: DateTime.now().toUtc(),
              updatedBy: generatedBy.trim(),
              version: current.version + 1,
              syncStatus: ProductSyncStatus.pending,
            );
            final updatedResult = await _variantRepository.update(
              variant: reactivated,
            );
            if (updatedResult is AppFailure<ProductVariant>) {
              return AppFailure<List<ProductVariant>>(updatedResult.failure);
            }
            generatedOrUpdated.add(
              (updatedResult as AppSuccess<ProductVariant>).value,
            );
          } else {
            generatedOrUpdated.add(current);
          }
          continue;
        }

        final sku = _deriveSku(product: product, color: color, size: size);
        final skuExists = await _variantRepository.existsBySku(
          organizationId: trimmedOrganizationId,
          sku: sku,
        );
        if (skuExists is AppFailure<bool>) {
          return AppFailure<List<ProductVariant>>(skuExists.failure);
        }
        if ((skuExists as AppSuccess<bool>).value) {
          return AppFailure<List<ProductVariant>>(
            ConflictFailure(
              'Product variant SKU already exists in this organization.',
              code: 'product_variant_sku_already_exists',
              cause: sku.value,
            ),
          );
        }

        final now = DateTime.now().toUtc();
        final variant = ProductVariant(
          id: _uuid.v4(),
          organizationId: trimmedOrganizationId,
          productId: product.id,
          colorId: color.id,
          sizeGridTemplateId: template.id,
          sizeId: size.id,
          sku: sku,
          status: ProductVariantStatus.active,
          createdAt: now,
          createdBy: generatedBy.trim(),
          updatedAt: now,
          updatedBy: generatedBy.trim(),
          version: 1,
          syncStatus: ProductSyncStatus.pending,
        );
        final createdResult = await _variantRepository.create(variant: variant);
        if (createdResult is AppFailure<ProductVariant>) {
          return AppFailure<List<ProductVariant>>(createdResult.failure);
        }
        generatedOrUpdated.add(
          (createdResult as AppSuccess<ProductVariant>).value,
        );
      }
    }

    for (final variant in existing) {
      if (desiredKeys.contains(variant.combinationKey) || !variant.isActive) {
        continue;
      }
      final inactive = variant.copyWith(
        status: ProductVariantStatus.inactive,
        updatedAt: DateTime.now().toUtc(),
        updatedBy: generatedBy.trim(),
        version: variant.version + 1,
        syncStatus: ProductSyncStatus.pending,
      );
      final updatedResult = await _variantRepository.update(variant: inactive);
      if (updatedResult is AppFailure<ProductVariant>) {
        return AppFailure<List<ProductVariant>>(updatedResult.failure);
      }
      generatedOrUpdated.add(
        (updatedResult as AppSuccess<ProductVariant>).value,
      );
    }

    final finalResult = await _variantRepository.listByProduct(
      organizationId: trimmedOrganizationId,
      productId: trimmedProductId,
    );
    if (finalResult is AppFailure<List<ProductVariant>>) return finalResult;
    return finalResult;
  }

  Sku _deriveSku({
    required Product product,
    required ProductColor color,
    required SizeGridSize size,
  }) {
    final raw =
        '${product.sku.value}-${_skuSegment(color.code)}-${_skuSegment(size.label)}';
    if (raw.length <= 40) return Sku.parse(raw);
    final compact = '${product.sku.value}-${color.id}-${size.id}';
    return Sku.parse(compact.length <= 40 ? compact : compact.substring(0, 40));
  }

  String _skuSegment(String value) {
    final normalized = value
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'UNICO' : normalized;
  }
}
