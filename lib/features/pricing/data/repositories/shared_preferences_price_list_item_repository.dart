import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/price_list_item.dart';
import '../../domain/repositories/price_list_item_repository.dart';

@LazySingleton(as: PriceListItemRepository)
final class SharedPreferencesPriceListItemRepository
    implements PriceListItemRepository {
  const SharedPreferencesPriceListItemRepository();

  String _keyFor(String organizationId) => 'price_list_items_$organizationId';

  @override
  Future<AppResult<List<PriceListItem>>> listByPriceList({
    required String organizationId,
    required String companyId,
    required String priceListId,
  }) async {
    try {
      final items = await _load(organizationId);
      return AppSuccess<List<PriceListItem>>(
        items
            .where(
              (item) =>
                  item.companyId == companyId &&
                  item.priceListId == priceListId &&
                  item.deletedAt == null,
            )
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<PriceListItem>>(
        UnexpectedFailure(
          'Unexpected error listing price list items locally.',
          code: 'price_list_item_local_list_by_price_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PriceListItem>>> listByProduct({
    required String organizationId,
    required String companyId,
    required String productId,
  }) async {
    try {
      final items = await _load(organizationId);
      return AppSuccess<List<PriceListItem>>(
        items
            .where(
              (item) =>
                  item.companyId == companyId &&
                  item.productId == productId &&
                  item.deletedAt == null,
            )
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<PriceListItem>>(
        UnexpectedFailure(
          'Unexpected error listing product prices locally.',
          code: 'price_list_item_local_list_by_product_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PriceListItem>>> upsertBatch({
    required String organizationId,
    required String companyId,
    required String priceListId,
    required List<PriceListItem> items,
    required bool confirmOverwrite,
  }) async {
    try {
      final existing = await _load(organizationId);
      final existingById = <String, PriceListItem>{
        for (final item in existing) item.id: item,
      };
      final conflictingIds = items
          .where((item) => existingById.containsKey(item.id))
          .map((item) => item.id)
          .toList(growable: false);
      if (conflictingIds.isNotEmpty && !confirmOverwrite) {
        return const AppFailure<List<PriceListItem>>(
          ConflictFailure(
            'Existing variant/product prices require explicit overwrite confirmation.',
            code: 'price_list_item_overwrite_confirmation_required',
          ),
        );
      }

      final retained = existing.where(
        (item) =>
            item.organizationId != organizationId ||
            item.companyId != companyId ||
            item.priceListId != priceListId ||
            !items.any((candidate) => candidate.id == item.id),
      );
      final next = <PriceListItem>[...retained, ...items];
      await _save(organizationId, next);
      return AppSuccess<List<PriceListItem>>(items);
    } catch (exception) {
      return AppFailure<List<PriceListItem>>(
        UnexpectedFailure(
          'Unexpected error saving price list items locally.',
          code: 'price_list_item_local_upsert_batch_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<PriceListItem>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null || raw.isEmpty) return const <PriceListItem>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const <PriceListItem>[];
    return decoded
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> _save(String organizationId, List<PriceListItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(items.map(_toJson).toList(growable: false)),
    );
  }

  Map<String, dynamic> _toJson(PriceListItem item) {
    return <String, dynamic>{
      'id': item.id,
      'organizationId': item.organizationId,
      'companyId': item.companyId,
      'priceListId': item.priceListId,
      'productId': item.productId,
      'variantId': item.variantId,
      'price': item.price,
      'updatedAt': item.updatedAt.toIso8601String(),
      'updatedBy': item.updatedBy,
      'deletedAt': item.deletedAt?.toIso8601String(),
      'version': item.version,
      'syncStatus': item.syncStatus,
    };
  }

  PriceListItem _fromJson(Map<String, dynamic> json) {
    return PriceListItem(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      companyId: json['companyId'] as String,
      priceListId: json['priceListId'] as String,
      productId: json['productId'] as String,
      variantId: json['variantId'] as String?,
      price: (json['price'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      updatedBy: json['updatedBy'] as String,
      deletedAt: (json['deletedAt'] as String?) == null
          ? null
          : DateTime.parse(json['deletedAt'] as String),
      version: json['version'] as int? ?? 1,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
    );
  }
}
