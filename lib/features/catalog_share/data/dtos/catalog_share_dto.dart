import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/errors.dart';
import 'catalog_share_item_dto.dart';

/// Wire shape of a `CatalogShare`, as seen by its **creator** (or an
/// OWNER/ADMIN) — the `organizations/{organizationId}/catalogShares/{id}`
/// Firestore document (dates as [Timestamp], via [CatalogShareDto.fromFirestore])
/// and `createCatalogShareLink`/`revokeCatalogShareLink`'s plain-JSON
/// callable response (dates as ISO-8601 strings, parsed by
/// `CloudFunctionsCatalogShareDataSource`'s own private helper — same
/// two-parsers-one-DTO precedent as `InviteDto`).
///
/// Deliberately does not model `tokenHash`: nothing in `data/`/`domain/`
/// ever needs to read it back — the plaintext token is only ever available
/// once, as [IssuedCatalogShareDto]'s `token`, right when
/// `createCatalogShareLink` succeeds.
final class CatalogShareDto {
  const CatalogShareDto({
    required this.id,
    required this.organizationId,
    required this.scope,
    required this.items,
    this.collectionId,
    this.collectionName,
    required this.status,
    required this.openCount,
    this.firstOpenedAt,
    this.lastOpenedAt,
    required this.expiresAt,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Builds a [CatalogShareDto] from a Firestore document's raw data (dates
  /// as [Timestamp]) — used by [FirestoreCatalogShareDataSource.getById].
  factory CatalogShareDto.fromFirestore(
    Map<String, dynamic> json, {
    required String id,
  }) {
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

    if (organizationId is! String ||
        scope is! String ||
        rawItems is! List ||
        (collectionId != null && collectionId is! String) ||
        (collectionName != null && collectionName is! String) ||
        status is! String ||
        openCount is! int ||
        (firstOpenedAt != null && firstOpenedAt is! Timestamp) ||
        (lastOpenedAt != null && lastOpenedAt is! Timestamp) ||
        expiresAt is! Timestamp ||
        createdBy is! String ||
        createdByName is! String ||
        createdAt is! Timestamp ||
        updatedAt is! Timestamp) {
      throw const ValidationException(
        'Invalid catalog share payload.',
        code: 'invalid_catalog_share_payload',
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
      firstOpenedAt: (firstOpenedAt as Timestamp?)?.toDate(),
      lastOpenedAt: (lastOpenedAt as Timestamp?)?.toDate(),
      expiresAt: expiresAt.toDate(),
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt.toDate(),
    );
  }

  final String id;
  final String organizationId;
  final String scope;
  final List<CatalogShareItemDto> items;
  final String? collectionId;
  final String? collectionName;
  final String status;
  final int openCount;
  final DateTime? firstOpenedAt;
  final DateTime? lastOpenedAt;
  final DateTime expiresAt;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
}
