import 'package:flutter/material.dart';

import '../../foundations/foundations.dart';
import '../../theme/theme.dart';
import '../buttons/app_button.dart';
import '../buttons/app_icon_button.dart';

/// How [AppPagination] presents navigation.
enum AppPaginationMode {
  /// Previous/next arrows around a page indicator (numeric pages, typically
  /// backed by an offset-based repository).
  numeric,

  /// A single "carregar mais" button that appends the next page — the shape
  /// compatible with cursor-based pagination, where the caller only knows
  /// "is there a next cursor?" ([hasMore]), never a total page count.
  loadMore,
}

/// The pagination control every paginated list/table reuses.
///
/// [AppPagination] never owns or fetches the list of items itself — it is a
/// pure control: [onPageChanged]/[onLoadMore] only report user intent
/// (which page/whether to fetch the next cursor). The caller's BLoC/
/// repository decides how to fetch and, critically, *appends* (never
/// discards) previously loaded items — [AppPagination] cannot lose data
/// because it never held any.
///
/// ```dart
/// // Cursor-based "carregar mais", compatible with the repository's cursor
/// // pagination: previously fetched items stay in state, this only adds
/// // more.
/// AppPagination(
///   mode: AppPaginationMode.loadMore,
///   hasMore: state.hasMore,
///   isLoadingMore: state.isLoadingNextPage,
///   onLoadMore: () => bloc.add(LoadNextPage(state.nextCursor)),
/// )
/// ```
class AppPagination extends StatelessWidget {
  const AppPagination({
    super.key,
    this.mode = AppPaginationMode.loadMore,
    this.currentPage = 1,
    this.totalPages,
    this.onPageChanged,
    this.onLoadMore,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.loadMoreLabel = 'Carregar mais',
    this.endOfListLabel = 'Não há mais itens',
    this.previousSemanticLabel = 'Página anterior',
    this.nextSemanticLabel = 'Próxima página',
    this.pageLabelBuilder,
  });

  final AppPaginationMode mode;

  /// 1-based current page. Only meaningful for [AppPaginationMode.numeric].
  final int currentPage;

  /// Total number of pages, when known. `null` keeps the "next" arrow
  /// enabled based on [hasMore] alone (unknown total, cursor-compatible).
  final int? totalPages;

  /// Called with the requested page for [AppPaginationMode.numeric].
  final void Function(int page)? onPageChanged;

  /// Called to fetch the next page/cursor for [AppPaginationMode.loadMore].
  final VoidCallback? onLoadMore;

  /// Whether a next page/cursor is known to exist.
  final bool hasMore;

  /// Shows a loading state on the "carregar mais" button without disabling
  /// the rest of the already-rendered list.
  final bool isLoadingMore;

  final String loadMoreLabel;
  final String endOfListLabel;
  final String previousSemanticLabel;
  final String nextSemanticLabel;

  /// Overrides the "Página X de Y" text. Receives [currentPage] and
  /// [totalPages].
  final String Function(int currentPage, int? totalPages)? pageLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      AppPaginationMode.numeric => _buildNumeric(context),
      AppPaginationMode.loadMore => _buildLoadMore(context),
    };
  }

  Widget _buildNumeric(BuildContext context) {
    final colors = context.colors;
    final canGoPrevious = currentPage > 1;
    final canGoNext = totalPages != null ? currentPage < totalPages! : hasMore;
    final label = pageLabelBuilder != null
        ? pageLabelBuilder!(currentPage, totalPages)
        : (totalPages != null
              ? 'Página $currentPage de $totalPages'
              : 'Página $currentPage');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AppIconButton(
          icon: Icons.chevron_left,
          semanticLabel: previousSemanticLabel,
          isDisabled: !canGoPrevious,
          onPressed: canGoPrevious
              ? () => onPageChanged?.call(currentPage - 1)
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing8),
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: colors.onSurface),
          ),
        ),
        AppIconButton(
          icon: Icons.chevron_right,
          semanticLabel: nextSemanticLabel,
          isDisabled: !canGoNext,
          onPressed: canGoNext
              ? () => onPageChanged?.call(currentPage + 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildLoadMore(BuildContext context) {
    final colors = context.colors;
    if (!hasMore) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
          child: Text(
            endOfListLabel,
            style: AppTypography.bodySmall.copyWith(color: colors.outline),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing16),
        child: AppButton(
          label: loadMoreLabel,
          variant: AppButtonVariant.secondary,
          isLoading: isLoadingMore,
          onPressed: isLoadingMore ? null : onLoadMore,
        ),
      ),
    );
  }
}
