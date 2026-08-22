import 'package:flutter/material.dart';

import '../components/buttons/app_icon_button.dart';
import '../components/overlays/app_bottom_sheet.dart';
import '../foundations/foundations.dart';
import '../theme/theme.dart';
import 'app_responsive_builder.dart';

/// Fixed width of the desktop/large-desktop filters side panel. Not part
/// of [AppSpacing] on purpose: it sizes a whole panel, not a gap/padding.
const double _kFiltersPanelWidth = 280;

/// The single administrative page skeleton every list/management screen
/// (users, clients, products, orders, ...) composes around its own table,
/// grid or form: a header ([title] + [actions]) above the scrollable
/// [content], and — only when [filtersBuilder] is provided — a permanent
/// side panel on desktop/large desktop, or a filter button that opens an
/// [AppBottomSheet] on mobile/tablet. The exact same [filtersBuilder]
/// content renders in both places: there is never a separate mobile-only
/// and desktop-only filters form.
///
/// [AppAdminPageLayout] carries no data-fetching/filtering logic itself —
/// [content] and [filtersBuilder] are both fully built by the caller, and
/// this widget only decides *where* the filters live for the current
/// [AppBreakpoint].
///
/// ```dart
/// AppAdminPageLayout(
///   title: 'Clientes',
///   actions: [
///     AppButton(label: 'Novo cliente', onPressed: () => context.push('/clients/new')),
///   ],
///   filtersBuilder: (context) => const ClientFiltersForm(),
///   content: AppDataTable<Client>(...),
/// )
/// ```
class AppAdminPageLayout extends StatelessWidget {
  const AppAdminPageLayout({
    super.key,
    required this.title,
    required this.content,
    this.actions = const <Widget>[],
    this.filtersBuilder,
    this.filtersTitle = 'Filtros',
    this.filtersButtonSemanticLabel = 'Abrir filtros',
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  /// Builds the filters form, reused unchanged in both the desktop side
  /// panel and the mobile/tablet [AppBottomSheet]. `null` hides every
  /// filter entry point — a page with nothing to filter never shows an
  /// empty button/panel.
  final WidgetBuilder? filtersBuilder;
  final String filtersTitle;
  final String filtersButtonSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBuilder(
      builder: (context, breakpoint) {
        final showsSidePanel =
            filtersBuilder != null &&
            (breakpoint == AppBreakpoint.desktop ||
                breakpoint == AppBreakpoint.largeDesktop);
        final showsFilterButton = filtersBuilder != null && !showsSidePanel;

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeader(context, showsFilterButton: showsFilterButton),
              const SizedBox(height: AppSpacing.spacing16),
              Expanded(
                child: showsSidePanel
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(child: content),
                          const SizedBox(width: AppSpacing.spacing24),
                          SizedBox(
                            width: _kFiltersPanelWidth,
                            child: filtersBuilder!(context),
                          ),
                        ],
                      )
                    : content,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, {required bool showsFilterButton}) {
    final colors = context.colors;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: AppTypography.titleLarge.copyWith(color: colors.onSurface),
          ),
        ),
        if (showsFilterButton) ...<Widget>[
          AppIconButton(
            icon: Icons.filter_list,
            semanticLabel: filtersButtonSemanticLabel,
            onPressed: () => AppBottomSheet.show<void>(
              context: context,
              title: filtersTitle,
              builder: filtersBuilder!,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing8),
        ],
        ...actions,
      ],
    );
  }
}
