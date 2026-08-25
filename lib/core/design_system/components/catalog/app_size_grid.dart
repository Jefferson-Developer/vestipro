import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../overlays/app_tooltip.dart';

/// Whether a single color/size cell of an [AppSizeGrid] can currently take
/// a quantity.
enum AppSizeGridCellAvailability {
  /// Ships from stock on hand — the default; the quantity field is editable.
  readyStock,

  /// Only available from a future stock arrival — still editable, but
  /// flagged with a "estoque futuro" indicator so the rep can set
  /// expectations with the client.
  futureStock,

  /// Cannot be sold at all for this color/size — the quantity field is
  /// replaced by a non-editable "indisponível" indicator (never a blank
  /// cell, so it never looks like a data-loading gap).
  unavailable,
}

/// A single color/size cell's data: the already-typed [quantity] and its
/// [availability]. [AppSizeGrid] never computes/validates stock, price or
/// order totals from this — it only renders it and reports quantity
/// changes back via [AppSizeGrid.onQuantityChanged].
@immutable
class AppSizeGridCell {
  const AppSizeGridCell({
    this.quantity = 0,
    this.availability = AppSizeGridCellAvailability.readyStock,
    this.availabilityLabel,
  });

  final int quantity;
  final AppSizeGridCellAvailability availability;
  final String? availabilityLabel;
}

/// A single size column of an [AppSizeGrid] (e.g. "P", "M", "38", "40").
@immutable
class AppSizeGridColumn {
  const AppSizeGridColumn({required this.id, required this.label});

  final Object id;
  final String label;
}

/// A single color row of an [AppSizeGrid]: [cells] is keyed by
/// [AppSizeGridColumn.id] — a missing key means "no cell rendered for that
/// size", not "quantity zero" (use an explicit [AppSizeGridCell] with
/// `quantity: 0` for that).
@immutable
class AppSizeGridRow {
  const AppSizeGridRow({
    required this.id,
    required this.label,
    required this.cells,
    this.colorSwatch,
  });

  final Object id;
  final String label;

  /// The row's color chip, purely decorative (next to [label], never the
  /// only way the color is identified).
  final Color? colorSwatch;

  final Map<Object, AppSizeGridCell> cells;
}

/// The color × size commercial grid every catalog/order screen reuses for
/// fast, grid-shaped quantity entry.
///
/// Fully controlled: [rows]/[columns] always come from the caller's
/// BLoC/domain state, and [onQuantityChanged] only reports
/// `(rowId, columnId, quantity)` — this widget never calculates price,
/// discount or order totals; the "Total" row/column it renders are a plain
/// sum of the already-given [AppSizeGridCell.quantity] values, purely as a
/// typing aid (per `tasks.md` §26 — "totais sempre visíveis durante a
/// digitação").
///
/// Each cell keeps its own [TextEditingController] keyed by
/// `(row.id, column.id)`, so as long as the caller keeps the same rows/
/// columns identities across a rebuild (e.g. a rebuild triggered by an
/// unrelated connectivity/sync banner elsewhere on the screen), Flutter
/// reuses that cell's [State] and an in-progress keystroke is never lost —
/// even before it is committed to [onQuantityChanged].
///
/// Row labels stay pinned on the left and the row/grand totals stay pinned
/// on the right; only the size columns in between scroll horizontally, so
/// this fits a phone-width screen with a long size run without losing
/// context of which color/total a value belongs to.
///
/// ```dart
/// AppSizeGrid(
///   columns: state.sizes.map((s) => AppSizeGridColumn(id: s.id, label: s.label)).toList(),
///   rows: state.colors.map((c) => AppSizeGridRow(
///     id: c.id,
///     label: c.label,
///     colorSwatch: c.swatch,
///     cells: c.cellsBySizeId,
///   )).toList(),
///   onQuantityChanged: (colorId, sizeId, quantity) =>
///       bloc.add(GradeQuantityChanged(colorId, sizeId, quantity)),
/// )
/// ```
class AppSizeGrid extends StatelessWidget {
  const AppSizeGrid({
    super.key,
    required this.columns,
    required this.rows,
    required this.onQuantityChanged,
    this.columnWidth,
    this.rowLabelWidth = AppSpacing.spacing64 * 1.5,
    this.rowTotalLabel = 'Total',
    this.grandTotalLabel = 'Total geral',
    this.unavailableLabel = 'Indisponível',
    this.futureStockLabel = 'Estoque futuro',
  });

  final List<AppSizeGridColumn> columns;
  final List<AppSizeGridRow> rows;

  /// Reports the user's intended next quantity for `(rowId, columnId)`.
  /// Called on every keystroke (so the caller's domain state — the single
  /// source of truth — can persist it immediately, surviving a lost
  /// connection) and is never called with a value the caller did not type
  /// (this widget applies no clamping/rounding of its own).
  final void Function(Object rowId, Object columnId, int quantity)
  onQuantityChanged;

  /// Width of a single size column. Defaults to a breakpoint-aware value
  /// (narrower on mobile, wider on tablet/desktop) so the grid never just
  /// stretches the mobile layout.
  final double? columnWidth;

  final double rowLabelWidth;
  final String rowTotalLabel;
  final String grandTotalLabel;
  final String unavailableLabel;
  final String futureStockLabel;

  int _columnTotal(AppSizeGridColumn column) =>
      rows.fold(0, (sum, row) => sum + (row.cells[column.id]?.quantity ?? 0));

  int _rowTotal(AppSizeGridRow row) =>
      row.cells.values.fold(0, (sum, cell) => sum + cell.quantity);

  int get _grandTotal => rows.fold(0, (sum, row) => sum + _rowTotal(row));

  double _resolveColumnWidth(BuildContext context) {
    if (columnWidth != null) {
      return columnWidth!;
    }
    return context.breakpoint == AppBreakpoint.mobile
        ? AppSpacing.spacing48
        : AppSpacing.spacing64;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final resolvedColumnWidth = _resolveColumnWidth(context);

    return Semantics(
      label: 'Grade de tamanhos',
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline.withValues(alpha: 0.24)),
          borderRadius: BorderRadius.circular(AppRadius.radius12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(
                      width: rowLabelWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: AppSpacing.spacing40),
                          for (final row in rows) _buildRowLabel(context, row),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                for (final column in columns)
                                  _buildColumnHeader(
                                    context,
                                    column,
                                    resolvedColumnWidth,
                                  ),
                              ],
                            ),
                            for (final row in rows)
                              Row(
                                children: <Widget>[
                                  for (final column in columns)
                                    _buildCell(
                                      context,
                                      row,
                                      column,
                                      resolvedColumnWidth,
                                    ),
                                ],
                              ),
                            _buildColumnTotalsRow(context, resolvedColumnWidth),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: rowLabelWidth * 0.7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          _buildHeaderText(context, rowTotalLabel),
                          for (final row in rows)
                            _buildTotalText(
                              context,
                              _rowTotal(row),
                              key: Key('app_size_grid_row_total_${row.id}'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: AppSpacing.spacing24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    grandTotalLabel,
                    style: AppTypography.labelLarge.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    '$_grandTotal',
                    key: const Key('app_size_grid_grand_total'),
                    style: AppTypography.titleMedium.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderText(BuildContext context, String label) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
      child: SizedBox(
        height: AppSpacing.spacing40 - AppSpacing.spacing16,
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(color: colors.outline),
        ),
      ),
    );
  }

  Widget _buildTotalText(BuildContext context, int total, {Key? key}) {
    final colors = context.colors;
    return SizedBox(
      height: AppSpacing.spacing48,
      child: Center(
        child: Text(
          '$total',
          key: key,
          style: AppTypography.labelLarge.copyWith(color: colors.onSurface),
        ),
      ),
    );
  }

  Widget _buildRowLabel(BuildContext context, AppSizeGridRow row) {
    final colors = context.colors;
    return SizedBox(
      height: AppSpacing.spacing48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (row.colorSwatch != null) ...<Widget>[
            Container(
              width: AppSpacing.spacing16,
              height: AppSpacing.spacing16,
              decoration: BoxDecoration(
                color: row.colorSwatch,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outline),
              ),
            ),
            const SizedBox(width: AppSpacing.spacing8),
          ],
          Expanded(
            child: Text(
              row.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(
    BuildContext context,
    AppSizeGridColumn column,
    double width,
  ) {
    final colors = context.colors;
    return SizedBox(
      width: width,
      height: AppSpacing.spacing40,
      child: Center(
        child: Text(
          column.label,
          style: AppTypography.labelMedium.copyWith(color: colors.onSurface),
        ),
      ),
    );
  }

  Widget _buildColumnTotalsRow(BuildContext context, double width) {
    final colors = context.colors;
    return Row(
      children: <Widget>[
        for (final column in columns)
          SizedBox(
            width: width,
            height: AppSpacing.spacing40,
            child: Center(
              child: Text(
                '${_columnTotal(column)}',
                key: Key('app_size_grid_column_total_${column.id}'),
                style: AppTypography.labelMedium.copyWith(
                  color: colors.outline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCell(
    BuildContext context,
    AppSizeGridRow row,
    AppSizeGridColumn column,
    double width,
  ) {
    final cell = row.cells[column.id];
    if (cell == null) {
      return SizedBox(width: width, height: AppSpacing.spacing48);
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      child: _AppSizeGridCellField(
        key: ValueKey('${row.id}_${column.id}'),
        cell: cell,
        width: width - AppSpacing.spacing8,
        semanticLabel: '${row.label} ${column.label}',
        unavailableLabel: unavailableLabel,
        futureStockLabel: futureStockLabel,
        availabilityLabel: cell.availabilityLabel,
        onChanged: (quantity) => onQuantityChanged(row.id, column.id, quantity),
      ),
    );
  }
}

/// A single editable quantity field inside [AppSizeGrid], statefully
/// preserving whatever the user has typed via a per-cell
/// [TextEditingController] that outlives unrelated parent rebuilds (see
/// [AppSizeGrid]'s class doc).
class _AppSizeGridCellField extends StatefulWidget {
  const _AppSizeGridCellField({
    required super.key,
    required this.cell,
    required this.width,
    required this.semanticLabel,
    required this.unavailableLabel,
    required this.futureStockLabel,
    required this.availabilityLabel,
    required this.onChanged,
  });

  final AppSizeGridCell cell;
  final double width;
  final String semanticLabel;
  final String unavailableLabel;
  final String futureStockLabel;
  final String? availabilityLabel;
  final ValueChanged<int> onChanged;

  @override
  State<_AppSizeGridCellField> createState() => _AppSizeGridCellFieldState();
}

class _AppSizeGridCellFieldState extends State<_AppSizeGridCellField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _textFor(widget.cell.quantity));
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  String _textFor(int quantity) => quantity == 0 ? '' : '$quantity';

  @override
  void didUpdateWidget(covariant _AppSizeGridCellField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        oldWidget.cell.quantity != widget.cell.quantity) {
      _controller.text = _textFor(widget.cell.quantity);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _commit(_controller.text);
    }
  }

  void _commit(String rawValue) {
    final parsed = int.tryParse(rawValue) ?? 0;
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    if (widget.cell.availability == AppSizeGridCellAvailability.unavailable) {
      final unavailableMessage =
          widget.availabilityLabel ?? widget.unavailableLabel;
      return SizedBox(
        width: widget.width,
        height: AppSpacing.spacing48,
        child: Center(
          child: AppTooltip(
            message: unavailableMessage,
            child: Semantics(
              label: '${widget.semanticLabel}: $unavailableMessage',
              child: Icon(
                Icons.block,
                size: AppIconSizes.md,
                color: colors.outline,
              ),
            ),
          ),
        ),
      );
    }

    final isFutureStock =
        widget.cell.availability == AppSizeGridCellAvailability.futureStock;
    final futureStockMessage =
        widget.availabilityLabel ?? widget.futureStockLabel;

    return SizedBox(
      width: widget.width,
      height: AppSpacing.spacing48,
      child: Stack(
        children: <Widget>[
          Semantics(
            label: isFutureStock
                ? '${widget.semanticLabel}: $futureStockMessage'
                : widget.semanticLabel,
            textField: true,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              textInputAction: TextInputAction.next,
              onChanged: _commit,
              // Providing `onEditingComplete` opts out of TextField's
              // default "unfocus on submit" behavior, so our own
              // `nextFocus()` call below is the only thing deciding where
              // focus lands next — advancing to the next size/color cell
              // instead of dismissing the keyboard.
              onEditingComplete: () => FocusScope.of(context).nextFocus(),
              style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
              decoration: InputDecoration(
                isDense: true,
                hintText: '0',
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.spacing12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radius8),
                  borderSide: BorderSide(
                    color: colors.outline.withValues(alpha: 0.32),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.radius8),
                  borderSide: BorderSide(color: colors.primary),
                ),
              ),
            ),
          ),
          if (isFutureStock)
            Positioned(
              top: 0,
              right: 0,
              child: AppTooltip(
                message: futureStockMessage,
                child: Icon(
                  Icons.schedule,
                  size: AppIconSizes.sm,
                  color: colors.warning,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
