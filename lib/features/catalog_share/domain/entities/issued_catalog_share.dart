import 'package:freezed_annotation/freezed_annotation.dart';

import 'catalog_share.dart';

part 'issued_catalog_share.freezed.dart';

/// The result of creating a [CatalogShare]: the persisted record itself plus
/// the plaintext [token] needed to build the shareable link right now
/// (TASK-081) — same "only available at creation time" contract as
/// `IssuedInvite` (`lib/features/invites/domain/entities/issued_invite.dart`).
///
/// Firestore only ever stores this token's SHA-256 hash; a later read of
/// the same [CatalogShare] (e.g. listing "meus compartilhamentos") can
/// never recover it.
@freezed
abstract class IssuedCatalogShare with _$IssuedCatalogShare {
  const factory IssuedCatalogShare({
    required CatalogShare share,
    required String token,
  }) = _IssuedCatalogShare;
}
