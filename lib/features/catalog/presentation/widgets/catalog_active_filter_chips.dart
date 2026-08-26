import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../products/domain/value_objects/catalog_filter_key.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../bloc/catalog_filter_state.dart';

/// One row of removable chips (TASK-082), one per active `CatalogFilter`
/// dimension/value — a set-valued dimension (cor/tamanho/tag) shows one
/// chip per selected value, individually removable, never a single chip for
/// the whole dimension. Resolves an id-based chip's label (coleção, estação,
/// categoria, cor) against `CatalogFilterState`'s already-loaded reference
/// vocabulary; a free-text dimension (marca, material) shows its raw value.
class CatalogActiveFilterChips extends StatelessWidget {
  const CatalogActiveFilterChips({
    required this.state,
    required this.onRemove,
    super.key,
  });

  final CatalogFilterState state;
  final void Function(CatalogFilterKey key, {String? value}) onRemove;

  @override
  Widget build(BuildContext context) {
    final entries = state.filter.activeEntries();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.spacing8,
      runSpacing: AppSpacing.spacing8,
      children: entries
          .map(
            (entry) => AppFilterChip(
              label: _labelFor(entry.$1, entry.$2),
              onRemove: () => onRemove(entry.$1, value: entry.$2),
            ),
          )
          .toList(growable: false),
    );
  }

  String _labelFor(CatalogFilterKey key, String value) {
    return switch (key) {
      CatalogFilterKey.collection => _nameOr(
        value,
        state.collections,
        (c) => c.id,
        (c) => c.name,
      ),
      CatalogFilterKey.season => _nameOr(
        value,
        state.seasons,
        (s) => s.id,
        (s) => s.name,
      ),
      CatalogFilterKey.category => _nameOr(
        value,
        state.categories,
        (c) => c.id,
        (c) => c.name,
      ),
      CatalogFilterKey.color => _nameOr(
        value,
        state.colors,
        (c) => c.id,
        (c) => c.name,
      ),
      CatalogFilterKey.brand => 'Marca: $value',
      CatalogFilterKey.size => 'Tamanho: $value',
      CatalogFilterKey.tag => 'Tag: $value',
      CatalogFilterKey.material => 'Material: $value',
      CatalogFilterKey.launch => 'Somente lançamentos',
      CatalogFilterKey.availability => _availabilityLabel(value),
    };
  }

  String _nameOr<T>(
    String id,
    List<T> items,
    String Function(T) idOf,
    String Function(T) nameOf,
  ) {
    for (final item in items) {
      if (idOf(item) == id) return nameOf(item);
    }
    return id;
  }

  String _availabilityLabel(String code) {
    return switch (VariantAvailabilityStatus.values.where(
      (status) => status.name == code,
    )) {
      final matches when matches.isNotEmpty => switch (matches.first) {
        VariantAvailabilityStatus.readyStock => 'Pronta entrega',
        VariantAvailabilityStatus.futureStock => 'Estoque futuro',
        VariantAvailabilityStatus.unavailable => 'Indisponível',
      },
      _ => code,
    };
  }
}
