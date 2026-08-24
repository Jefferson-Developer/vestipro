import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/product_collection_link.dart';
import '../../domain/repositories/product_collection_link_repository.dart';

/// Local Product-Collection join store used until the remote/outbox sync
/// implementation exists (TASK-066; same rationale as
/// `SharedPreferencesProductRepository`, TASK-065), scoped to the active
/// Organization.
@LazySingleton(as: ProductCollectionLinkRepository)
final class SharedPreferencesProductCollectionLinkRepository
    implements ProductCollectionLinkRepository {
  const SharedPreferencesProductCollectionLinkRepository();

  String _keyFor(String organizationId) =>
      'product_collection_links_$organizationId';

  @override
  Future<AppResult<ProductCollectionLink>> create({
    required ProductCollectionLink link,
  }) async {
    try {
      final links = await _load(link.organizationId);
      final next = <ProductCollectionLink>[
        ...links.where((existing) => existing.id != link.id),
        link,
      ];
      await _save(link.organizationId, next);
      return AppSuccess<ProductCollectionLink>(link);
    } catch (exception) {
      return AppFailure<ProductCollectionLink>(
        UnexpectedFailure(
          'Unexpected error saving product-collection link locally.',
          code: 'product_collection_link_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ProductCollectionLink>>> listByProduct({
    required String organizationId,
    required String productId,
  }) async {
    try {
      final links = await _load(organizationId);
      return AppSuccess<List<ProductCollectionLink>>(
        links
            .where((link) => link.productId == productId)
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<ProductCollectionLink>>(
        UnexpectedFailure(
          'Unexpected error listing product-collection links locally.',
          code: 'product_collection_link_local_list_by_product_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<ProductCollectionLink>>> listByCollection({
    required String organizationId,
    required String collectionId,
  }) async {
    try {
      final links = await _load(organizationId);
      return AppSuccess<List<ProductCollectionLink>>(
        links
            .where((link) => link.collectionId == collectionId)
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<ProductCollectionLink>>(
        UnexpectedFailure(
          'Unexpected error listing product-collection links locally.',
          code: 'product_collection_link_local_list_by_collection_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> deleteByProductAndCollection({
    required String organizationId,
    required String productId,
    required String collectionId,
  }) async {
    try {
      final links = await _load(organizationId);
      final next = links
          .where(
            (link) =>
                !(link.productId == productId &&
                    link.collectionId == collectionId),
          )
          .toList(growable: false);
      await _save(organizationId, next);
      return const AppSuccess<bool>(true);
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error removing product-collection link locally.',
          code: 'product_collection_link_local_delete_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<bool>> deleteAllByProduct({
    required String organizationId,
    required String productId,
  }) async {
    try {
      final links = await _load(organizationId);
      final next = links
          .where((link) => link.productId != productId)
          .toList(growable: false);
      await _save(organizationId, next);
      return const AppSuccess<bool>(true);
    } catch (exception) {
      return AppFailure<bool>(
        UnexpectedFailure(
          'Unexpected error removing product-collection links locally.',
          code: 'product_collection_link_local_delete_all_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<ProductCollectionLink>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <ProductCollectionLink>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local product-collection link list.',
        code: 'invalid_product_collection_link_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local product-collection link payload.',
              code: 'invalid_product_collection_link_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(
    String organizationId,
    List<ProductCollectionLink> links,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(links.map(_toJson).toList(growable: false)),
    );
  }

  ProductCollectionLink _fromJson(Map<String, dynamic> json) {
    return ProductCollectionLink(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      productId: _requiredString(json, 'productId'),
      collectionId: _requiredString(json, 'collectionId'),
      createdAt: DateTime.parse(_requiredString(json, 'createdAt')).toUtc(),
      createdBy: _requiredString(json, 'createdBy'),
    );
  }

  Map<String, dynamic> _toJson(ProductCollectionLink link) {
    return <String, dynamic>{
      'id': link.id,
      'organizationId': link.organizationId,
      'productId': link.productId,
      'collectionId': link.collectionId,
      'createdAt': link.createdAt.toUtc().toIso8601String(),
      'createdBy': link.createdBy,
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local product-collection link string field.',
      code: 'invalid_product_collection_link_local_payload',
      cause: field,
    );
  }
}
