import 'package:flutter/widgets.dart';

/// A single navigable section of the app (e.g. "Início", "Clientes",
/// "Pedidos") as consumed by [AppAdaptiveShell] — never a route path or a
/// permission check. Which destinations reach the shell (RBAC filtering) is
/// entirely up to the caller/domain layer; [AppNavDestination] only carries
/// what is needed to render one entry consistently across bottom
/// navigation, a rail and a sidebar.
@immutable
class AppNavDestination {
  const AppNavDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.semanticLabel,
  });

  /// Rendered while this destination is not the active one.
  final IconData icon;

  /// Rendered instead of [icon] while this destination is the active one.
  /// Falls back to [icon] when not provided.
  final IconData? selectedIcon;

  /// The visible label, always caller-provided (i18n-ready).
  final String label;

  /// Overrides [label] as the accessibility announcement, for cases where
  /// the label alone is ambiguous out of context.
  final String? semanticLabel;
}
