import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/database.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/functions/functions.dart';
import '../dtos/catalog_share_dto.dart';
import '../dtos/catalog_share_item_dto.dart';
import 'catalog_share_data_source.dart';

/// Firestore/Cloud-Functions-backed [CatalogShareDataSource] for
/// `organizations/{organizationId}/catalogShares` (TASK-081).
///
/// [getById] reads Firestore directly through [FirestoreCollectionDataSource],
/// same pattern `FirestoreInviteDataSource.listPending` already sets.
/// [create]/[revoke] never write to Firestore directly — they call the
/// corresponding callable Cloud Function through [CloudFunctionsService] and
/// parse its JSON response by hand (dates as ISO-8601 strings, never
/// [CatalogShareDto.fromFirestore]'s [Timestamp] shape), same pattern
/// `FirestoreInviteDataSource.create`/`revoke` established.
@LazySingleton(as: CatalogShareDataSource)
final class FirestoreCatalogShareDataSource implements CatalogShareDataSource {
  FirestoreCatalogShareDataSource(
    this._cloudFunctionsService,
    FirebaseFirestore firestore,
  ) : _collection = FirestoreCollectionDataSource<CatalogShareDto>(
        firestore: firestore,
        collectionName: 'catalogShares',
        converter: FirestoreConverter<CatalogShareDto>(
          fromJson: (data, id) => CatalogShareDto.fromFirestore(data, id: id),
          // Never written from the client — see this class' own doc — but
          // [FirestoreConverter] requires a `toJson` regardless of whether
          // any write path ever calls it.
          toJson: (dto) => throw UnsupportedError(
            'CatalogShare is never written directly from the client.',
          ),
        ),
      );

  final CloudFunctionsService _cloudFunctionsService;
  final FirestoreCollectionDataSource<CatalogShareDto> _collection;

  @override
  Future<IssuedCatalogShareDto> create({
    required String organizationId,
    required String scope,
    required List<CatalogShareItemDto> items,
    String? collectionId,
    String? collectionName,
    int? expiresInDays,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'createCatalogShareLink',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'scope': scope,
        'items': items.map((item) => item.toJson()).toList(growable: false),
        'collectionId': ?collectionId,
        'collectionName': ?collectionName,
        'expiresInDays': ?expiresInDays,
      },
      requireAuth: true,
    );

    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const ServerException(
        'Unexpected createCatalogShareLink callable response shape.',
        code: 'invalid_catalog_share_callable_response',
      );
    }
    return (
      share: _shareDtoFromCallableJson(_requireShareJson(response)),
      token: token,
    );
  }

  @override
  Future<CatalogShareDto> revoke({
    required String organizationId,
    required String shareId,
  }) async {
    final response = await _cloudFunctionsService.call<Map<String, dynamic>>(
      'revokeCatalogShareLink',
      data: <String, dynamic>{
        'organizationId': organizationId,
        'shareId': shareId,
      },
      requireAuth: true,
    );
    return _shareDtoFromCallableJson(_requireShareJson(response));
  }

  @override
  Future<CatalogShareDto?> getById({
    required String organizationId,
    required String shareId,
  }) {
    return _collection.getById(organizationId: organizationId, id: shareId);
  }

  Map<String, dynamic> _requireShareJson(Map<String, dynamic> response) {
    final shareJson = response['share'];
    if (shareJson is! Map) {
      throw const ServerException(
        'Unexpected catalog share callable response shape.',
        code: 'invalid_catalog_share_callable_response',
      );
    }
    return Map<String, dynamic>.from(shareJson);
  }

  /// Parses one `share` JSON object from a callable response — plain JSON
  /// over the wire, dates as `DateTime.parse`-able ISO-8601 strings, unlike
  /// [CatalogShareDto.fromFirestore]'s [Timestamp] shape.
  CatalogShareDto _shareDtoFromCallableJson(Map<String, dynamic> json) {
    final id = json['id'];
    final organizationId = json['organizationId'];
    final scope = json['scope'];
    final rawItems = json['items'];
    final collectionId = json['collectionId'];
    final collectionName = json['collectionName'];
    final status = json['status'];
    final openCount = json['openCount'];
    final firstOpenedAt = json['firstOpenedAt'];
    final lastOpenedAt = json['lastOpenedAt'];
    final expiresAt = json['expiresAt'];
    final createdBy = json['createdBy'];
    final createdByName = json['createdByName'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];

    if (id is! String ||
        organizationId is! String ||
        scope is! String ||
        rawItems is! List ||
        (collectionId != null && collectionId is! String) ||
        (collectionName != null && collectionName is! String) ||
        status is! String ||
        openCount is! int ||
        (firstOpenedAt != null && firstOpenedAt is! String) ||
        (lastOpenedAt != null && lastOpenedAt is! String) ||
        expiresAt is! String ||
        createdBy is! String ||
        createdByName is! String ||
        createdAt is! String ||
        updatedAt is! String) {
      throw const ServerException(
        'Unexpected catalog share callable response shape.',
        code: 'invalid_catalog_share_callable_response',
      );
    }

    return CatalogShareDto(
      id: id,
      organizationId: organizationId,
      scope: scope,
      items: rawItems
          .map(
            (item) => CatalogShareItemDto.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      collectionId: collectionId as String?,
      collectionName: collectionName as String?,
      status: status,
      openCount: openCount,
      firstOpenedAt: firstOpenedAt == null
          ? null
          : DateTime.parse(firstOpenedAt as String),
      lastOpenedAt: lastOpenedAt == null
          ? null
          : DateTime.parse(lastOpenedAt as String),
      expiresAt: DateTime.parse(expiresAt),
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
