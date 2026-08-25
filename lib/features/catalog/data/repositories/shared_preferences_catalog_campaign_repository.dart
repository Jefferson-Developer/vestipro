import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/catalog_campaign.dart';
import '../../domain/repositories/catalog_campaign_repository.dart';

/// Local `CatalogCampaign` store (TASK-076), the same "local store used
/// until the remote/outbox sync implementation exists" precedent
/// `SharedPreferencesCollectionRepository`/`SharedPreferencesProductRepository`
/// already set (TASK-065/TASK-066). Read-only today (`listByOrganization`):
/// admin CRUD is TASK-080's scope, which will add `create`/`update` to this
/// same store, the same incremental-interface-growth pattern
/// `ProductRepository` already followed from TASK-064 to TASK-065.
///
/// With no writer wired yet, this always returns an empty list unless a
/// caller (e.g. a future TASK-080 admin screen, or a test) seeds
/// `SharedPreferences` directly under [_keyFor] — the catalog home simply
/// hides the "campanhas em destaque" section when it does (TASK-076: never
/// render a section with no content).
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

  CatalogCampaign _fromJson(Map<String, dynamic> json) {
    return CatalogCampaign(
      id: _requiredString(json, 'id'),
      organizationId: _requiredString(json, 'organizationId'),
      title: _requiredString(json, 'title'),
      subtitle: _optionalString(json, 'subtitle'),
      imageUrl: _optionalString(json, 'imageUrl'),
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
