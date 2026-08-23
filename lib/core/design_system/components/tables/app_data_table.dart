import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_button.dart';
import '../buttons/app_icon_button.dart';
import '../feedback/app_empty_state.dart';
import '../feedback/app_error_state.dart';
import '../feedback/app_skeleton.dart';
import '../overlays/app_confirmation_dialog.dart';

/// The loading/empty/error lifecycle of [AppDataTable], mirroring the states
/// every BLoC-backed list screen (users, clients, products, orders) already
/// models.
enum AppDataTableStatus {
  /// Real [AppDataTable.rows] are ready to render.
  idle,

  /// Shows [AppDataTable.loadingRowCount] skeleton rows/cards instead of
  /// [AppDataTable.rows].
  loading,

  /// Shows [AppEmptyState] instead of the table/cards.
  empty,

  /// Shows [AppErrorState] instead of the table/cards.
  error,
}

/// A single configurable column of an [AppDataTable]: how its header renders
/// and how a value of type [T] renders inside a cell.
@immutable
class AppDataColumn<T> {
  const AppDataColumn({
    required this.label,
    required this.cellBuilder,
    this.sortable = false,
    this.numeric = false,
  });

  /// The header text. Always caller-provided (i18n-ready).
  final String label;

  /// Builds the cell's content for [item]. The exact same builder is reused
  /// for the mobile card layout — [AppDataTable] never duplicates rendering
  /// logic between its table and card presentation.
  final Widget Function(BuildContext context, T item) cellBuilder;

  /// Whether tapping the header toggles sorting via [AppDataTable.onSort].
  /// Sorting [AppDataTable.rows] itself is always the caller's
  /// responsibility — this component never reorders/calculates data.
  final bool sortable;

  /// Right-aligns the header and cell content (quantities, money, ...).
  final bool numeric;
}

/// A contextual, per-row action (e.g. "ver detalhes", "editar").
@immutable
class AppDataTableAction<T> {
  const AppDataTableAction({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.iconBuilder,
    this.semanticLabelBuilder,
  });

  final IconData icon;
  final String semanticLabel;
  final void Function(T item) onPressed;
  final IconData Function(T item)? iconBuilder;
  final String Function(T item)? semanticLabelBuilder;

  IconData resolvedIcon(T item) => iconBuilder?.call(item) ?? icon;

  String resolvedSemanticLabel(T item) =>
      semanticLabelBuilder?.call(item) ?? semanticLabel;
}

/// A bulk action available once at least one row is selected.
///
/// When [isDestructive] is `true`, [AppDataTable] always confirms via
/// [AppConfirmationDialog] before calling [onConfirmed] — no caller may
/// replace that confirmation with a bespoke dialog/snackbar (see
/// `AppConfirmationDialog`'s own contract).
@immutable
class AppDataTableBatchAction {
  const AppDataTableBatchAction({
    required this.label,
    required this.onConfirmed,
    this.icon,
    this.isDestructive = false,
    this.confirmationTitle,
    this.confirmationMessage,
    this.confirmLabel,
  }) : assert(
         !isDestructive ||
             (confirmationTitle != null &&
                 confirmationMessage != null &&
                 confirmLabel != null),
         'Destructive batch actions must provide confirmationTitle, '
         'confirmationMessage and confirmLabel so AppConfirmationDialog can '
         'be shown before onConfirmed runs.',
       );

  final String label;
  final IconData? icon;

  /// Whether this action is irreversible (e.g. "excluir selecionados").
  final bool isDestructive;
  final String? confirmationTitle;
  final String? confirmationMessage;
  final String? confirmLabel;

  /// Called with the selected row ids once the action is authorized (either
  /// immediately, or after the user confirms the [AppConfirmationDialog]).
  final void Function(Set<Object> selectedIds) onConfirmed;
}

/// The administrative table every list screen (users, clients, products,
/// orders) and dashboard reuses: configurable [columns], optional sorting,
/// batch selection with [batchActions], per-row [rowActions], and the
/// loading/empty/error states already standardized by
/// [AppSkeleton]/[AppEmptyState]/[AppErrorState].
///
/// Below the mobile breakpoint it never renders as a horizontally-scrolling
/// table: a [LayoutBuilder] converts every row into a card built from the
/// exact same [AppDataColumn.cellBuilder]s, so there is only ever one
/// implementation of "how a row renders" — never a second, bespoke mobile
/// screen.
///
/// Fully controlled: [rows], [status], [selectedIds] and sort state all come
/// from the caller (typically a `BlocBuilder`). [AppDataTable] never fetches,
/// sorts, filters or paginates data itself — it only renders what it is
/// given and reports user intent back via callbacks.
///
/// ```dart
/// AppDataTable<Client>(
///   status: state.status,
///   rows: state.clients,
///   rowIdBuilder: (client) => client.id,
///   columns: [
///     AppDataColumn(label: 'Cliente', cellBuilder: (_, c) => Text(c.name)),
///     AppDataColumn(label: 'Cidade', cellBuilder: (_, c) => Text(c.city)),
///   ],
///   rowActions: [
///     AppDataTableAction(
///       icon: Icons.visibility_outlined,
///       semanticLabel: 'Ver detalhes',
///       onPressed: (c) => context.push('/clients/${c.id}'),
///     ),
///   ],
///   selectable: true,
///   selectedIds: state.selectedClientIds,
///   onSelectionChanged: (ids) => bloc.add(SelectClients(ids)),
///   batchActions: [
///     AppDataTableBatchAction(
///       label: 'Excluir selecionados',
///       icon: Icons.delete_outline,
///       isDestructive: true,
///       confirmationTitle: 'Excluir clientes?',
///       confirmationMessage: 'Esta ação não pode ser desfeita.',
///       confirmLabel: 'Excluir',
///       onConfirmed: (ids) => bloc.add(DeleteClients(ids)),
///     ),
///   ],
/// )
/// ```
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowIdBuilder,
    this.status = AppDataTableStatus.idle,
    this.rowActions = const [],
    this.selectable = false,
    this.selectedIds = const {},
    this.onSelectionChanged,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.batchActions = const [],
    this.loadingRowCount = 5,
    this.maxHeight,
    this.emptyTitle = 'Nenhum registro encontrado',
    this.emptyDescription,
    this.errorTitle = 'Não foi possível carregar os dados',
    this.errorMessage,
    this.retryLabel,
    this.onRetry,
    this.selectAllSemanticLabel = 'Selecionar todos',
    this.mobileCardTitleBuilder,
  });

  final List<AppDataColumn<T>> columns;
  final List<T> rows;

  /// The stable identity of a row, used for selection tracking. Must be
  /// unique and stable across rebuilds (e.g. an entity id).
  final Object Function(T item) rowIdBuilder;

  final AppDataTableStatus status;
  final List<AppDataTableAction<T>> rowActions;

  final bool selectable;
  final Set<Object> selectedIds;
  final ValueChanged<Set<Object>>? onSelectionChanged;

  /// Index into [columns] currently driving the sort, or `null` if unsorted.
  /// Purely visual (renders the sort arrow) — [AppDataTable] never reorders
  /// [rows] itself.
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;

  final List<AppDataTableBatchAction> batchActions;

  /// Number of skeleton rows/cards rendered while [status] is
  /// [AppDataTableStatus.loading].
  final int loadingRowCount;

  /// When set, the table body scrolls independently inside a fixed-height
  /// region while the header stays visible above it — the classic
  /// "sticky header" data-grid layout. When `null` (default), the header
  /// and every row size to their content (no internal scrolling), so the
  /// table composes safely inside an already-scrollable page.
  final double? maxHeight;

  final String emptyTitle;
  final String? emptyDescription;
  final String errorTitle;
  final String? errorMessage;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final String selectAllSemanticLabel;

  /// Overrides the prominent title of the mobile card for [item]. Defaults
  /// to the first column's cell.
  final Widget Function(BuildContext context, T item)? mobileCardTitleBuilder;

  bool get _allSelected =>
      rows.isNotEmpty &&
      rows.every((row) => selectedIds.contains(rowIdBuilder(row)));

  bool get _anySelected =>
      rows.any((row) => selectedIds.contains(rowIdBuilder(row)));

  void _toggleSelectAll(bool? value) {
    if (onSelectionChanged == null) {
      return;
    }
    if (value ?? false) {
      onSelectionChanged!(rows.map(rowIdBuilder).toSet());
    } else {
      onSelectionChanged!(const {});
    }
  }

  void _toggleRow(Object id, bool? value) {
    if (onSelectionChanged == null) {
      return;
    }
    final next = Set<Object>.of(selectedIds);
    if (value ?? false) {
      next.add(id);
    } else {
      next.remove(id);
    }
    onSelectionChanged!(next);
  }

  Future<void> _handleBatchAction(
    BuildContext context,
    AppDataTableBatchAction action,
  ) async {
    if (!action.isDestructive) {
      action.onConfirmed(selectedIds);
      return;
    }
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: action.confirmationTitle!,
      message: action.confirmationMessage!,
      confirmLabel: action.confirmLabel!,
    );
    if (confirmed) {
      action.onConfirmed(selectedIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AppDataTableStatus.error:
        return AppErrorState(
          title: errorTitle,
          message: errorMessage ?? '',
          retryLabel: onRetry != null
              ? (retryLabel ?? 'Tentar novamente')
              : null,
          onRetry: onRetry,
        );
      case AppDataTableStatus.empty:
        return AppEmptyState(title: emptyTitle, description: emptyDescription);
      case AppDataTableStatus.loading:
      case AppDataTableStatus.idle:
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile =
            AppBreakpoints.resolve(constraints.maxWidth) ==
            AppBreakpoint.mobile;
        final content = isMobile
            ? _buildCardList(context)
            : _buildTable(context);

        if (batchActions.isEmpty || !selectable) {
          return content;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (_anySelected) _buildBatchActionsBar(context),
            content,
          ],
        );
      },
    );
  }

  Widget _buildBatchActionsBar(BuildContext context) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.spacing8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.radius8),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '${selectedIds.length} selecionado(s)',
              style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
            ),
          ),
          Wrap(
            spacing: AppSpacing.spacing8,
            children: batchActions
                .map(
                  (action) => AppButton(
                    label: action.label,
                    leadingIcon: action.icon,
                    variant: action.isDestructive
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.secondary,
                    onPressed: () => _handleBatchAction(context, action),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final colors = context.colors;
    final header = _buildHeaderRow(context);
    final body = status == AppDataTableStatus.loading
        ? _buildLoadingTableRows(context)
        : Column(
            children: List<Widget>.generate(
              rows.length,
              (index) => _buildTableRow(context, rows[index], index),
            ),
          );

    final table = DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline.withValues(alpha: 0.24)),
        borderRadius: BorderRadius.circular(AppRadius.radius12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            header,
            if (maxHeight != null)
              SizedBox(
                height: maxHeight,
                child: SingleChildScrollView(child: body),
              )
            else
              body,
          ],
        ),
      ),
    );

    return table;
  }

  Widget _buildHeaderRow(BuildContext context) {
    final colors = context.colors;
    return Container(
      color: colors.surfaceContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing12,
      ),
      child: Row(
        children: <Widget>[
          if (selectable)
            SizedBox(
              width: AppSpacing.spacing48,
              child: Checkbox(
                value: _allSelected ? true : (_anySelected ? null : false),
                tristate: true,
                onChanged: _toggleSelectAll,
                semanticLabel: selectAllSemanticLabel,
              ),
            ),
          for (var i = 0; i < columns.length; i++)
            Expanded(child: _buildHeaderCell(context, columns[i], i)),
          if (rowActions.isNotEmpty)
            SizedBox(width: AppSpacing.spacing48 * rowActions.length),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    BuildContext context,
    AppDataColumn<T> column,
    int index,
  ) {
    final colors = context.colors;
    final isSorted = sortColumnIndex == index;
    final label = Text(
      column.label,
      style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
    );

    if (!column.sortable) {
      return Align(
        alignment: column.numeric
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: label,
      );
    }

    return InkWell(
      onTap: () => onSort?.call(index, isSorted ? !sortAscending : true),
      child: Row(
        mainAxisAlignment: column.numeric
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          label,
          const SizedBox(width: AppSpacing.spacing4),
          Icon(
            isSorted
                ? (sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: AppIconSizes.sm,
            color: isSorted ? colors.primary : colors.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, T item, int index) {
    final colors = context.colors;
    final id = rowIdBuilder(item);
    final isSelected = selectedIds.contains(id);

    return Container(
      key: ValueKey(id),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer.withValues(alpha: 0.4)
            : null,
        border: Border(
          top: BorderSide(color: colors.outline.withValues(alpha: 0.16)),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing16,
        vertical: AppSpacing.spacing12,
      ),
      child: Row(
        children: <Widget>[
          if (selectable)
            SizedBox(
              width: AppSpacing.spacing48,
              child: Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleRow(id, value),
              ),
            ),
          for (final column in columns)
            Expanded(
              child: Align(
                alignment: column.numeric
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: column.cellBuilder(context, item),
              ),
            ),
          if (rowActions.isNotEmpty)
            SizedBox(
              width: AppSpacing.spacing48 * rowActions.length,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: rowActions
                    .map(
                      (action) => AppIconButton(
                        icon: action.resolvedIcon(item),
                        semanticLabel: action.resolvedSemanticLabel(item),
                        variant: AppButtonVariant.text,
                        onPressed: () => action.onPressed(item),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingTableRows(BuildContext context) {
    return Column(
      children: List<Widget>.generate(
        loadingRowCount,
        (index) => Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing16,
            vertical: AppSpacing.spacing12,
          ),
          child: Row(
            children: <Widget>[
              if (selectable) const SizedBox(width: AppSpacing.spacing48),
              for (var i = 0; i < columns.length; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.spacing16),
                    child: const AppSkeleton.line(),
                  ),
                ),
              if (rowActions.isNotEmpty)
                SizedBox(width: AppSpacing.spacing48 * rowActions.length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardList(BuildContext context) {
    final children = status == AppDataTableStatus.loading
        ? List<Widget>.generate(
            loadingRowCount,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.spacing12),
              child: AppSkeleton.card(),
            ),
          )
        : List<Widget>.generate(
            rows.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.spacing12),
              child: _buildCard(context, rows[index]),
            ),
          );

    return Column(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _buildCard(BuildContext context, T item) {
    final colors = context.colors;
    final id = rowIdBuilder(item);
    final isSelected = selectedIds.contains(id);
    final title = mobileCardTitleBuilder != null
        ? mobileCardTitleBuilder!(context, item)
        : columns.first.cellBuilder(context, item);
    final fieldColumns = mobileCardTitleBuilder != null
        ? columns
        : columns.skip(1).toList(growable: false);

    return Container(
      key: ValueKey(id),
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer.withValues(alpha: 0.4)
            : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.radius12),
        border: Border.all(color: colors.outline.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (selectable)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleRow(id, value),
                ),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.onSurface,
                  ),
                  child: title,
                ),
              ),
              for (final action in rowActions)
                AppIconButton(
                  icon: action.resolvedIcon(item),
                  semanticLabel: action.resolvedSemanticLabel(item),
                  variant: AppButtonVariant.text,
                  onPressed: () => action.onPressed(item),
                ),
            ],
          ),
          if (fieldColumns.isNotEmpty)
            const SizedBox(height: AppSpacing.spacing8),
          for (final column in fieldColumns)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.spacing4,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    '${column.label}: ',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.outline,
                    ),
                  ),
                  Expanded(child: column.cellBuilder(context, item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
