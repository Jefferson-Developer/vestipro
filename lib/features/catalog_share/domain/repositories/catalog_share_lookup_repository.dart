import '../../../../core/utils/utils.dart';
import '../entities/catalog_share_preview.dart';

/// Contract for the token-driven, public catalog share flow (TASK-081): a
/// visitor who never signs in, looking at whatever `CatalogSharePreview`
/// [token] currently resolves to.
///
/// Deliberately a separate contract from [CatalogShareRepository]
/// (management by an already-authenticated vendor, always scoped by
/// `organizationId`): here the caller only ever has a [token] — the
/// `organizationId` is not known ahead of time, same "resolved from the
/// token, not passed in" precedent [InviteAcceptanceRepository] already
/// sets for `lib/features/invites`.
abstract interface class CatalogShareLookupRepository {
  /// Reports what [token] currently resolves to — never throws for an
  /// expected business outcome (unknown/expired/revoked token); only an
  /// [AppFailure] represents a genuine technical failure (network, server
  /// error).
  Future<AppResult<CatalogSharePreview>> preview({required String token});

  /// Best-effort: records that [token] was just opened. Always resolves
  /// successfully (even when nothing was actually recorded) — see
  /// `registerCatalogShareOpen`'s own doc for why this must never be able
  /// to block or degrade [preview]'s result. Callers should never `await`
  /// this before rendering the preview they already have.
  Future<void> registerOpen({required String token});
}
