sealed class CatalogSharePublicEvent {
  const CatalogSharePublicEvent();
}

/// Starts (or restarts, e.g. a manual "tentar novamente" after a network
/// error) loading the public preview for [token] — the URL's own path
/// parameter, resolved by `CatalogSharePublicRoute`.
final class CatalogSharePublicStarted extends CatalogSharePublicEvent {
  const CatalogSharePublicStarted({required this.token});

  final String token;
}
