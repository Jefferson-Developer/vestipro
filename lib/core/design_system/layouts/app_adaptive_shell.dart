import 'dart:async';

import 'package:flutter/material.dart';

import '../components/buttons/app_icon_button.dart';
import '../components/overlays/app_bottom_sheet.dart';
import '../foundations/foundations.dart';
import '../theme/theme.dart';
import 'app_nav_destination.dart';
import 'app_responsive_builder.dart';

/// Fixed width of the collapsed desktop/large-desktop sidebar. Not part of
/// [AppSpacing] on purpose: it sizes a whole navigation rail, not a
/// gap/padding.
const double _kCollapsedSidebarWidth = 72;

/// Fixed width of the expanded desktop/large-desktop sidebar.
const double _kExpandedSidebarWidth = 240;

/// Minimum content width (icon + spacing, before the label itself needs any
/// room) below which a sidebar item must render icon-only. Guards the brief
/// window where [AnimatedContainer] is still animating between
/// [_kCollapsedSidebarWidth] and [_kExpandedSidebarWidth] right after
/// [_isSidebarCollapsed] flips to `false`.
const double _kMinExpandedSidebarItemContentWidth =
    24 /* icon */ + AppSpacing.spacing12;

/// The single adaptive navigation shell every authenticated area of
/// VestiPro composes its content around: bottom navigation (+ an optional
/// "mais" sheet for overflow items) on mobile, a compact [NavigationRail]
/// on tablet, and a permanent, collapsible sidebar on desktop/large
/// desktop.
///
/// The same [destinations]/[selectedIndex]/[onDestinationSelected] contract
/// drives all three presentations — there is only ever one active-route
/// state, never a mobile-only and a desktop-only copy of the navigation
/// logic. [AppAdaptiveShell] never decides *which* destinations a user is
/// allowed to see (RBAC filtering happens before [destinations] reaches
/// this widget — see TASK-029) and it never imports `go_router` or knows
/// about a specific route: [body] is whatever the caller's router already
/// resolved for the active route, and [onDestinationSelected] is the
/// caller's own navigation callback (typically `context.go(...)` from a
/// `StatefulShellRoute` branch). This keeps the shell fully reusable
/// regardless of how routing is wired above it.
///
/// ```dart
/// AppAdaptiveShell(
///   destinations: const [
///     AppNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Início'),
///     AppNavDestination(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Clientes'),
///   ],
///   selectedIndex: state.tabIndex,
///   onDestinationSelected: (index) => bloc.add(SelectTab(index)),
///   body: navigationShell,
/// )
/// ```
class AppAdaptiveShell extends StatefulWidget {
  const AppAdaptiveShell({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.secondaryDestinations = const <AppNavDestination>[],
    this.onSecondaryDestinationSelected,
    this.header,
    this.footer,
    this.maxMobileDestinations = 4,
    this.moreLabel = 'Mais',
    this.navigationSemanticLabel = 'Navegação principal',
    this.collapseSemanticLabel = 'Recolher menu',
    this.expandSemanticLabel = 'Expandir menu',
    this.initiallyCollapsed = false,
  }) : assert(
         destinations.length > 0,
         'AppAdaptiveShell requires at least one destination.',
       ),
       assert(
         selectedIndex >= 0 && selectedIndex < destinations.length,
         'selectedIndex must point at an existing destination.',
       ),
       assert(
         maxMobileDestinations > 0,
         'maxMobileDestinations must be at least 1.',
       );

  /// The primary sections of the app. Rendered in full on tablet/desktop/
  /// large desktop; capped to [maxMobileDestinations] on mobile, with the
  /// rest reachable from the [moreLabel] sheet so the bottom bar never
  /// turns into a second, cluttered menu.
  final List<AppNavDestination> destinations;

  /// The index into [destinations] that is currently active. Fully
  /// controlled by the caller — [AppAdaptiveShell] never tracks its own
  /// copy of it, which is exactly what keeps mobile/tablet/desktop in sync
  /// without duplicating navigation state.
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Whatever the caller's router already resolved for [selectedIndex]'s
  /// route.
  final Widget body;

  /// Extra destinations that never compete for bottom-navigation/rail
  /// space (e.g. "Configurações", "Ajuda"): reachable directly from the
  /// sidebar on desktop/large desktop, and from the [moreLabel] sheet on
  /// mobile/tablet.
  final List<AppNavDestination> secondaryDestinations;

  /// Called with the index into [secondaryDestinations] the user picked.
  /// Required whenever [secondaryDestinations] is non-empty.
  final ValueChanged<int>? onSecondaryDestinationSelected;

  /// Rendered above the destination list on tablet/desktop/large desktop
  /// (e.g. an organization/branch switcher). Never shown on mobile, where
  /// vertical space belongs to [body].
  final Widget? header;

  /// Rendered below the destination list on desktop/large desktop only.
  final Widget? footer;

  /// Caps how many [destinations] the mobile bottom navigation shows
  /// before the rest collapse into the [moreLabel] sheet.
  final int maxMobileDestinations;

  final String moreLabel;
  final String navigationSemanticLabel;
  final String collapseSemanticLabel;
  final String expandSemanticLabel;

  /// Only read the very first time this shell instance builds; afterwards
  /// the collapse/expand state lives in [State] and survives every
  /// navigation for as long as the caller's router keeps this shell
  /// instance alive (e.g. a `StatefulShellRoute`).
  final bool initiallyCollapsed;

  @override
  State<AppAdaptiveShell> createState() => _AppAdaptiveShellState();
}

class _AppAdaptiveShellState extends State<AppAdaptiveShell> {
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _isSidebarCollapsed = widget.initiallyCollapsed;
  }

  int get _mobileVisibleCount =>
      widget.destinations.length < widget.maxMobileDestinations
      ? widget.destinations.length
      : widget.maxMobileDestinations;

  bool get _hasMobileOverflow =>
      widget.destinations.length > _mobileVisibleCount ||
      widget.secondaryDestinations.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveBuilder(
      builder: (context, breakpoint) {
        switch (breakpoint) {
          case AppBreakpoint.mobile:
            return _buildMobile(context);
          case AppBreakpoint.tablet:
            return _buildRail(context);
          case AppBreakpoint.desktop:
          case AppBreakpoint.largeDesktop:
            return _buildSidebar(context);
        }
      },
    );
  }

  Widget _buildMobile(BuildContext context) {
    final visible = widget.destinations
        .take(_mobileVisibleCount)
        .toList(growable: false);
    final moreIndex = visible.length;
    final selectedIndex = widget.selectedIndex < moreIndex
        ? widget.selectedIndex
        : moreIndex;

    return Scaffold(
      body: widget.body,
      bottomNavigationBar: Semantics(
        container: true,
        label: widget.navigationSemanticLabel,
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            if (_hasMobileOverflow && index == moreIndex) {
              unawaited(_showMoreSheet(context, primaryStartIndex: moreIndex));
              return;
            }
            widget.onDestinationSelected(index);
          },
          destinations: <Widget>[
            for (final destination in visible)
              _buildNavigationBarDestination(destination),
            if (_hasMobileOverflow)
              NavigationDestination(
                icon: const Icon(Icons.more_horiz),
                label: widget.moreLabel,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            container: true,
            label: widget.navigationSemanticLabel,
            child: NavigationRail(
              selectedIndex: widget.selectedIndex,
              onDestinationSelected: widget.onDestinationSelected,
              labelType: NavigationRailLabelType.selected,
              leading: widget.header,
              trailing: widget.secondaryDestinations.isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.spacing8),
                      child: AppIconButton(
                        icon: Icons.more_horiz,
                        semanticLabel: widget.moreLabel,
                        onPressed: () => _showMoreSheet(
                          context,
                          primaryStartIndex: widget.destinations.length,
                        ),
                      ),
                    ),
              destinations: <NavigationRailDestination>[
                for (final destination in widget.destinations)
                  _buildNavigationRailDestination(destination),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: widget.body),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final colors = context.colors;
    final width = _isSidebarCollapsed
        ? _kCollapsedSidebarWidth
        : _kExpandedSidebarWidth;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            container: true,
            label: widget.navigationSemanticLabel,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width: width,
              color: colors.surfaceContainer,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (widget.header != null)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.spacing16),
                        child: widget.header,
                      ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacing8,
                        ),
                        children: <Widget>[
                          for (
                            var index = 0;
                            index < widget.destinations.length;
                            index++
                          )
                            _buildSidebarItem(
                              context,
                              widget.destinations[index],
                              isSelected: index == widget.selectedIndex,
                              onTap: () => widget.onDestinationSelected(index),
                            ),
                          if (widget
                              .secondaryDestinations
                              .isNotEmpty) ...<Widget>[
                            const Divider(height: AppSpacing.spacing16),
                            for (
                              var index = 0;
                              index < widget.secondaryDestinations.length;
                              index++
                            )
                              _buildSidebarItem(
                                context,
                                widget.secondaryDestinations[index],
                                isSelected: false,
                                onTap: () => widget
                                    .onSecondaryDestinationSelected
                                    ?.call(index),
                              ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.footer != null) widget.footer!,
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.spacing8),
                      child: Align(
                        alignment: _isSidebarCollapsed
                            ? Alignment.center
                            : Alignment.centerRight,
                        child: AppIconButton(
                          icon: _isSidebarCollapsed
                              ? Icons.chevron_right
                              : Icons.chevron_left,
                          semanticLabel: _isSidebarCollapsed
                              ? widget.expandSemanticLabel
                              : widget.collapseSemanticLabel,
                          onPressed: () => setState(
                            () => _isSidebarCollapsed = !_isSidebarCollapsed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: widget.body),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context,
    AppNavDestination destination, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final foreground = isSelected ? colors.primary : colors.onSurface;
    final icon =
        (isSelected ? destination.selectedIcon : null) ?? destination.icon;

    return Semantics(
      key: ValueKey('app_adaptive_shell_nav_item_${destination.label}'),
      label: destination.semanticLabel ?? destination.label,
      selected: isSelected,
      button: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing8,
          vertical: AppSpacing.spacing4,
        ),
        child: Material(
          color: isSelected ? colors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.radius8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.radius8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing12,
                vertical: AppSpacing.spacing12,
              ),
              // Resolved against the *actual* available width (via
              // LayoutBuilder), not just [_isSidebarCollapsed]: while
              // [AnimatedContainer] is mid-animation between the collapsed
              // and expanded sidebar widths, the boolean flips a frame
              // before the width tween catches up, which would otherwise
              // ask a still-narrow Row to lay out the full icon+label
              // content and overflow.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final canShowLabel =
                      !_isSidebarCollapsed &&
                      constraints.maxWidth >=
                          _kMinExpandedSidebarItemContentWidth;
                  if (!canShowLabel) {
                    return Icon(icon, color: foreground);
                  }
                  return Row(
                    children: <Widget>[
                      Icon(icon, color: foreground),
                      const SizedBox(width: AppSpacing.spacing12),
                      Expanded(
                        child: Text(
                          destination.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: foreground,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationBarDestination(AppNavDestination destination) {
    return NavigationDestination(
      icon: Icon(destination.icon),
      selectedIcon: destination.selectedIcon != null
          ? Icon(destination.selectedIcon)
          : null,
      label: destination.label,
      tooltip: destination.semanticLabel ?? destination.label,
    );
  }

  NavigationRailDestination _buildNavigationRailDestination(
    AppNavDestination destination,
  ) {
    return NavigationRailDestination(
      icon: Icon(destination.icon),
      selectedIcon: destination.selectedIcon != null
          ? Icon(destination.selectedIcon)
          : null,
      label: Text(destination.label),
    );
  }

  Future<void> _showMoreSheet(
    BuildContext context, {
    required int primaryStartIndex,
  }) {
    final overflowDestinations = widget.destinations
        .skip(primaryStartIndex)
        .toList(growable: false);

    return AppBottomSheet.show<void>(
      context: context,
      title: widget.moreLabel,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var i = 0; i < overflowDestinations.length; i++)
            _buildMoreSheetTile(
              sheetContext,
              overflowDestinations[i],
              isSelected: widget.selectedIndex == primaryStartIndex + i,
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onDestinationSelected(primaryStartIndex + i);
              },
            ),
          for (var i = 0; i < widget.secondaryDestinations.length; i++)
            _buildMoreSheetTile(
              sheetContext,
              widget.secondaryDestinations[i],
              isSelected: false,
              onTap: () {
                Navigator.of(sheetContext).pop();
                widget.onSecondaryDestinationSelected?.call(i);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMoreSheetTile(
    BuildContext context,
    AppNavDestination destination, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Semantics(
      selected: isSelected,
      button: true,
      child: ListTile(
        leading: Icon(
          (isSelected ? destination.selectedIcon : null) ?? destination.icon,
          color: isSelected ? colors.primary : colors.onSurface,
        ),
        title: Text(
          destination.label,
          style: AppTypography.bodyLarge.copyWith(
            color: isSelected ? colors.primary : colors.onSurface,
          ),
        ),
        trailing: isSelected ? Icon(Icons.check, color: colors.primary) : null,
        onTap: onTap,
      ),
    );
  }
}
