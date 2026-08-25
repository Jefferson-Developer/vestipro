import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/repositories/product_variant_repository.dart';
import '../../domain/value_objects/ean.dart';
import '../../domain/value_objects/sku.dart';
import '../dtos/product_variant_dto.dart';
import '../mappers/product_variant_mapper.dart';

/// Firestore-backed product variant repository used by emulator/integration
/// coverage and future remote sync work. Runtime DI still uses the local
/// SharedPreferences repository so product administration remains offline-first.
final class FirestoreProductVariantRepository
    implements ProductVariantRepository {
  FirestoreProductVariantRepository(
    this._firestore, {
    this._mapper = const ProductVariantMapper(),
  }) {
    _collection = FirestoreCollectionDataSource<ProductVariantDto>(
      firestore: _firestore,
      collectionName: 'productVariants',
      converter: FirestoreConverter<ProductVariantDto>(
        fromJson: (data, id) => ProductVariantDto.fromJson(data, id: id),
        toJson: (dto) => dto.toJson(),
      ),
    );
  }

  final FirebaseFirestore _firestore;
  final ProductVariantMapper _mapper;
  late final FirestoreCollectionDataSource<ProductVariantDto> _collection;

  @override
  Future<AppResult<ProductVariant>> create({
    required ProductVariant variant,
  }) async {
    try {
      await _collection.set(
        organizationId: variant.organizationId,
        id: variant.id,
        value: _mapper.toDto(variant),
      );
      return AppSuccess<ProductVariant>(variant);
    } on AppException catch (exception) {
      return AppFailure<ProductVariant>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<ProductVariant>(
        UnexpectedFailure(
          'Unexpected error saving product variant remotely.',
          code: 'product_variant_remote_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ProductVariant>> update({
    required ProductVariant variant,
  }) async {
    try {
      await _collection.set(
        organizationId: variant.organizationId,
        id: variant.id,
        value: _mapper.toDto(variant),
      );
      return AppSuccess<ProductVariant>(variant);
    } on AppException catch (exception) {
      return AppFailure<ProductVariant>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<ProductVariant>(
        UnexpectedFailure(
          'Unexpected error updating product variant remotely.',
          code: 'product_variant_remote_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ProductVariant>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final page = await _collection.getPage(
        organizationId: organizationId,
        limit: 500,
      );
      return AppSuccess<List<ProductVariant>>(
        _mapAndSort(page.items, organizationId),
      );
    } on AppException catch (exception) {
      return AppFailure<List<ProductVariant>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<ProductVariant>>(
        UnexpectedFailure(
          'Unexpected error listing product variants remotely.',
          code: 'product_variant_remote_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ProductVariant>>> listByProduct({
    required String organizationId,
    required String productId,
  }) async {
    try {
      final page = await _collection.getPage(
        organizationId: organizationId,
        limit: 500,
        queryBuilder: (query) => query.where('productId', isEqualTo: productId),
      );
      return AppSuccess<List<ProductVariant>>(
        _mapAndSort(page.items, organizationId),
      );
    } on AppException catch (exception) {
      return AppFailure<List<ProductVariant>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<ProductVariant>>(
        UnexpectedFailure(
          'Unexpected error listing product variants by product remotely.',
          code: 'product_variant_remote_product_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<ProductVariant>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final dto = await _collection.getById(
        organizationId: organizationId,
        id: id,
      );
      if (dto == null) {
        return const AppFailure<ProductVariant>(
          NotFoundFailure(
            'Product variant not found.',
            code: 'product_variant_not_found',
          ),
        );
      }
      final variant = _mapper.toEntity(dto);
      if (variant.organizationId != organizationId) {
        return const AppFailure<ProductVariant>(
          PermissionFailure(
            'Product variant belongs to another organization.',
            code: 'product_variant_tenant_mismatch',
          ),
        );
      }
      return AppSuccess<ProductVariant>(variant);
    } on AppException catch (exception) {
      return AppFailure<ProductVariant>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<ProductVariant>(
        UnexpectedFailure(
          'Unexpected error loading product variant remotely.',
          code: 'product_variant_remote_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> existsBySku({
    required String organizationId,
    required Sku sku,
    String? excludingVariantId,
  }) async {
    return _existsByUniqueField(
      organizationId: organizationId,
      field: 'sku',
      value: sku.value,
      excludingVariantId: excludingVariantId,
    );
  }

  @override
  Future<AppResult<bool>> existsByEan({
    required String organizationId,
    required Ean ean,
    String? excludingVariantId,
  }) async {
    return _existsByUniqueField(
      organizationId: organizationId,
      field: 'ean',
      value: ean.digits,
      excludingVariantId: excludingVariantId,
    );
  }

  @override
  Future<AppResult<bool>> isReferencedByOrder({
    required String organizationId,
    required String variantId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('orders')
          .where('variantIds', arrayContains: variantId)
          .limit(1)
          .get();
      return AppSuccess<bool>(snapshot.docs.isNotEmpty);
    } on FirebaseException catch (exception, stackTrace) {
      return AppFailure<bool>(
        mapAppExceptionToFailure(
          mapFirestoreExceptionToAppException(exception, stackTrace),
        ),
      );
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking product variant order usage remotely.',
          code: 'product_variant_remote_order_usage_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<AppResult<bool>> _existsByUniqueField({
    required String organizationId,
    required String field,
    required Object value,
    String? excludingVariantId,
  }) async {
    try {
      final page = await _collection.getPage(
        organizationId: organizationId,
        limit: 10,
        queryBuilder: (query) => query
            .where(field, isEqualTo: value)
            .where('status', isEqualTo: 'active'),
      );
      final excludedId = excludingVariantId?.trim();
      return AppSuccess<bool>(
        page.items.any(
          (dto) =>
              dto.organizationId == organizationId &&
              (excludedId == null ||
                  excludedId.isEmpty ||
                  dto.id != excludedId),
        ),
      );
    } on AppException catch (exception) {
      return AppFailure<bool>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error checking product variant uniqueness remotely.',
          code: 'product_variant_remote_unique_unexpected',
          cause: exception,
        ),
      );
    }
  }

  List<ProductVariant> _mapAndSort(
    List<ProductVariantDto> dtos,
    String organizationId,
  ) {
    return dtos
        .map(_mapper.toEntity)
        .where((variant) => variant.organizationId == organizationId)
        .toList(growable: false)
      ..sort(_compareVariants);
  }

  int _compareVariants(ProductVariant a, ProductVariant b) {
    final byProduct = a.productId.compareTo(b.productId);
    if (byProduct != 0) return byProduct;
    final byColor = a.colorId.compareTo(b.colorId);
    if (byColor != 0) return byColor;
    return a.sizeId.compareTo(b.sizeId);
  }
}
