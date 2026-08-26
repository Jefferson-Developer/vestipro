import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../products/domain/entities/catalog_filter.dart';
import '../../../products/domain/value_objects/variant_availability_status.dart';
import '../bloc/catalog_filter_state.dart';

/// The catalog filter form (TASK-082) — reused unchanged in both the
/// desktop side panel and the mobile/tablet `AppBottomSheet`
/// (`AppAdminPageLayout`'s `filtersBuilder` contract), same "one form, two
/// places" precedent `CustomerPortfolioPage`'s `_PortfolioFilters` already
/// sets.
///
/// Edits a local draft and only calls [onApply] when the viewer taps
/// "Aplicar filtros" — never on every keystroke/selection — so a
/// half-typed brand name never triggers a network refetch mid-typing.
///
/// **Faixa de preço is intentionally absent** — see `CatalogFilter`'s class
/// doc: no price-list/pricing-engine exists in VestiPro yet (EPIC-11), so
/// there is nothing real to filter by; showing a control that silently does
/// nothing would be worse than not showing one at all.
class CatalogFilterPanel extends StatefulWidget {
  const CatalogFilterPanel({
    required this.state,
    required this.onApply,
    required this.onClear,
    super.key,
  });

  final CatalogFilterState state;
  final ValueChanged<CatalogFilter> onApply;
  final VoidCallback onClear;

  @override
  State<CatalogFilterPanel> createState() => _CatalogFilterPanelState();
}

class _CatalogFilterPanelState extends State<CatalogFilterPanel> {
  late CatalogFilter _draft;
  late final TextEditingController _brandController;
  late final TextEditingController _tagsController;
  late final TextEditingController _materialController;

  @override
  void initState() {
    super.initState();
    _draft = widget.state.filter;
    _brandController = TextEditingController(text: _draft.brand ?? '');
    _tagsController = TextEditingController(text: _draft.tags.join(', '));
    _materialController = TextEditingController(text: _draft.material ?? '');
  }

  @override
  void didUpdateWidget(covariant CatalogFilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.filter != widget.state.filter) {
      setState(() => _draft = widget.state.filter);
      _brandController.text = _draft.brand ?? '';
      _tagsController.text = _draft.tags.join(', ');
      _materialController.text = _draft.material ?? '';
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _tagsController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppDropdown<String>(
            label: 'Coleção',
            hintText: 'Todas',
            closeSemanticLabel: 'Fechar filtro de coleção',
            options: widget.state.collections
                .map(
                  (collection) => AppDropdownOption<String>(
                    value: collection.id,
                    label: collection.name,
                  ),
                )
                .toList(growable: false),
            selectedValues: <String>{
              if (_draft.collectionId != null) _draft.collectionId!,
            },
            onChanged: (selected) => setState(
              () => _draft = _draft.copyWith(
                collectionId: selected.isEmpty ? null : selected.first,
                clearCollectionId: selected.isEmpty,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<String>(
            label: 'Estação',
            hintText: 'Todas',
            closeSemanticLabel: 'Fechar filtro de estação',
            options: widget.state.seasons
                .map(
                  (season) => AppDropdownOption<String>(
                    value: season.id,
                    label: season.name,
                  ),
                )
                .toList(growable: false),
            selectedValues: <String>{
              if (_draft.seasonId != null) _draft.seasonId!,
            },
            onChanged: (selected) => setState(
              () => _draft = _draft.copyWith(
                seasonId: selected.isEmpty ? null : selected.first,
                clearSeasonId: selected.isEmpty,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<String>(
            label: 'Categoria',
            hintText: 'Todas',
            closeSemanticLabel: 'Fechar filtro de categoria',
            options: widget.state.categories
                .map(
                  (category) => AppDropdownOption<String>(
                    value: category.id,
                    label: category.name,
                  ),
                )
                .toList(growable: false),
            selectedValues: <String>{
              if (_draft.categoryId != null) _draft.categoryId!,
            },
            onChanged: (selected) => setState(
              () => _draft = _draft.copyWith(
                categoryId: selected.isEmpty ? null : selected.first,
                clearCategoryId: selected.isEmpty,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            controller: _brandController,
            label: 'Marca',
            hintText: 'Ex.: Malwee',
            semanticLabel: 'Filtrar por marca',
            onChanged: (value) => _draft = _draft.copyWith(
              brand: value.trim().isEmpty ? null : value,
              clearBrand: value.trim().isEmpty,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<String>(
            label: 'Cor',
            hintText: 'Todas',
            multiple: true,
            closeSemanticLabel: 'Fechar filtro de cor',
            options: widget.state.colors
                .map(
                  (color) => AppDropdownOption<String>(
                    value: color.id,
                    label: color.name,
                  ),
                )
                .toList(growable: false),
            selectedValues: _draft.colorIds,
            onChanged: (selected) =>
                setState(() => _draft = _draft.copyWith(colorIds: selected)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<String>(
            label: 'Tamanho',
            hintText: 'Todos',
            multiple: true,
            closeSemanticLabel: 'Fechar filtro de tamanho',
            options: _sizeOptions(),
            selectedValues: _draft.sizes,
            onChanged: (selected) =>
                setState(() => _draft = _draft.copyWith(sizes: selected)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppDropdown<VariantAvailabilityStatus>(
            label: 'Disponibilidade',
            hintText: 'Todas',
            closeSemanticLabel: 'Fechar filtro de disponibilidade',
            options: const <AppDropdownOption<VariantAvailabilityStatus>>[
              AppDropdownOption<VariantAvailabilityStatus>(
                value: VariantAvailabilityStatus.readyStock,
                label: 'Pronta entrega',
              ),
              AppDropdownOption<VariantAvailabilityStatus>(
                value: VariantAvailabilityStatus.futureStock,
                label: 'Estoque futuro',
              ),
              AppDropdownOption<VariantAvailabilityStatus>(
                value: VariantAvailabilityStatus.unavailable,
                label: 'Indisponível',
              ),
            ],
            selectedValues: <VariantAvailabilityStatus>{
              if (_draft.availability != null) _draft.availability!,
            },
            onChanged: (selected) => setState(
              () => _draft = _draft.copyWith(
                availability: selected.isEmpty ? null : selected.first,
                clearAvailability: selected.isEmpty,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            controller: _tagsController,
            label: 'Tags',
            hintText: 'Separe por vírgula',
            semanticLabel: 'Filtrar por tags',
            onChanged: (value) =>
                _draft = _draft.copyWith(tags: _parseCsv(value)),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppTextField(
            controller: _materialController,
            label: 'Material/tecido',
            hintText: 'Ex.: Algodão',
            semanticLabel: 'Filtrar por material ou tecido',
            onChanged: (value) => _draft = _draft.copyWith(
              material: value.trim().isEmpty ? null : value,
              clearMaterial: value.trim().isEmpty,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing16),
          AppCheckbox(
            value: _draft.launchOnly,
            label: 'Somente lançamentos',
            onChanged: (value) =>
                setState(() => _draft = _draft.copyWith(launchOnly: value)),
          ),
          const SizedBox(height: AppSpacing.spacing24),
          // Stacked (never side-by-side) so each button keeps the full
          // available width — the desktop side panel is only ~232px wide
          // (`AppAdminPageLayout`'s fixed filters panel width), too narrow
          // to fit "Limpar filtros"/"Aplicar filtros" as two half-width
          // buttons without overflowing.
          AppButton(
            label: 'Aplicar filtros',
            expand: true,
            onPressed: () => widget.onApply(_draft.normalized()),
          ),
          const SizedBox(height: AppSpacing.spacing12),
          AppButton(
            label: 'Limpar filtros',
            variant: AppButtonVariant.secondary,
            expand: true,
            onPressed: () {
              setState(() => _draft = CatalogFilter.empty);
              _brandController.clear();
              _tagsController.clear();
              _materialController.clear();
              widget.onClear();
            },
          ),
        ],
      ),
    );
  }

  List<AppDropdownOption<String>> _sizeOptions() {
    final labels = <String>{
      for (final sizes in widget.state.sizeLabelsByTemplateId.values) ...sizes,
    }.toList(growable: false)..sort();
    return labels
        .map((label) => AppDropdownOption<String>(value: label, label: label))
        .toList(growable: false);
  }

  Set<String> _parseCsv(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();
  }
}
