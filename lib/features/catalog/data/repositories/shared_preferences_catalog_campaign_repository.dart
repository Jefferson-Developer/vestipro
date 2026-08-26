import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/catalog_campaign.dart';
import '../../domain/repositories/catalog_campaign_repository.dart';

/// Local `CatalogCampaign` store used until the remote/outbox sync
/// implementation exists (TASK-076 read-only, TASK-080 adds the write
/// side) — the same "local store used until the remote/outbox sync
/// implementation exists" precedent
/// `SharedPreferencesCollectionRepository`/`SharedPreferencesProductRepository`
/// already set (TASK-065/TASK-066): every create/update/delete mutation
/// stays durable in `SharedPreferences`, scoped to the active Organization.
@LazySingleton(as: CatalogCampaignRepository)
final class SharedPreferencesCatalogCampaignRepository
    implements CatalogCampaignRepository {
  const SharedPreferencesCatalogCampaignRepository();

  String _keyFor(String organizationId) => 'catalog_campaigns_$organizationId';

  @override
  Future<AppResult<List<CatalogCampaign>>> listByOrganization(
    String organizationId,
  ) async {
    try {
      final campaigns = await _load(organizationId);
      return AppSuccess<List<CatalogCampaign>>(
        campaigns
            .where((campaign) => campaign.deletedAt == null)
            .toList(growable: false),
      );
    } catch (exception) {
      return AppFailure<List<CatalogCampaign>>(
        UnexpectedFailure(
          'Unexpected error listing catalog campaigns locally.',
          code: 'catalog_campaign_local_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CatalogCampaign>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final campaigns = await _load(organizationId);
      for (final campaign in campaigns) {
        if (campaign.id == id) return AppSuccess<CatalogCampaign>(campaign);
      }
      return const AppFailure<CatalogCampaign>(
        NotFoundFailure(
          'Catalog campaign not found.',
          code: 'catalog_campaign_not_found',
        ),
      );
    } catch (exception) {
      return AppFailure<CatalogCampaign>(
        UnexpectedFailure(
          'Unexpected error loading catalog campaign locally.',
          code: 'catalog_campaign_local_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CatalogCampaign>> create({
    required CatalogCampaign campaign,
  }) async {
    try {
      final campaigns = await _load(campaign.organizationId);
      final next = <CatalogCampaign>[
        ...campaigns.where((existing) => existing.id != campaign.id),
        campaign,
      ];
      await _save(campaign.organizationId, next);
      return AppSuccess<CatalogCampaign>(campaign);
    } catch (exception) {
      return AppFailure<CatalogCampaign>(
        UnexpectedFailure(
          'Unexpected error saving catalog campaign locally.',
          code: 'catalog_campaign_local_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CatalogCampaign>> update({
    required CatalogCampaign campaign,
  }) async {
    try {
      final campaigns = await _load(campaign.organizationId);
      final index = campaigns.indexWhere(
        (existing) => existing.id == campaign.id,
      );
      if (index == -1) {
        return const AppFailure<CatalogCampaign>(
          NotFoundFailure(
            'Catalog campaign not found.',
            code: 'catalog_campaign_not_found',
          ),
        );
      }
      final next = List<CatalogCampaign>.of(campaigns)..[index] = campaign;
      await _save(campaign.organizationId, next);
      return AppSuccess<CatalogCampaign>(campaign);
    } catch (exception) {
      return AppFailure<CatalogCampaign>(
        UnexpectedFailure(
          'Unexpected error updating catalog campaign locally.',
          code: 'catalog_campaign_local_update_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<CatalogCampaign>> delete({
    required String organizationId,
    required String id,
    required String updatedBy,
  }) async {
    try {
      final campaigns = await _load(organizationId);
      final index = campaigns.indexWhere((existing) => existing.id == id);
      if (index == -1) {
        return const AppFailure<CatalogCampaign>(
          NotFoundFailure(
            'Catalog campaign not found.',
            code: 'catalog_campaign_not_found',
          ),
        );
      }
      final now = DateTime.now().toUtc();
      final deleted = campaigns[index].copyWith(
        deletedAt: now,
        updatedAt: now,
        updatedBy: updatedBy,
      );
      final next = List<CatalogCampaign>.of(campaigns)..[index] = deleted;
      await _save(organizationId, next);
      return AppSuccess<CatalogCampaign>(deleted);
    } catch (exception) {
      return AppFailure<CatalogCampaign>(
        UnexpectedFailure(
          'Unexpected error deleting catalog campaign locally.',
          code: 'catalog_campaign_local_delete_unexpected',
          cause: exception,
        ),
      );
    }
  }

  Future<List<CatalogCampaign>> _load(String organizationId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(organizationId));
    if (raw == null) return const <CatalogCampaign>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      throw const ValidationException(
        'Invalid local catalog campaign list.',
        code: 'invalid_catalog_campaign_local_list',
      );
    }

    return decoded
        .map((item) {
          if (item is! Map<String, dynamic>) {
            throw const ValidationException(
              'Invalid local catalog campaign payload.',
              code: 'invalid_catalog_campaign_local_payload',
            );
          }
          return _fromJson(item);
        })
        .toList(growable: false);
  }

  Future<void> _save(
    String organizationId,
    List<CatalogCampaign> campaigns,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(organizationId),
      jsonEncode(campaigns.map(_toJson).toList(growable: false)),
    );
  }

  CatalogCampaign _fromJson(Map<String, dynamic> json) {
    return CatalogCampaign(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      title: _requiredString(json, 'title'),
      subtitle: _optionalString(json, 'subtitle'),
      description: _optionalString(json, 'description'),
      imageUrl: _optionalString(json, 'imageUrl'),
      editorialImageUrls: _stringList(json, 'editorialImageUrls'),
      relatedProductIds: _stringList(json, 'relatedProductIds'),
      collectionId: _optionalString(json, 'collectionId'),
      order: _requiredInt(json, 'order'),
      active: (json['active'] as bool?) ?? false,
      startAt: _optionalDate(json, 'startAt'),
      endAt: _optionalDate(json, 'endAt'),
      createdAt: _requiredDate(json, 'createdAt'),
      createdBy: _requiredString(json, 'createdBy'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      updatedBy: _requiredString(json, 'updatedBy'),
      deletedAt: _optionalDate(json, 'deletedAt'),
    );
  }

  Map<String, dynamic> _toJson(CatalogCampaign campaign) {
    return <String, dynamic>{
      'id': campaign.id,
      'organizationId': campaign.organizationId,
      'title': campaign.title,
      if (campaign.subtitle != null) 'subtitle': campaign.subtitle,
      if (campaign.description != null) 'description': campaign.description,
      if (campaign.imageUrl != null) 'imageUrl': campaign.imageUrl,
      'editorialImageUrls': campaign.editorialImageUrls,
      'relatedProductIds': campaign.relatedProductIds,
      if (campaign.collectionId != null) 'collectionId': campaign.collectionId,
      'order': campaign.order,
      'active': campaign.active,
      if (campaign.startAt != null)
        'startAt': campaign.startAt!.toUtc().toIso8601String(),
      if (campaign.endAt != null)
        'endAt': campaign.endAt!.toUtc().toIso8601String(),
      'createdAt': campaign.createdAt.toUtc().toIso8601String(),
      'createdBy': campaign.createdBy,
      'updatedAt': campaign.updatedAt.toUtc().toIso8601String(),
      'updatedBy': campaign.updatedBy,
      if (campaign.deletedAt != null)
        'deletedAt': campaign.deletedAt!.toUtc().toIso8601String(),
    };
  }

  String _requiredString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String) return value;
    throw ValidationException(
      'Invalid local catalog campaign string field.',
      code: 'invalid_catalog_campaign_local_payload',
      cause: field,
    );
  }

  String? _optionalString(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null || value is String) return value as String?;
    throw ValidationException(
      'Invalid local catalog campaign string field.',
      code: 'invalid_catalog_campaign_local_payload',
      cause: field,
    );
  }

  List<String> _stringList(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value == null) return const <String>[];
    if (value is List) return value.cast<String>();
    throw ValidationException(
      'Invalid local catalog campaign list field.',
      code: 'invalid_catalog_campaign_local_payload',
      cause: field,
    );
  }

  int _requiredInt(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ValidationException(
      'Invalid local catalog campaign integer field.',
      code: 'invalid_catalog_campaign_local_payload',
      cause: field,
    );
  }

  DateTime _requiredDate(Map<String, dynamic> json, String field) {
    return DateTime.parse(_requiredString(json, field)).toUtc();
  }

  DateTime? _optionalDate(Map<String, dynamic> json, String field) {
    final value = _optionalString(json, field);
    return value == null ? null : DateTime.parse(value).toUtc();
  }
}
