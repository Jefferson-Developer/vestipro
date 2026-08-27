import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/promotional_campaign.dart';
import '../../domain/repositories/promotional_campaign_repository.dart';
import '../../domain/value_objects/promotional_campaign_status.dart';
import '../../domain/value_objects/promotional_discount_type.dart';

@LazySingleton(as: PromotionalCampaignRepository)
final class SharedPreferencesPromotionalCampaignRepository
    implements PromotionalCampaignRepository {
  const SharedPreferencesPromotionalCampaignRepository();

  String _keyFor(String organizationId) =>
      'promotional_campaigns_$organizationId';

  @override
  Future<AppResult<PromotionalCampaign>> create({
    required PromotionalCampaign campaign,
  }) async {
    try {
      final existing = await _load(campaign.organizationId);
      if (existing.any((item) => item.id == campaign.id)) {
        return const AppFailure<PromotionalCampaign>(
          ConflictFailure(
            'Promotional campaign already exists.',
            code: 'promotional_campaign_already_exists',
          ),
        );
      }
      await _save(campaign.organizationId, <PromotionalCampaign>[
        ...existing,
        campaign,
      ]);
      return AppSuccess<PromotionalCampaign>(campaign);
    } catch (exception) {
      return AppFailure<PromotionalCampaign>(
        UnexpectedFailure(
          'Unexpected error creating promotional campaign locally.',
          code: 'promotional_campaign_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<PromotionalCampaign?>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final items = await _load(organizationId);
      for (final item in items) {
        if (item.id == id && item.deletedAt == null) {
          return AppSuccess<PromotionalCampaign?>(item);
        }
      }
      return const AppSuccess<PromotionalCampaign?>(null);
    } catch (exception) {
      return AppFailure<PromotionalCampaign?>(
        UnexpectedFailure(
          'Unexpected error loading promotional campaign locally.',
          code: 'promotional_campaign_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PromotionalCampaign>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final items = await _load(organizationId);
      return AppSuccess<List<PromotionalCampaign>>(
        items
            .where(
              (item) => item.companyId == companyId && item.deletedAt == null,
            )
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<PromotionalCampaign>>(
        UnexpectedFailure(
          'Unexpected error listing promotional campaigns locally.',
          code: 'promotional_campaign_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<PromotionalCampaign>> update({
    required PromotionalCampaign campaign,
  }) async {
    try {
      final items = await _load(campaign.organizationId);
      final index = items.indexWhere((item) => item.id == campaign.id);
      if (index < 0) {
        return const AppFailure<PromotionalCampaign>(
          NotFoundFailure(
            'Promotional campaign not found.',
            code: 'promotional_campaign_not_found',
          ),
        );
      }
      final next = List<PromotionalCampaign>.of(items);
      next[index] = campaign;
      await _save(campaign.organizationId, next);
      return AppSuccess<PromotionalCampaign>(campaign);
    } catch (exception) {
      return AppFailure<PromotionalCampaign>(
        UnexpectedFailure(
          'Unexpected error updating promotional campaign locally.',
          code: 'promotional_campaign_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<PromotionalCampaign>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null || raw.isEmpty) return const <PromotionalCampaign>[];
    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) return const <PromotionalCampaign>[];
    return decoded
        .map((item) => _fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> _save(
    String organizationId,
    List<PromotionalCampaign> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(items.map(_toJson).toList(growable: false)),
    );
  }

  Map<String, Object?> _toJson(PromotionalCampaign item) {
    return <String, Object?>{
      'id': item.id,
      'organizationId': item.organizationId,
      'companyId': item.companyId,
      'name': item.name,
      'validFrom': item.validFrom.toUtc().toIso8601String(),
      'validTo': item.validTo.toUtc().toIso8601String(),
      'customerSegment': item.customerSegment,
      'productIds': item.productIds,
      'collectionIds': item.collectionIds,
      'categoryIds': item.categoryIds,
      'discountType': item.discountType.name,
      'discountValue': item.discountValue,
      'stackableWithOtherCampaigns': item.stackableWithOtherCampaigns,
      'priority': item.priority,
      'status': item.status.name,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
      'createdBy': item.createdBy,
      'updatedAt': item.updatedAt.toUtc().toIso8601String(),
      'updatedBy': item.updatedBy,
      'deletedAt': item.deletedAt?.toUtc().toIso8601String(),
      'version': item.version,
      'syncStatus': item.syncStatus,
    };
  }

  PromotionalCampaign _fromJson(Map<String, dynamic> json) {
    return PromotionalCampaign(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      companyId: json['companyId'] as String,
      name: json['name'] as String,
      validFrom: DateTime.parse(json['validFrom'] as String),
      validTo: DateTime.parse(json['validTo'] as String),
      customerSegment: json['customerSegment'] as String,
      productIds: (json['productIds'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toList(growable: false),
      collectionIds: (json['collectionIds'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toList(growable: false),
      categoryIds: (json['categoryIds'] as List<dynamic>? ?? const [])
          .cast<String>()
          .toList(growable: false),
      discountType: PromotionalDiscountType.values.byName(
        json['discountType'] as String,
      ),
      discountValue: (json['discountValue'] as num).toDouble(),
      stackableWithOtherCampaigns:
          json['stackableWithOtherCampaigns'] as bool? ?? false,
      priority: json['priority'] as int? ?? 0,
      status: PromotionalCampaignStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
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
