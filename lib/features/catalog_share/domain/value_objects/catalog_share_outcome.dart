/// What `getCatalogShareLink` (TASK-081,
/// `functions/src/catalog/get-catalog-share-link.ts`) reports about a token
/// *before* `CatalogSharePublicPage` ever shows any product — mirrors that
/// Function's own `outcome` field exactly, same shape as
/// `InviteAcceptanceOutcome`.
///
/// [valid] is the only outcome that carries [CatalogSharePreview.items];
/// every other value only exists to pick which clear, specific message to
/// show (TASK-081: "link expirado ou revogado deve exibir mensagem clara ao
/// destinatário, nunca erro técnico cru").
enum CatalogShareOutcome {
  /// Still active and within its `expiresAt` — items are safe to render.
  valid,

  /// No `CatalogShare` document anywhere matches the presented token — an
  /// unknown, mistyped or tampered link.
  notFound,

  /// Past `expiresAt` — resolved server-side, independently of a possibly
  /// stale `status` field.
  expired,

  /// Explicitly revoked by its creator or an OWNER/ADMIN — terminal.
  revoked,
}

extension CatalogShareOutcomeCode on CatalogShareOutcome {
  /// The literal value in `getCatalogShareLink`'s own response.
  String get code {
    return switch (this) {
      CatalogShareOutcome.valid => 'valid',
      CatalogShareOutcome.notFound => 'notFound',
      CatalogShareOutcome.expired => 'expired',
      CatalogShareOutcome.revoked => 'revoked',
    };
  }
}

/// Parses the raw `getCatalogShareLink` response value back into a
/// [CatalogShareOutcome], or `null` for anything unrecognized.
CatalogShareOutcome? catalogShareOutcomeFromCode(String code) {
  for (final outcome in CatalogShareOutcome.values) {
    if (outcome.code == code) return outcome;
  }
  return null;
}
