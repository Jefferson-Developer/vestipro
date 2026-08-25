/// The kind of content a [CatalogHomeSection] shows on the catalog home
/// (TASK-076, EPIC-10).
///
/// Only [featuredCollections], [newArrivals] and [campaigns] have a real,
/// data-backed use case wired into `CatalogHomeBloc` today — each reads from
/// a repository that already exists in this codebase
/// (`CollectionRepository`, `ProductRepository`, `CatalogCampaignRepository`).
///
/// [bestSellers], [recommended] and [readyToShip] are intentionally part of
/// this enum (the vocabulary `tasks.md`/TASK-076 describes for the home) but
/// have **no** use case registered yet: "mais vendidos"/"recomendados" need
/// the server-side sales/insights aggregation EPIC-16/17 has not built, and
/// "pronta entrega" needs the stock/availability aggregation EPIC-12 has not
/// built either. Faking either with a client-side computation would violate
/// the business rule in TASK-076 ("nunca de cálculo client-side") and the
/// "nenhuma seção pode simular urgência falsa" rule, so `CatalogHomeBloc`
/// simply has no runner for these types yet — a section config that enables
/// one of them is silently skipped (not treated as a failure) until a future
/// task registers its use case. See TASK-076's completion notes.
enum CatalogHomeSectionType {
  featuredCollections,
  newArrivals,
  bestSellers,
  recommended,
  readyToShip,
  campaigns,
}
