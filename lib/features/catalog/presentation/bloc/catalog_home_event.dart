import '../../domain/entities/catalog_home_section_type.dart';

sealed class CatalogHomeEvent {
  const CatalogHomeEvent();
}

/// Starts loading the catalog home for [organizationId] (and, when the
/// organization splits its catalog per company, [companyId]) — first
/// painting any cached snapshot instantly, then fetching every enabled
/// section in parallel (TASK-076).
final class CatalogHomeStarted extends CatalogHomeEvent {
  const CatalogHomeStarted({
    required this.organizationId,
    this.companyId,
    required this.userId,
  });

  final String organizationId;
  final String? companyId;
  final String userId;
}

/// Pull-to-refresh: re-fetches every enabled section without discarding the
/// sections already on screen while the new data loads.
final class CatalogHomeRefreshRequested extends CatalogHomeEvent {
  const CatalogHomeRefreshRequested();
}

/// The viewer tapped a section's header/item. `CatalogHomeBloc` only uses
/// this to fire the `catalog_section_opened` analytics event — navigation
/// itself is decided by whoever instantiates `CatalogHomePage`
/// (`onSectionItemTap`), never by the BLoC.
final class CatalogHomeSectionOpened extends CatalogHomeEvent {
  const CatalogHomeSectionOpened(this.type);

  final CatalogHomeSectionType type;
}
