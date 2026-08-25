import 'package:freezed_annotation/freezed_annotation.dart';

import 'catalog_home_item.dart';
import 'catalog_home_section_type.dart';

part 'catalog_home_section.freezed.dart';

/// One already-resolved section of the catalog home (TASK-076): a title, a
/// display [order]/[priority] and the [items] to render as a horizontal
/// carousel — everything `CatalogHomeSectionView` needs, with no further
/// business logic left for the widget layer to apply.
///
/// [order]/[priority]/[title] come from `CatalogHomeSectionConfig`
/// (data-driven, Remote-Config-backed), never hardcoded on the page — see
/// `CatalogHomeConfigRepository`.
@freezed
abstract class CatalogHomeSection with _$CatalogHomeSection {
  const CatalogHomeSection._();

  const factory CatalogHomeSection({
    required CatalogHomeSectionType type,
    required String title,
    required int order,
    required int priority,
    @Default(<CatalogHomeItem>[]) List<CatalogHomeItem> items,
  }) = _CatalogHomeSection;

  /// A section with no items must never render an empty title/container on
  /// the home (TASK-076 business rule).
  bool get isEmpty => items.isEmpty;
}
