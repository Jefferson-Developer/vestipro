import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../entities/pack_component.dart';
import '../entities/resolved_pack_line.dart';
import '../value_objects/pack_component_composition_type.dart';
import 'pack_component_variant_resolver.dart';

/// Turns a flat list of non-nested `PackComponent`s (TASK-207) — already
/// resolved to concrete sellable variants by a
/// [PackComponentVariantResolver] — into the exact per-variant quantities one
/// instance of the owning `CommercialPack` requires (TASK-208, EPIC-32).
///
/// Deliberately a pure, static function with no repository/resolver
/// dependency of its own: [ExpandCommercialPackToOrderItemsUseCase]
/// (`lib/features/orders`) and `GetCommercialPackAvailabilityUseCase` both
/// need this exact same math (quantity required per resolved variant), and
/// neither should re-derive it independently — same "não duplicar regra já
/// existente" rule (`AGENTS.md`) this class exists to satisfy.
///
/// [PackComponentScopeType.commercialPack] components are never passed to
/// [compose] — nesting one pack inside another needs the nested pack's own
/// recursive expansion (a different pack's components, its own quantities
/// multiplied by the outer component's), which only
/// `ExpandCommercialPackToOrderItemsUseCase` performs.
final class CommercialPackComposer {
  const CommercialPackComposer._();

  /// [resolvedVariantsByComponent] must carry one entry per
  /// [components] id (the `PackComponentVariantResolver` result for that
  /// component's scope) — a missing or empty entry means "nothing sellable
  /// currently matches this component" and fails the whole composition
  /// (never silently drops the component).
  ///
  /// [quantityOverridesByComponent] lets a seller adjust a `flexible`
  /// component's quantity (per resolved variant) within its own
  /// `PackComponent.minQuantity`/`maxQuantity` — a value outside that range
  /// fails. Omitting an override for a flexible component defaults to its
  /// `minQuantity`.
  ///
  /// [totalGridQuantity] is required the moment any component uses
  /// [PackComponentCompositionType.gridProportion] — the absolute "peças
  /// totais do sortimento" its `proportion`s are a fraction of. Its integer
  /// quantity is distributed across every variant that component resolved
  /// to, largest remainder first, so per-variant quantities always sum
  /// exactly to `round(proportion * totalGridQuantity)`.
  static AppResult<List<ResolvedPackLine>> compose({
    required List<PackComponent> components,
    required Map<String, List<ResolvedComponentVariant>>
    resolvedVariantsByComponent,
    Map<String, int>? quantityOverridesByComponent,
    int? totalGridQuantity,
  }) {
    final lines = <ResolvedPackLine>[];
    final fieldErrors = <String, String>{};

    for (var index = 0; index < components.length; index++) {
      final component = components[index];
      final prefix = 'components[$index]';
      final resolvedVariants = resolvedVariantsByComponent[component.id];
      if (resolvedVariants == null || resolvedVariants.isEmpty) {
        fieldErrors['$prefix.scopeReferenceId'] =
            'No currently sellable variant matches this component.';
        continue;
      }

      switch (component.compositionType) {
        case PackComponentCompositionType.fixed:
          final quantity = component.quantity ?? 0;
          if (quantity <= 0) {
            fieldErrors['$prefix.quantity'] =
                'Fixed component quantity must be greater than zero.';
            continue;
          }
          for (final variant in resolvedVariants) {
            lines.add(
              ResolvedPackLine(
                componentId: component.id,
                variantId: variant.variantId,
                productId: variant.productId,
                quantity: quantity,
                isBonusItem: component.isBonusItem,
              ),
            );
          }
        case PackComponentCompositionType.flexible:
          final minQuantity = component.minQuantity ?? 0;
          final maxQuantity = component.maxQuantity ?? 0;
          final requested =
              quantityOverridesByComponent?[component.id] ?? minQuantity;
          if (minQuantity <= 0 ||
              maxQuantity <= 0 ||
              minQuantity > maxQuantity) {
            fieldErrors['$prefix.maxQuantity'] =
                'Flexible component has no valid minQuantity/maxQuantity '
                'range.';
            continue;
          }
          if (requested < minQuantity || requested > maxQuantity) {
            fieldErrors['$prefix.quantity'] =
                'Requested quantity must stay between $minQuantity and '
                '$maxQuantity.';
            continue;
          }
          for (final variant in resolvedVariants) {
            lines.add(
              ResolvedPackLine(
                componentId: component.id,
                variantId: variant.variantId,
                productId: variant.productId,
                quantity: requested,
                isBonusItem: component.isBonusItem,
              ),
            );
          }
        case PackComponentCompositionType.gridProportion:
          final proportion = component.proportion;
          if (proportion == null || proportion <= 0 || proportion > 1) {
            fieldErrors['$prefix.proportion'] =
                'Grid proportion must be greater than zero and at most 1.';
            continue;
          }
          if (totalGridQuantity == null || totalGridQuantity <= 0) {
            fieldErrors['totalGridQuantity'] =
                'totalGridQuantity is required when any component uses '
                'gridProportion.';
            continue;
          }
          final absoluteQuantity = (proportion * totalGridQuantity).round();
          if (absoluteQuantity <= 0) {
            fieldErrors['$prefix.proportion'] =
                'This proportion rounds to zero units for the requested '
                'totalGridQuantity.';
            continue;
          }
          for (final line in _distributeEvenly(
            component: component,
            variants: resolvedVariants,
            totalQuantity: absoluteQuantity,
          )) {
            lines.add(line);
          }
      }
    }

    if (fieldErrors.isNotEmpty) {
      return AppFailure<List<ResolvedPackLine>>(
        ValidationFailure(
          'Unable to compose this commercial pack right now.',
          code: 'commercial_pack_composition_unresolved',
          fieldErrors: fieldErrors,
        ),
      );
    }

    return AppSuccess<List<ResolvedPackLine>>(
      List<ResolvedPackLine>.unmodifiable(lines),
    );
  }

  /// Splits [totalQuantity] as evenly as possible across [variants] —
  /// `totalQuantity ~/ variants.length` each, with the remainder (largest
  /// remainder method, applied in resolver order for determinism) handed one
  /// extra unit each so the per-variant quantities always sum back to
  /// exactly [totalQuantity].
  static List<ResolvedPackLine> _distributeEvenly({
    required PackComponent component,
    required List<ResolvedComponentVariant> variants,
    required int totalQuantity,
  }) {
    final baseQuantity = totalQuantity ~/ variants.length;
    var remainder = totalQuantity % variants.length;
    final lines = <ResolvedPackLine>[];
    for (final variant in variants) {
      final extra = remainder > 0 ? 1 : 0;
      if (remainder > 0) remainder--;
      final quantity = baseQuantity + extra;
      if (quantity <= 0) continue;
      lines.add(
        ResolvedPackLine(
          componentId: component.id,
          variantId: variant.variantId,
          productId: variant.productId,
          quantity: quantity,
          isBonusItem: component.isBonusItem,
        ),
      );
    }
    return lines;
  }
}
